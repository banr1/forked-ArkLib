#!/usr/bin/env bash
# unique_inlinks.sh  (DAG前提・GraphViz .dot -> node,count CSV)
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 input.dot" >&2
  exit 1
fi

infile="$1"

# gawk 推奨（macOS: brew install gawk）
gawk '
BEGIN{
  FS="\n"; OFS=","; sep=SUBSEP; listsep="\034";
}

function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/,"",s); return s }
function cleanid(s,   t){
  split(s, arr, "["); t=arr[1];
  split(t, arr2, ";"); t=arr2[1];
  t=trim(t);
  if (t ~ /^".*"$/){ sub(/^"/,"",t); sub(/"$/,"",t) }
  return trim(t);
}

{
  line=$0
  sub(/\/\/.*/,"",line)  # // コメント簡易除去

  if (line ~ /->/){
    if (match(line, /([^;]+)->([^;]+)/, m)){
      u=cleanid(m[1]); v=cleanid(m[2]);
      if (u!="" && v!=""){
        nodes[u]=1; nodes[v]=1
        children[u, ++chcnt[u]] = v
        indeg[v]++
      }
    }
  } else {
    # 例:  X [shape=circle];
    if (match(line, /^[ \t]*([A-Za-z0-9_:.]+|"[^"]+")[ \t]*\[/, m)){
      n=cleanid(m[1])
      if (n!="") nodes[n]=1
    }
  }
}

# asorti 用の比較関数: 被リンク総量（cnt）昇順、同値はノード名昇順
function by_count_then_name(i1, v1, i2, v2, c1, c2){
  c1 = (i1 in cnt)?cnt[i1]:0
  c2 = (i2 in cnt)?cnt[i2]:0
  if (c1 < c2) return -1
  if (c1 > c2) return 1
  return (i1 < i2) ? -1 : (i1 > i2) ? 1 : 0
}

END{
  # Kahn法トポロジカルソート
  n_total=0
  for (n in nodes){
    n_total++
    if (!(n in indeg)) indeg[n]=0
  }

  qh=1; qt=0
  for (n in nodes) if (indeg[n]==0) queue[++qt]=n

  orderc=0
  while (qh<=qt){
    cur=queue[qh++]
    order[++orderc]=cur

    for (i=1; i<=chcnt[cur]; i++){
      c = children[cur,i]

      # cur 自身を c の祖先に
      if (!( (c sep cur) in has )){
        has[c,cur]=1
        if (anc_list[c]=="") anc_list[c]=cur; else anc_list[c]=anc_list[c] listsep cur
        cnt[c]++
      }

      # cur の祖先を c に伝播
      if (anc_list[cur]!=""){
        split(anc_list[cur], tmp, listsep)
        for (k in tmp){
          a = tmp[k]
          if (!( (c sep a) in has )){
            has[c,a]=1
            if (anc_list[c]=="") anc_list[c]=a; else anc_list[c]=anc_list[c] listsep a
            cnt[c]++
          }
        }
      }

      indeg[c]--
      if (indeg[c]==0) queue[++qt]=c
    }
  }

  if (orderc != n_total){
    print "Error: input graph seems to contain a cycle." > "/dev/stderr"
    exit 2
  }

  # --- ここから出力 ---
  # ① ヘッダー
  print "node","count"

  # ② 被リンク総量（cnt）で昇順ソート、同数は名前昇順
  nkeys = asorti(nodes, sorted, "by_count_then_name")
  for (i=1;i<=nkeys;i++){
    n = sorted[i]
    c = (n in cnt) ? cnt[n] : 0
    print n, c
  }
}
' "$infile"
