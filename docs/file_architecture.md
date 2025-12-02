# ArkLib File Architecture

This document explains how the files and folders in the ArkLib repository are organized and what each part is for. It is written for readers who are comfortable with Lean and proof engineering, but it avoids protocol-specific technicalities where possible.

## Top-level layout

At the root of the repository you will find:

- `ArkLib/` – the Lean 4 library itself, split into topic-based subdirectories.
- `ArkLib.lean` – umbrella file that collects and re-exports the main `ArkLib` modules.
- `blueprint/` – human-oriented design documents (the “blueprint”) for the library.
- `scripts/` – helper scripts for building, linting, and analyzing the project.
- `dependency_graphs/` – precomputed dependency graphs of the Lean modules.
- `home_page/` – a small static web page for the project.
- `node_modules/`, `package.json`, `pnpm-lock.yaml` – JavaScript tooling and dependencies (not part of the Lean library itself).
- `BACKGROUND*.md`, `ROADMAP*.md` – background and roadmap documents in English and Japanese.
- `README*.md`, `CONTRIBUTING.md` – high-level project overview and contribution guide (English and Japanese variants).
- `AUTHORS`, `LICENSE` – authorship and licensing information.
- `lakefile.toml`, `lake-manifest.json`, `lean-toolchain` – Lean / Lake build configuration.
- `AGENTS*.md` – instructions for automated agents that work on this repository.
- `import_graph_to_merkle_tree.dot` – a Graphviz representation of the import graph, used for meta-level analysis.

In day-to-day development you will mostly work inside `ArkLib/` and occasionally consult `blueprint/`, the `BACKGROUND*`/`ROADMAP*` files, and the scripts.

## Core Lean library: `ArkLib/`

The `ArkLib/` directory contains all Lean source files that make up the ArkLib library. It is organized by topic:

- `OracleReduction/` – infrastructure for interactive oracle reductions and related gadgets.
- `ProofSystem/` – formalizations of concrete proof systems and protocols.
- `CommitmentScheme/` – definitions and constructions of commitment schemes.
- `Data/` – supporting algebraic and combinatorial data structures and lemmas.
- `AGM/` – definitions and results related to the Algebraic Group Model.
- `ToMathlib/` – compatibility shims and extensions on top of mathlib.
- `ToVCVio/` – compatibility layer with the VCVio library.

Below is a brief overview of each of these subtrees.

### `ArkLib/OracleReduction/`

This directory contains the general theory of oracle reductions, used to describe how protocols transform one oracle into another.

- Top-level files such as `Basic.lean`, `OracleInterface.lean`, `Execution.lean`, `Cast.lean`, `Prelude.lean`, `Salt.lean`, and `VectorIOR.lean` develop:
  - the core definitions of oracle interfaces and queries,
  - the basic execution semantics of oracle computations,
  - utilities for casting between related oracle types,
  - common combinators and supporting lemmas.
- `BCS/` – components related to the “Binary Constraint System” (BCS) style oracle reductions.
- `Composition/` – constructions for composing multiple oracle reductions.
- `FiatShamir/` – the Fiat–Shamir transformation and its interaction with oracle reductions.
- `LiftContext/` – utilities for lifting an oracle reduction into a larger context.
- `ProtocolSpec/` – specifications of protocols in terms of the oracle-reduction framework.
- `Security/` – security notions and reductions phrased in the oracle-reduction language.

When you want to express a new reduction or security proof that manipulates oracles, this is the place to look.

### `ArkLib/ProofSystem/`

This directory formalizes specific proof systems and their composition.

- `DSL.lean` – a domain-specific language for describing proof-system components.
- `Stir.lean`, `Whir.lean` – high-level files for the STIR and WHIR systems.
- Subdirectories for individual proof systems and building blocks:
  - `BatchedFri/` – batched FRI (Fast Reed–Solomon Interactive Oracle Proofs of Proximity).
  - `Binius/` – components related to Binius-style polynomial commitments or protocols.
  - `Component/` – reusable proof-system components and combinators.
  - `ConstraintSystem/` – abstractions for constraint systems underlying many protocols.
  - `Fri/` – the FRI protocol itself.
  - `Plonk/` – PLONK-style polynomial-commitment-based proof systems.
  - `Spartan/` – Spartan-style proof systems.
  - `Stir/`, `Whir/`, `Sumcheck/` – implementations of the STIR, WHIR, and Sumcheck protocols.

If you are looking for the formalization of a particular protocol (Sumcheck, FRI, Plonk, …), this is the directory to explore.

### `ArkLib/CommitmentScheme/`

This directory contains definitions and implementations of commitment schemes, which are used as building blocks in various proof systems.

- `Basic.lean` – common interfaces and basic lemmas about commitment schemes.
- `Trivial.lean` – a simple “toy” commitment scheme, useful as a baseline or for testing.
- `MerkleTree.lean`, `InductiveMerkleTree.lean` – Merkle-tree-based commitment schemes.
- `KZG.lean` – KZG (Kate–Zaverucha–Goldberg) polynomial commitment scheme.
- `SimpleRO.lean` – commitment schemes built from a simple random oracle.
- `Fold.lean`, `Tensor.lean` – folding and tensor-based constructions for commitments.

New commitment schemes or variations typically live here.

### `ArkLib/Data/`

This subtree provides the algebraic and combinatorial groundwork that many protocols rely on. It is roughly organized by mathematical topic:

- `Array/`, `List/`, `Vector/` – additional results and utilities about basic containers.
- `Nat/`, `CNat/` – natural numbers and countable variants.
- `Matrix/`, `Polynomial/`, `UniPoly/`, `MvPolynomial/`, `MlPoly/` – matrices and various kinds of (multi)polynomials.
- `FieldTheory/`, `RingTheory/`, `GroupTheory/` – algebraic infrastructure tailored to ArkLib’s needs.
- `CodingTheory/`, `CodingTheory.lean` – coding-theoretic constructions used in proof systems.
- `Fin/` – results related to finite index types.
- `Hash/` – abstractions and lemmas about hash functions.
- `Probability/` – probabilistic reasoning tools.
- `Misc/` – small supporting lemmas and utilities that do not fit elsewhere.

Most reusable mathematics that is specific to ArkLib, but not yet in mathlib, is developed here.

### `ArkLib/AGM/`

The `AGM/` directory contains material related to the Algebraic Group Model (AGM).

- `Basic.lean` – core definitions and basic results about the AGM setting.

This is where AGM-specific reasoning is centralized.

### `ArkLib/ToMathlib/`

ArkLib builds heavily on mathlib. When ArkLib needs lemmas or definitions that are not yet available upstream, they live here, organized roughly in parallel with mathlib’s structure:

- `BigOperators/` – additions related to big operators (`∑`, `∏`, etc.).
- `Data/` – data-structure-related extensions.
- `Finset/` – extra lemmas about finite sets.
- `Finsupp/` – extensions for finitely supported functions.
- `MvPolynomial/` – additional results about multivariate polynomials.
- `NumberTheory/` – number-theoretic tools needed by the library.
- `UInt/` – additions around unsigned integer types.
- `README.md` – notes on how this directory relates to mathlib and what might be candidates for upstreaming.

Think of this directory as ArkLib’s staging area for potential mathlib contributions.

### `ArkLib/ToVCVio/`

This directory provides a bridge to the VCVio library.

- `DistEq.lean`, `Lemmas.lean`, `Oracle.lean`, `SimOracle.lean` – compatibility definitions and lemmas that connect ArkLib’s oracle and probability infrastructure with VCVio’s.

Whenever you need to relate ArkLib code to VCVio constructions, this is the place to look.

## Blueprints and narrative documentation: `blueprint/`, `BACKGROUND*`, `ROADMAP*`

While `ArkLib/` is the machine-checked code, the surrounding files explain the ideas behind it.

### `blueprint/`

The `blueprint/` directory hosts human-oriented design documents that mirror the structure of the Lean code:

- `src/` – main source of the blueprint, organized by topic:
  - `vcv/` – blueprint material around VCVio and related constructions.
  - `commitments/` – design notes for commitment schemes.
  - `oracle_reductions/` – explanations of oracle-reduction constructions.
  - `coding_theory/` – coding-theoretic background and its role in protocols.
  - `polynomials/` – polynomial-related background and conventions.
  - `proof_systems/` – high-level presentation of the proof systems implemented in `ArkLib/ProofSystem/`.
  - `macros/` – blueprint macros and tooling.
  - `figures/` – images and diagrams referenced by the blueprint.
- `lean_decls` – a text file that links blueprint items to Lean declarations (used by tooling to connect the blueprint to the formal code).

These documents are the best starting point when you want to understand the conceptual structure before diving into Lean code.

### Background and roadmap files

At the repository root:

- `BACKGROUND.md`, `BACKGROUND.ja.md` – explain the broader motivation and context of ArkLib (English and Japanese).
- `ROADMAP.md`, `ROADMAP.ja.md` – describe planned directions, milestones, and high-level goals (English and Japanese).

These are purely narrative and do not contain Lean code, but they are useful for understanding where the project is headed.

## Tooling and scripts: `scripts/`, `dependency_graphs/`

### `scripts/`

The `scripts/` directory contains shell and Python scripts that support development:

- `build-project.sh` – convenience wrapper around `lake build` for compiling the project.
- `check-imports.sh` – checks that `ArkLib.lean` correctly mirrors the actual modules present under `ArkLib/`.
- `update-lib.sh` – updates `ArkLib.lean` based on the current module layout.
- `lint-style.sh`, `lint-style.lean`, `lint-style.py` – mathlib-style linting: naming conventions, line length, docstrings, etc.
- `lintWhitespace.sh` – whitespace-only linting (e.g., trailing spaces).
- `analyze-deps-and-sorry.sh`, `dependency_analysis/`, `module_indegree_sorry.csv` – scripts and data for analyzing dependency structure and remaining `sorry`s.
- `pr-summary.py`, `review.py` – helpers for summarizing pull requests and review tasks.
- `style-exceptions.txt` – configuration for style checks (paths that are allowed to violate some rules).
- `README.md` – documentation for the scripts themselves.

You typically use these scripts via the commands described in `AGENTS.md` and `CONTRIBUTING.md` (for example, running `./scripts/check-imports.sh` after adding a new module).

### `dependency_graphs/`

This directory contains precomputed artifacts that describe the module dependency structure:

- `arklib_dependencies.dot` – a Graphviz file that can be rendered into a diagram of module dependencies.
- `arklib_dependencies.json` – a machine-readable version of the dependency graph.
- `arklib_dependencies.txt` – a human-readable summary of dependencies.

These files are useful when you want a high-level view of how modules depend on each other.

## Website and auxiliary tooling: `home_page/`, JavaScript files

### `home_page/`

- `index.html` – a small static page that can be used as a project home page or demo landing page.

This directory is decoupled from the Lean library and can be served as-is by any static file server.

### JavaScript tooling

At the root of the repository:

- `package.json`, `pnpm-lock.yaml` – configuration for Node/PNPM-based tooling.
- `node_modules/` – installed JavaScript dependencies (for example, the `@openai/codex` package).

These files are only relevant if you are using the JavaScript tooling; they are not required to build the Lean library.

## How to navigate the repository

- To explore or extend the formalized protocols, start in `ArkLib/ProofSystem/` and follow imports into `CommitmentScheme/`, `OracleReduction/`, and `Data/` as needed.
- To understand the math background or see if a lemma already exists, first look in `ArkLib/Data/` and `ArkLib/ToMathlib/`.
- To add a new protocol or construction, sketch it in the appropriate `blueprint/src/` subdirectory, then implement it under the matching `ArkLib/` subtree.
- To keep imports and style consistent, use the scripts in `scripts/` (`check-imports.sh`, `lint-style.sh`) and update `ArkLib.lean` when you add new modules.

With this structure in mind, you can treat `ArkLib/` as the formal core of the project, `blueprint/` and the background/roadmap files as the narrative layer, and `scripts/` plus the dependency graphs as the tooling that keeps everything coherent.
