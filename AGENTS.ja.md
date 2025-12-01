# リポジトリガイドライン

## プロジェクト構成とモジュール整理
ArkLib は Lean 4 向けライブラリ（ツールチェーン `leanprover/lean4:v4.22.0`）。
中核ソースは `ArkLib/` にあり、トピックごとに整理:
`OracleReduction/` はインタラクティブな帰着,
`ProofSystem/` はプロトコルの形式化,
`CommitmentScheme/` はコミットメント,
`Data/` は代数/データ構造の補助,
`ToMathlib/` と `ToVCVio/` は互換レイヤー。
`ArkLib.lean` がすべての import を束ねる。
補助資料: `blueprint/`（設計ドキュメント）、`BACKGROUND*.md` と `ROADMAP*.md`
（背景/ロードマップ）、`scripts/`（ツール類）、`home_page/`（サイト資産）。

## ビルド・テスト・開発コマンド
ピン留めされた toolchain を入れた上でリポジトリルートで実行。
- `lake update` — `lakefile.toml` に列挙された Lake 依存を取得。
- `lake build ArkLib` — ライブラリをコンパイル。デフォルトターゲットには `lake build` を使う。
- `./scripts/check-imports.sh` — `ArkLib.lean` が存在するモジュールと一致するか確認。
  古ければ `./scripts/update-lib.sh` を実行。
- `./scripts/lint-style.sh` — mathlib 形式のチェック（docstring, 行長, 大文字小文字, 実行ビット）。
  `scripts/style-exceptions.txt` を尊重。
- インタラクティブ作業には `lake env lean` またはエディタの Lean 4 サポートを使う。

## コーディングスタイルと命名規則
mathlib のスタイルガイド（`CONTRIBUTING.md` 参照）に従う: インデントはスペース 2 個、タブ不可、
行は 100 文字以内（URL などやむを得ない場合を除く）、束縛は明示的（`autoImplicit := false`）。
新規ファイルには先頭にモジュール docstring を付け、非自明な定義/定理には短い docstring を添える。
読める証明スクリプトを不透明な項証明より優先する。
モジュール名は CamelCase パス（`ProofSystem.Sumcheck`）、定義/定理は mathlib 慣習に沿った
説明的な snake_case にする。import は最小限かつソートし、大きな名前空間を global に `open` しない。

## テスト方針
コンパイルを主なテストとみなし、`lake build` が `sorry` なしで通るようにする。
新しい実行的定義には、期待される振る舞いを確かめるため同じ名前空間に小さな `example`
ブロックや補助補題を追加する。import 境界に触れた場合は `./scripts/check-imports.sh` を、
スタイル影響がある変更ではプッシュ前に `./scripts/lint-style.sh` を走らせる。
証明は決定的に保ち、暗黙検索の順序に依存する脆いタクティクスを避ける。

## コミットと Pull Request のガイドライン
コミットタイトルは既存パターンに合わせ、短い接頭辞とスコープを付ける
（例: `feat: computable additive NTT (#94)`）。件名は簡潔にし、関連する変更はコミットごとにまとめる。
PR では短い概要、関連 issue へのリンク（`Fixes #123`）、実行したコマンド（build/lint）を列挙し、
blueprint やドキュメント更新があれば記載する。描画結果が変わる資産（例: `home_page/`）を
変更しない限りスクリーンショットは不要。新しいモジュールは `ArkLib.lean` に import し、
文書化する。*** End Patch
