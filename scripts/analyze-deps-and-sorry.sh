#!/usr/bin/env bash
set -euo pipefail

# Analyze Lean module indegrees from a DOT import graph, compute each node's
# total number of unique ancestors (transitive in-links), and count non-comment
# `sorry` occurrences per module, then merge and sort the results.
#
# Outputs:
# - scripts/module_indegree_sorry.csv (module,indegree,ancestor_count,sorry_count)
#   sorted by (ancestor_count ASC, sorry_count DESC)
#
# Intermediate files (e.g., import_graph.dot, module_indegree.csv, sorry_counts.csv)
# are removed automatically on exit; only the final CSV remains.

# Usage:
#   scripts/analyze_deps_and_sorry.sh [TARGET]
# Default TARGET is "ArkLib".

TARGET=${1:-ArkLib}

# Resolve directories so output always lands under scripts/ regardless of CWD
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

DOT_FILE="import_graph.dot"
INDEGREE_CSV="module_indegree.csv"
SORRY_CSV="sorry_counts.csv"
# Ancestor counts derived from DOT via scripts/unique-inlinks.sh
ANCESTOR_CSV="module_ancestors.csv"
# Final output path under scripts/
MERGED_CSV="${SCRIPT_DIR}/module_indegree_sorry.csv"

# Track whether we created the DOT file to avoid deleting a pre-existing one
CREATED_DOT=0

# Ensure cleanup of intermediates; keep only the final merged CSV
cleanup() {
  # Remove temporary files if present
  rm -f "${INDEGREE_CSV}.tmp" "${SORRY_CSV}.tmp" "${ANCESTOR_CSV}.tmp" 2>/dev/null || true
  # Remove intermediate CSVs produced by this run
  rm -f "${INDEGREE_CSV}" "${SORRY_CSV}" "${ANCESTOR_CSV}" 2>/dev/null || true
  # Remove DOT only if we generated it in this run
  if [[ "${CREATED_DOT}" -eq 1 ]]; then
    rm -f "${DOT_FILE}" 2>/dev/null || true
  fi
  # If an old root-level merged CSV exists from prior runs, remove it
  if [[ -f "./module_indegree_sorry.csv" && "${MERGED_CSV}" != "$(pwd)/module_indegree_sorry.csv" ]]; then
    rm -f "./module_indegree_sorry.csv" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "[1/4] Generating DOT graph: lake exe graph --to ${TARGET} > ${DOT_FILE}"
if command -v lake >/dev/null 2>&1; then
  lake exe graph --to "${TARGET}" > "${DOT_FILE}"
  CREATED_DOT=1
else
  if [[ -f "${DOT_FILE}" ]]; then
    echo "Warn: 'lake' not found; using existing ${DOT_FILE}." >&2
  else
    echo "Error: 'lake' command not found and ${DOT_FILE} is missing. Install Lake or run inside the project." >&2
    exit 1
  fi
fi

echo "[2/4] Parsing DOT and computing indegrees -> ${INDEGREE_CSV}"

# AWK to parse Graphviz DOT for a digraph where edges look like:
#   "A.B" -> "C.D";
# We collect all node names seen and count indegree as RHS occurrences.
awk -v OFS="," '
  BEGIN {
    print "module","indegree"
  }
  {
    line = $0
    # Edge line: "LHS" -> "RHS"
    if (match(line, /"[^\"]+"[[:space:]]*->[[:space:]]*"[^\"]+"/)) {
      # Extract both quoted names
      # First quoted
      if (match(line, /"[^\"]+"/)) {
        lhs = substr(line, RSTART+1, RLENGTH-2)
        nodes[lhs] = 1
        # Trim up to after first quote to find second quoted
        rest = substr(line, RSTART+RLENGTH)
        if (match(rest, /"[^\"]+"/)) {
          rhs = substr(rest, RSTART+1, RLENGTH-2)
          nodes[rhs] = 1
          indeg[rhs]++
        }
      }
      next
    }

    # Node declaration lines often start with a quoted name
    if (match(line, /^[[:space:]]*"[^\"]+"/)) {
      s = substr(line, RSTART, RLENGTH)    # includes leading spaces plus the quoted name
      qpos = index(s, "\"")             # position of the first quote in s
      if (qpos > 0) {
        # extract between the first and last quote in this token
        s2 = substr(s, qpos+1)
        # s2 now starts after first quote; trim trailing quote if present
        lq = index(s2, "\"")
        if (lq > 0) {
          name = substr(s2, 1, lq-1)
          nodes[name] = 1
        }
      }
    }
  }
  END {
    for (n in nodes) {
      i = (n in indeg) ? indeg[n] : 0
      print n, i
    }
  }
' "${DOT_FILE}" | sort -t, -k1,1 > "${INDEGREE_CSV}.tmp"

# Keep header at top while sorting by module for deterministic merge order
{
  head -n 1 "${INDEGREE_CSV}.tmp" && tail -n +2 "${INDEGREE_CSV}.tmp"
} > "${INDEGREE_CSV}"
rm -f "${INDEGREE_CSV}.tmp"

echo "[3/4] Computing unique ancestor counts from DOT -> ${ANCESTOR_CSV}"
# Use the existing helper to compute unique in-links (all ancestors) per node
if [[ -x "${SCRIPT_DIR}/unique-inlinks.sh" ]]; then
  "${SCRIPT_DIR}/unique-inlinks.sh" "${DOT_FILE}" > "${ANCESTOR_CSV}.tmp"
else
  # Fall back to invoking via shell if not executable
  bash "${SCRIPT_DIR}/unique-inlinks.sh" "${DOT_FILE}" > "${ANCESTOR_CSV}.tmp"
fi
# Transform header to align with other CSVs and sort deterministically by module
{
  echo "module,ancestor_count"
  tail -n +2 "${ANCESTOR_CSV}.tmp" | awk -F, -v OFS="," '{ print $1, $2 }' | sort -t, -k1,1
} > "${ANCESTOR_CSV}"
rm -f "${ANCESTOR_CSV}.tmp"

echo "[4/4] Counting non-comment 'sorry' per module -> ${SORRY_CSV}"

# AWK filter to strip Lean comments (line comments with -- and nested block comments /- ... -/)
# and then count tokenized occurrences of the word "sorry".
count_sorry_awk='
  BEGIN { block = 0; total = 0 }
  {
    line = $0
    out = ""
    i = 1
    L = length(line)
    while (i <= L) {
      c = substr(line, i, 1)
      n = (i < L) ? substr(line, i+1, 1) : ""
      if (block > 0) {
        if (c == "-" && n == "/") { block--; i += 2; continue }
        else if (c == "/" && n == "-") { block++; i += 2; continue } # handle nested openings inside blocks
        else { i++; continue }
      } else {
        if (c == "/" && n == "-") { block++; i += 2; continue }
        if (c == "-" && n == "-") { break } # line comment: skip rest of line
        out = out c
        i++
      }
    }
    # Tokenize by non-word chars and count exact token "sorry"
    gsub(/[^A-Za-z0-9_]+/, " ", out)
    n = split(out, a, /[[:space:]]+/)
    for (j = 1; j <= n; j++) {
      if (a[j] == "sorry") total++
    }
  }
  END { print total }
'

{
  echo "module,sorry_count"
  # Find ArkLib modules: include top-level ArkLib.lean and files under ArkLib/
  find . -type f -name "*.lean" \( -path "./ArkLib/*" -o -name "ArkLib.lean" \) -print0 |
  sort -z |
  while IFS= read -r -d "" f; do
    # Map file path to module name: strip leading ./, replace / with ., drop .lean
    rel="${f#./}"
    mod="${rel%.lean}"
    mod="${mod//\//.}"
    # Count sorry after stripping comments
    cnt=$(awk "${count_sorry_awk}" "$f")
    echo "$mod,$cnt"
  done
} > "${SORRY_CSV}.tmp"

# Sort for deterministic ordering by module name
{
  head -n 1 "${SORRY_CSV}.tmp" && tail -n +2 "${SORRY_CSV}.tmp" | sort -t, -k1,1
} > "${SORRY_CSV}"
rm -f "${SORRY_CSV}.tmp"

echo "Merging and sorting -> ${MERGED_CSV}"

# Full outer join on module, defaulting missing counts to 0. Then sort (ancestor_count ASC, sorry DESC).
awk -F, -v OFS="," -v INFILE="${INDEGREE_CSV}" -v ANCFILE="${ANCESTOR_CSV}" -v SCFILE="${SORRY_CSV}" '
  FILENAME==INFILE {
    if (FNR>1) indeg[$1]=$2
    next
  }
  FILENAME==ANCFILE {
    if (FNR>1) anc[$1]=$2
    next
  }
  FILENAME==SCFILE {
    if (FNR>1) { sc[$1]=$2; seen[$1]=1 }
    next
  }
  END {
    print "module","indegree","ancestor_count","sorry_count"
    for (m in indeg) { seen[m]=1 }
    for (m in anc) { seen[m]=1 }
    for (m in seen) {
      i = (m in indeg) ? indeg[m] : 0
      a = (m in anc) ? anc[m] : 0
      s = (m in sc) ? sc[m] : 0
      print m, i, a, s
    }
  }
' "${INDEGREE_CSV}" "${ANCESTOR_CSV}" "${SORRY_CSV}" | (
  read -r header; echo "$header"; sort -t, -k3,3n -k4,4nr
) > "${MERGED_CSV}"

echo "Done. Output written to: ${MERGED_CSV}"
echo "(Intermediate files have been cleaned up.)"
