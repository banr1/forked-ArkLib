/-
Place this file anywhere in your repo, e.g. `Scripts/ExportRootNamespaces.lean`.
Import your project's root module before using the commands below:
  - `#export_root_namespaces "root_namespaces.csv"` writes the top-level namespaces to CSV.
-/
import Lean
import ArkLib

open Lean System
open Lean Elab Command

/-- `n` のすべての「親」プレフィクス（= namespace 候補）を列挙する。
    例: `A.B.c` → [`A`, `A.B`] -/
partial def parentPrefixes (n : Name) : List Name :=
  if n.isAnonymous then
    []
  else
    let p := n.getPrefix
    if p.isAnonymous then
      []
    else
      parentPrefixes p ++ [p]

/-- 環境内の全定数名から namespace 候補を収集する。 -/
def collectNamespaces (env : Environment) : Std.HashSet Name :=
  Id.run do
    let mut s : Std.HashSet Name := {}
    -- `constants` は Name → ConstantInfo のマップ
    for (n, _) in env.constants.toList do
      for p in parentPrefixes n do
        s := s.insert p
    return s

/-- 集めた namespace を文字列化してソートして返す。 -/
def sortedNamespaceStrings (s : Std.HashSet Name) : List String :=
  let arr := s.toArray.map (·.toString)
  arr.qsort (· < ·) |>.toList

def namespaceStrings (env : Environment) : List String :=
  sortedNamespaceStrings (collectNamespaces env)

/-- ルート namespace（= 最上位のセグメント）だけを取り出す。 -/
def rootNamespace? : Name → Option Name
  | .anonymous => none
  | .str .anonymous s => some (.str .anonymous s)
  | .str p _ => rootNamespace? p
  | .num p _ => rootNamespace? p

/-- namespace 候補の集合から、最上位セグメントのみに絞った集合を作る。 -/
def rootNamespaces (s : Std.HashSet Name) : Std.HashSet Name :=
  Id.run do
    let mut roots : Std.HashSet Name := {}
    for n in s.toArray do
      if let some r := rootNamespace? n then
        roots := roots.insert r
    return roots

def rootNamespaceStrings (env : Environment) : List String :=
  sortedNamespaceStrings (rootNamespaces (collectNamespaces env))

/-- 環境から集めた namespace 名のリストをログ出力する。 -/
def logNamespaces (ns : List String) : CommandElabM Unit := do
  if ns.isEmpty then
    logInfo "(no namespaces found)"
  else
    -- 1 行ずつ出力（エディタの Messages/Info に表示されます）
    for n in ns do
      logInfo m!"{n}"

def csvEscape (s : String) : String :=
  if s.any (fun c => c = ',' || c = '"' || c = '\n' || c = '\r') then
    let escaped := s.replace "\"" "\"\""
    s!"\"{escaped}\""
  else
    s

def namespaceCsv (ns : List String) : String :=
  let rows := ns.map csvEscape
  String.intercalate "\n" ("namespace" :: rows) ++ "\n"

/-- Write the top-level namespaces in the current environment to a CSV file. -/
def exportRootNamespaces (output : System.FilePath) : CommandElabM Unit := do
  let env ← getEnv
  let ns := rootNamespaceStrings env
  let csv := namespaceCsv ns
  if let some parent := output.parent then
    liftIO <| IO.FS.createDirAll parent
  liftIO <| IO.FS.writeFile output csv
  logInfo m!"wrote {ns.length} root namespaces to {output}"

/-- `#print_namespaces` コマンド本体 -/
elab "#print_namespaces" : command => do
  let env ← getEnv
  logNamespaces (namespaceStrings env)

/-- ルート namespace のみを列挙するバリアント -/
elab "#print_root_namespaces" : command => do
  let env ← getEnv
  logNamespaces (rootNamespaceStrings env)

syntax (name := exportRootNamespacesCommand) "#export_root_namespaces" str : command

@[command_elab exportRootNamespacesCommand]
def elabExportRootNamespaces : CommandElab := fun stx => do
  let some path := stx[1].isStrLit?
    | throwError "#export_root_namespaces expects a string literal path"
  exportRootNamespaces (System.FilePath.mk path)

#export_root_namespaces "Playground/root_namespaces.csv"
