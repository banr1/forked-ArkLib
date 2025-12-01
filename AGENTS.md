# Repository Guidelines

## Project Structure & Module Organization
ArkLib is a Lean 4 library (toolchain `leanprover/lean4:v4.22.0`). The core sources live in `ArkLib/`, organized by topic: `OracleReduction/` for interactive reductions, `ProofSystem/` for protocol formalizations, `CommitmentScheme/` for commitments, `Data/` for supporting algebra/data structures, and `ToMathlib/`/`ToVCVio/` for compatibility layers. `ArkLib.lean` collects all imports. Supporting material: `blueprint/` (design docs), `BACKGROUND*.md` and `ROADMAP*.md` (context), `scripts/` (tooling), and `home_page/` (site assets).

## Build, Test, and Development Commands
Run from the repo root with the pinned toolchain installed.
- `lake update` — fetch Lake dependencies listed in `lakefile.toml`.
- `lake build ArkLib` — compile the library; use `lake build` for all default targets.
- `./scripts/check-imports.sh` — verify `ArkLib.lean` matches the modules present; run `./scripts/update-lib.sh` if it is outdated.
- `./scripts/lint-style.sh` — mathlib-style checks (docstrings, line length, casing, executable bits); honors `scripts/style-exceptions.txt`.
- Use `lake env lean` or your editor’s Lean 4 support to work interactively.

## Coding Style & Naming Conventions
Follow the mathlib style guide (see `CONTRIBUTING.md`): two-space indentation, no tabs, lines ≤100 chars unless unavoidable (e.g., URLs), and explicit binders (`autoImplicit := false`). Add a module docstring at the top of new files, short docstrings on nontrivial definitions/theorems, and prefer readable proof scripts over opaque term proofs. Name modules with CamelCase paths (`ProofSystem.Sumcheck`), definitions/theorems with descriptive snake_case that matches mathlib conventions. Keep imports minimal and sorted; avoid `open`ing large namespaces globally.

## Testing Guidelines
Treat compilation as the primary test: `lake build` should succeed without `sorry`. For new executable definitions, add small `example` blocks or helper lemmas in the same namespace to exercise expected behavior. If you touch import boundaries, run `./scripts/check-imports.sh`; for style-sensitive changes, run `./scripts/lint-style.sh` before pushing. Keep proofs deterministic and avoid fragile tactics that depend on implicit search ordering.

## Commit & Pull Request Guidelines
Commit titles follow the existing pattern: short prefix plus scope, e.g., `feat: computable additive NTT (#94)`. Keep the subject line concise; group related changes per commit. In PRs, include a brief summary, link issues (`Fixes #123`), list the commands you ran (build/lint), and mention any blueprint or documentation updates. Screenshots are unnecessary unless you change rendered assets (e.g., `home_page/`). Ensure new modules are imported in `ArkLib.lean` and documented.
