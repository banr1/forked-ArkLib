# ArkLib ファイル構成

このドキュメントは、ArkLib リポジトリのファイルやディレクトリがどのように整理されていて、それぞれが何のためにあるのかを説明します。Lean や証明工学にある程度慣れた読者を想定していますが、可能な限りプロトコル固有の専門的な話は避けています。

## リポジトリ直下の構成

リポジトリのルートには、主に次のようなものがあります:

- `ArkLib/` – ArkLib 本体の Lean 4 ライブラリ。トピックごとにサブディレクトリに分かれています。
- `ArkLib.lean` – 主要な `ArkLib` モジュールをまとめてインポート・再エクスポートする「入口」ファイル。
- `blueprint/` – ライブラリの設計を人間向けに説明した「ブループリント」文書群。
- `scripts/` – ビルド・lint・依存関係解析などを行う補助スクリプト。
- `dependency_graphs/` – Lean モジュールどうしの依存関係グラフを事前計算したもの。
- `home_page/` – プロジェクト用の簡単な静的 Web ページ。
- `node_modules/`, `package.json`, `pnpm-lock.yaml` – JavaScript 系ツール・依存パッケージ（Lean ライブラリ本体とは独立）。
- `BACKGROUND*.md`, `ROADMAP*.md` – プロジェクトの背景説明・ロードマップ（英語版と日本語版）。
- `README*.md`, `CONTRIBUTING.md` – プロジェクト概要とコントリビュート方法の説明（英語・日本語のバリアント）。
- `AUTHORS`, `LICENSE` – 著者情報とライセンス文書。
- `lakefile.toml`, `lake-manifest.json`, `lean-toolchain` – Lean / Lake のビルド設定。
- `AGENTS*.md` – このリポジトリで動く自動エージェント向けの指示。
- `import_graph_to_merkle_tree.dot` – インポートグラフを表す Graphviz ファイル（メタな解析に利用）。

普段の開発では主に `ArkLib/` 以下で作業し、ときどき `blueprint/` や `BACKGROUND*` / `ROADMAP*`、各種スクリプトを参照する、というイメージです。

## コア Lean ライブラリ: `ArkLib/`

`ArkLib/` ディレクトリには、ArkLib ライブラリを構成する Lean ソースがすべて入っています。トピックごとに次のように分かれています:

- `OracleReduction/` – 対話的オラクル還元とその周辺の道具立て。
- `ProofSystem/` – 具体的な証明系・プロトコルの形式化。
- `CommitmentScheme/` – コミットメントスキームの定義と構成。
- `Data/` – 代数的・組合せ的なデータ構造や補題などの基礎的ツール。
- `AGM/` – Algebraic Group Model（代数群モデル）に関する定義と結果。
- `ToMathlib/` – mathlib との互換レイヤや拡張。
- `ToVCVio/` – VCVio ライブラリとの互換レイヤ。

以下では、それぞれのサブツリーの概要を簡単に説明します。

### `ArkLib/OracleReduction/`

このディレクトリには、オラクル還元の一般論がまとまっています。プロトコルが「あるオラクルを別のオラクルへ」変換する様子を記述するための枠組みです。

- `Basic.lean`, `OracleInterface.lean`, `Execution.lean`, `Cast.lean`, `Prelude.lean`, `Salt.lean`, `VectorIOR.lean` などのトップレベルのファイルでは、次のような内容を扱います:
  - オラクルインターフェースとクエリの基本定義
  - オラクル計算の実行意味論
  - 関連するオラクル型どうしを変換するためのユーティリティ
  - よく使う合成子や補題の集まり
- `BCS/` – Binary Constraint System（BCS）型のオラクル還元に関連するコンポーネント。
- `Composition/` – 複数のオラクル還元を合成するための構成。
- `FiatShamir/` – Fiat–Shamir 変換とオラクル還元との相互作用。
- `LiftContext/` – あるオラクル還元を、より大きなコンテキストへ持ち上げるための道具。
- `ProtocolSpec/` – プロトコルをオラクル還元フレームワーク上で仕様化したもの。
- `Security/` – セキュリティ概念や還元を、オラクル還元の言葉で記述した部分。

新しい還元や、オラクルを操作するセキュリティ証明を書きたいときには、まずここを参照します。

### `ArkLib/ProofSystem/`

このディレクトリでは、具体的な証明系とその組み合わせを形式化しています。

- `DSL.lean` – 証明系コンポーネントを記述するためのドメイン固有言語。
- `Stir.lean`, `Whir.lean` – STIR と WHIR システムの高レベルな入口ファイル。
- 個々の証明系やビルディングブロックごとにサブディレクトリがあります:
  - `BatchedFri/` – batched FRI（Fast Reed–Solomon Interactive Oracle Proofs of Proximity）。
  - `Binius/` – Binius 型の多項式コミットメント／プロトコルに関連するコンポーネント。
  - `Component/` – 再利用可能な証明系コンポーネントやコンビネータ。
  - `ConstraintSystem/` – 多くのプロトコルの土台となる制約システムの抽象化。
  - `Fri/` – FRI プロトコル本体。
  - `Plonk/` – PLONK 型多項式コミットメントベースの証明系。
  - `Spartan/` – Spartan 型の証明系。
  - `Stir/`, `Whir/`, `Sumcheck/` – STIR・WHIR・Sumcheck プロトコルの実装。

特定のプロトコル（Sumcheck, FRI, Plonk など）の形式化を探したい場合は、このディレクトリの対応するサブディレクトリを見るのが近道です。

### `ArkLib/CommitmentScheme/`

このディレクトリには、さまざまなコミットメントスキームの定義と実装がまとめられています。多くの証明系のビルディングブロックとして使われます。

- `Basic.lean` – コミットメントスキームの共通インターフェースと基本補題。
- `Trivial.lean` – 「おもちゃ」的な単純コミットメントスキーム（ベースラインやテスト用）。
- `MerkleTree.lean`, `InductiveMerkleTree.lean` – メルクリーツリーベースのコミットメントスキーム。
- `KZG.lean` – KZG（Kate–Zaverucha–Goldberg）多項式コミットメント。
- `SimpleRO.lean` – 単純なランダムオラクルから作るコミットメントスキーム。
- `Fold.lean`, `Tensor.lean` – fold やテンソルを用いたコミットメント構成。

新しいコミットメントスキームやそのバリエーションを追加したい場合は、基本的にこのディレクトリに置きます。

### `ArkLib/Data/`

このサブツリーには、多くのプロトコルが依存している代数的・組合せ的な基盤が入っています。おおまかに、数学的トピックごとに整理されています:

- `Array/`, `List/`, `Vector/` – 基本コンテナに関する追加の結果やユーティリティ。
- `Nat/`, `CNat/` – 自然数や可算な拡張に関する定義・補題。
- `Matrix/`, `Polynomial/`, `UniPoly/`, `MvPolynomial/`, `MlPoly/` – 行列やさまざまな種類の（多変数）多項式。
- `FieldTheory/`, `RingTheory/`, `GroupTheory/` – ArkLib 向けに特化した代数的インフラ。
- `CodingTheory/`, `CodingTheory.lean` – 証明系で使われるコーディング理論的構成。
- `Fin/` – 有限添字型に関する結果。
- `Hash/` – ハッシュ関数の抽象化と補題。
- `Probability/` – 確率的な議論を支えるツール。
- `Misc/` – どこにも分類しづらい小さな補題・ユーティリティ。

mathlib にはまだ入っていないが ArkLib ではよく使う数学的道具立ての多くは、このディレクトリで開発されています。

### `ArkLib/AGM/`

`AGM/` ディレクトリには、Algebraic Group Model（AGM）に関する内容がまとまっています。

- `Basic.lean` – AGM 設定の基本定義と基本結果。

AGM に特有の議論は、基本的にここに集約されています。

### `ArkLib/ToMathlib/`

ArkLib は mathlib の上に大きく依存していますが、ArkLib が必要としている補題や定義のうち、まだ mathlib に入っていないものはここに置かれます。構成は mathlib のディレクトリ構造をざっくりと反映しています:

- `BigOperators/` – 大きな総和・総積（`∑`, `∏` など）に関する追加の結果。
- `Data/` – データ構造に関連する拡張。
- `Finset/` – 有限集合に関する追加補題。
- `Finsupp/` – 有限支え関数（`finsupp`）に関する拡張。
- `MvPolynomial/` – 多変数多項式に関する追加結果。
- `NumberTheory/` – ArkLib が必要とする数論的ツール。
- `UInt/` – 符号なし整数型に関する拡張。
- `README.md` – このディレクトリと mathlib との関係や、上流に投げる候補のメモなど。

このディレクトリは、「いずれ mathlib に upstream したいもののステージングエリア」というイメージで見ると分かりやすいです。

### `ArkLib/ToVCVio/`

このディレクトリは VCVio ライブラリとの橋渡しを担当します。

- `DistEq.lean`, `Lemmas.lean`, `Oracle.lean`, `SimOracle.lean` – ArkLib のオラクル・確率のインフラを VCVio の構成と結び付けるための互換定義や補題。

ArkLib のコードと VCVio の構成を対応付けたい場合は、まずここを探してください。

## ブループリントと説明的ドキュメント: `blueprint/`, `BACKGROUND*`, `ROADMAP*`

`ArkLib/` が機械検証されたコード本体だとすると、その周辺にあるファイル群は「その背後にある考え方」を説明する役割を担っています。

### `blueprint/`

`blueprint/` ディレクトリには、Lean コードの構成を反映した、人間向けの設計文書がまとまっています。

- `src/` – ブループリントの本文。トピックごとにサブディレクトリに分かれています:
  - `vcv/` – VCVio や関連する構成に関するブループリント。
  - `commitments/` – コミットメントスキームの設計メモ。
  - `oracle_reductions/` – オラクル還元の構成を説明するパート。
  - `coding_theory/` – コーディング理論の背景と、プロトコルにおける役割。
  - `polynomials/` – 多項式に関する背景説明や慣習。
  - `proof_systems/` – `ArkLib/ProofSystem/` に実装されている証明系の高レベルな紹介。
  - `macros/` – ブループリント用のマクロやツール。
  - `figures/` – ブループリントで使う画像や図表。
- `lean_decls` – ブループリントの項目と Lean の定義を対応付けるテキストファイル（ツールがブループリントと形式コードを結び付けるのに使います）。

Lean コードを読む前に、まず概念構造を把握したいときには、ここにある文書が一番の入口になります。

### 背景説明とロードマップ

リポジトリ直下には、次のような説明文書があります:

- `BACKGROUND.md`, `BACKGROUND.ja.md` – ArkLib の背景・動機づけや文脈の説明（英語／日本語）。
- `ROADMAP.md`, `ROADMAP.ja.md` – 今後の方向性やマイルストーン、高レベルな目標（英語／日本語）。

これらは純粋に説明用の文書であり、Lean コードは含まれていませんが、プロジェクト全体の方向性を理解するのに役立ちます。

## ツールとスクリプト: `scripts/`, `dependency_graphs/`

### `scripts/`

`scripts/` ディレクトリには、開発を支援するシェルスクリプトや Python スクリプトがまとまっています。

- `build-project.sh` – プロジェクト全体をコンパイルするための `lake build` ラッパー。
- `check-imports.sh` – `ArkLib.lean` が `ArkLib/` 以下の実際のモジュール構成と一致しているかを確認。
- `update-lib.sh` – 現在のモジュールレイアウトに基づいて `ArkLib.lean` を更新。
- `lint-style.sh`, `lint-style.lean`, `lint-style.py` – mathlib 風スタイル（命名規則、行長、docstring など）のチェック。
- `lintWhitespace.sh` – 末尾スペースなどホワイトスペースのみを対象とした lint。
- `analyze-deps-and-sorry.sh`, `dependency_analysis/`, `module_indegree_sorry.csv` – 依存構造や残っている `sorry` を解析するためのスクリプトやデータ。
- `pr-summary.py`, `review.py` – Pull Request の概要作成やレビュー作業を手助けするツール。
- `style-exceptions.txt` – スタイルチェックから一部のパスを除外するための設定。
- `README.md` – これらのスクリプト自体に関する説明。

これらのスクリプトは、`AGENTS.md` や `CONTRIBUTING.md` で説明されているコマンド経由で使うことが多いです（例: 新しいモジュールを追加した後に `./scripts/check-imports.sh` を実行するなど）。

### `dependency_graphs/`

このディレクトリには、モジュール依存構造を表す成果物が入っています:

- `arklib_dependencies.dot` – Graphviz 形式のファイル。モジュール依存グラフを図として描画できます。
- `arklib_dependencies.json` – 機械可読な JSON 形式の依存グラフ。
- `arklib_dependencies.txt` – 人間がざっと読めるテキスト形式の依存関係一覧。

モジュール間の依存関係を高い視点から眺めたいときに便利です。

## Web ページと補助ツール: `home_page/`, JavaScript 関連ファイル

### `home_page/`

- `index.html` – プロジェクトのホームページやデモ用の着地点として使える簡単な静的ページ。

このディレクトリは Lean ライブラリから独立しており、任意の静的ファイルサーバでそのまま配信できます。

### JavaScript 関連

リポジトリ直下には、JavaScript ツール向けのファイルがあります:

- `package.json`, `pnpm-lock.yaml` – Node / PNPM ベースのツール設定。
- `node_modules/` – インストール済みの JavaScript 依存パッケージ（例: `@openai/codex`）。

これらは JavaScript ツールを使うときにのみ関係があり、Lean ライブラリのビルドには必須ではありません。

## リポジトリの歩き方

- 形式化されたプロトコルを調べたり拡張したりしたいときは、`ArkLib/ProofSystem/` から入り、必要に応じて `CommitmentScheme/`、`OracleReduction/`、`Data/` へインポートをたどっていくのがおすすめです。
- 数学的な背景を知りたい、あるいは欲しい補題がすでにあるか確認したいときは、まず `ArkLib/Data/` と `ArkLib/ToMathlib/` を探してみてください。
- 新しいプロトコルや構成を追加したいときは、まず対応する `blueprint/src/` のサブディレクトリでスケッチをしてから、対応する `ArkLib/` のサブツリーに Lean 実装を書く、という流れが自然です。
- インポートやスタイルを一貫させるためには、`scripts/` 内のスクリプト（`check-imports.sh`, `lint-style.sh` など）を活用し、新しいモジュールを追加したときには `ArkLib.lean` の更新も忘れないようにします。

この構成を頭に入れておけば、`ArkLib/` をプロジェクトの「形式コア」、`blueprint/` や背景説明・ロードマップを「物語レイヤ」、`scripts/` と依存グラフをそれらをつなぐ開発ツール群として捉えられます。

