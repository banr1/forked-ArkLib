import ArkLib.ToMathlib.Data.IndexedBinaryTree.Basic


/-!
# Equivalences

This section contains theorems about equivalences between different tree indexing types
and data structures.
-/

namespace BinaryTree

section Equivalences

/-- Build `LeafData` from a function on leaf indices. -/
def LeafData.ofFun {α : Type} (s : Skeleton)
    (f : SkeletonLeafIndex s → α) : LeafData α s :=
  match s with
  | .leaf => LeafData.leaf (f SkeletonLeafIndex.ofLeaf)
  | .internal l r =>
      LeafData.internal
        (LeafData.ofFun l (fun idx => f (SkeletonLeafIndex.ofLeft idx)))
        (LeafData.ofFun r (fun idx => f (SkeletonLeafIndex.ofRight idx)))

@[simp]
theorem LeafData.ofFun_get {α} {s} (tree : LeafData α s) :
    LeafData.ofFun s (fun idx => tree.get idx) = tree := by
  cases tree with
  | leaf value =>
    simp [LeafData.ofFun, LeafData.get_leaf]
  | @internal l r left right =>
    have ihL := LeafData.ofFun_get (s := l) left
    have ihR := LeafData.ofFun_get (s := r) right
    simp [LeafData.ofFun, ihL, ihR]

@[simp]
theorem LeafData.get_ofFun {α} {s} (f : SkeletonLeafIndex s → α) :
    (LeafData.ofFun s f).get = f := by
  funext idx
  induction idx with
  | ofLeaf => simp [LeafData.ofFun, LeafData.get_leaf]
  | ofLeft idx ih => simp [LeafData.ofFun, ih]
  | ofRight idx ih => simp [LeafData.ofFun, ih]

/-- Build `InternalData` from a function on internal indices. -/
def InternalData.ofFun {α : Type} (s : Skeleton)
    (f : SkeletonInternalIndex s → α) : InternalData α s :=
  match s with
  | .leaf => InternalData.leaf
  | .internal l r =>
      InternalData.internal
        (f SkeletonInternalIndex.ofInternal)
        (InternalData.ofFun l (fun idx => f (SkeletonInternalIndex.ofLeft idx)))
        (InternalData.ofFun r (fun idx => f (SkeletonInternalIndex.ofRight idx)))

@[simp]
theorem InternalData.ofFun_get {α} {s} (tree : InternalData α s) :
    InternalData.ofFun s (fun idx => tree.get idx) = tree := by
  cases tree with
  | leaf => simp [InternalData.ofFun]
  | @internal l r value left right =>
    have ihL := InternalData.ofFun_get (s := l) left
    have ihR := InternalData.ofFun_get (s := r) right
    simp [InternalData.ofFun, InternalData.get, ihL, ihR]

@[simp]
theorem InternalData.get_ofFun {α} {s} (f : SkeletonInternalIndex s → α) :
    (InternalData.ofFun s f).get = f := by
  funext idx
  induction idx with
  | ofInternal => simp [InternalData.ofFun, InternalData.get]
  | ofLeft idx ih => simp [InternalData.ofFun, InternalData.get, ih]
  | ofRight idx ih => simp [InternalData.ofFun, InternalData.get, ih]

/-- Build `FullData` from a function on all node indices. -/
def FullData.ofFun {α : Type} (s : Skeleton)
    (f : SkeletonNodeIndex s → α) : FullData α s :=
  match s with
  | .leaf => FullData.leaf (f SkeletonNodeIndex.ofLeaf)
  | .internal l r =>
      FullData.internal
        (f SkeletonNodeIndex.ofInternal)
        (FullData.ofFun l (fun idx => f (SkeletonNodeIndex.ofLeft idx)))
        (FullData.ofFun r (fun idx => f (SkeletonNodeIndex.ofRight idx)))

@[simp]
theorem FullData.ofFun_get {α} {s} (tree : FullData α s) :
    FullData.ofFun s (fun idx => tree.get idx) = tree := by
  cases tree with
  | leaf value => simp [FullData.ofFun, FullData.get_leaf]
  | @internal l r value left right =>
    have ihL := FullData.ofFun_get (s := l) left
    have ihR := FullData.ofFun_get (s := r) right
    simp [FullData.ofFun, FullData.get, ihL, ihR]

@[simp]
theorem FullData.get_ofFun {α} {s} (f : SkeletonNodeIndex s → α) :
    (FullData.ofFun s f).get = f := by
  funext idx
  induction idx with
  | ofLeaf => simp [FullData.ofFun, FullData.get_leaf]
  | ofInternal => simp [FullData.ofFun, FullData.get]
  | ofLeft idx ih => simp [FullData.ofFun, FullData.get, ih]
  | ofRight idx ih => simp [FullData.ofFun, FullData.get, ih]

/-- `LeafData`s are equivalent to functions from `SkeletonLeafIndex` to values -/
def LeafData.EquivIndexFun {α : Type} (s : Skeleton) :
    LeafData α s ≃ (SkeletonLeafIndex s → α) where
  toFun := fun tree idx => tree.get idx
  invFun := fun f => LeafData.ofFun s f
  left_inv := by
    intro tree
    cases s with
    | leaf =>
        cases tree with
        | leaf value =>
            simp [LeafData.ofFun, LeafData.get_leaf]
    | @internal l r =>
        cases tree with
        | internal left right =>
            simp [LeafData.ofFun]
  right_inv := by
    intro f
    simp [LeafData.get_ofFun (s := s) f]

/-- `InternalData`s are equivalent to functions from `SkeletonInternalIndex` to values -/
def InternalData.EquivIndexFun {α : Type} (s : Skeleton) :
    InternalData α s ≃ (SkeletonInternalIndex s → α) where
  toFun := fun tree idx => tree.get idx
  invFun := fun f => InternalData.ofFun s f
  left_inv := by
    intro tree
    cases s with
    | leaf =>
        cases tree with
        | leaf => simp [InternalData.ofFun]
    | @internal l r =>
        cases tree with
        | internal value left right => simp [InternalData.ofFun, InternalData.get]
  right_inv := by
    intro f
    simp [InternalData.get_ofFun (s := s) f]

/-- `FullData`s are equivalent to functions from `SkeletonNodeIndex` to values -/
def FullData.EquivIndexFun {α : Type} (s : Skeleton) :
    FullData α s ≃ (SkeletonNodeIndex s → α) where
  toFun := fun tree idx => tree.get idx
  invFun := fun f => FullData.ofFun s f
  left_inv := by
    intro tree
    cases s with
    | leaf =>
        cases tree with
        | leaf value => simp [FullData.ofFun, FullData.get_leaf]
    | @internal l r =>
        cases tree with
        | internal value left right =>
            simp [FullData.ofFun, FullData.get]
  right_inv := by
    intro f
    simp [FullData.get_ofFun (s := s) f]

/-- A `LeafData` can be interpreted as a function from `SkeletonLeafIndex` to values -/
instance {α : Type} {s : Skeleton} :
    CoeFun (LeafData α s) fun (_ : LeafData α s) => SkeletonLeafIndex s → α where
  coe := fun tree idx => tree.get idx

/-- An `InternalData` can be interpreted as a function from `SkeletonInternalIndex` to values -/
instance {α : Type} {s : Skeleton} :
    CoeFun (InternalData α s) fun (_ : InternalData α s) => SkeletonInternalIndex s → α where
  coe := fun tree idx => tree.get idx

/-- A `FullData` can be interpreted as a function from `SkeletonNodeIndex` to values -/
instance {α : Type} {s : Skeleton} :
    CoeFun (FullData α s) fun (_ : FullData α s) => SkeletonNodeIndex s → α where
  coe := fun tree idx => tree.get idx

/--
A function taking a `SkeletonNodeIndex s`
to either a `SkeletonInternalIndex s` or a `SkeletonLeafIndex s`
-/
def SkeletonNodeIndex.toSum {s : Skeleton} :
    SkeletonNodeIndex s → SkeletonInternalIndex s ⊕ SkeletonLeafIndex s :=
  fun idx =>
    match idx with
    | SkeletonNodeIndex.ofLeaf => Sum.inr (SkeletonLeafIndex.ofLeaf)
    | SkeletonNodeIndex.ofInternal => Sum.inl (SkeletonInternalIndex.ofInternal)
    | SkeletonNodeIndex.ofLeft idxLeft => match idxLeft.toSum with
      | .inl idxLeft => Sum.inl (SkeletonInternalIndex.ofLeft idxLeft)
      | .inr idxLeft => Sum.inr (SkeletonLeafIndex.ofLeft idxLeft)
    | SkeletonNodeIndex.ofRight idxRight => match idxRight.toSum with
      | .inl idxRight => Sum.inl (SkeletonInternalIndex.ofRight idxRight)
      | .inr idxRight => Sum.inr (SkeletonLeafIndex.ofRight idxRight)

/-- Equivalence between node indices and the sum of internal and leaf indices -/
def FunEquivNodeSum (s : Skeleton) {α} :
    (SkeletonNodeIndex s → α) ≃ (SkeletonInternalIndex s → α) × (SkeletonLeafIndex s → α) :=
{ toFun := fun f =>
    (fun i => f (SkeletonInternalIndex.toNodeIndex i),
     fun j => f (SkeletonLeafIndex.toNodeIndex j))
  , invFun := fun p idx => match idx.toSum with
      | Sum.inl i => p.fst i
      | Sum.inr j => p.snd j
  , right_inv := by
      intro p
      cases p with
      | mk f g =>
        refine Prod.ext ?h1 ?h2
        · funext i
          induction i with
          | ofInternal =>
              simp [SkeletonNodeIndex.toSum, SkeletonInternalIndex.toNodeIndex]
          | ofLeft i ih =>
              have h' := ih (fun x => f x.ofLeft) (fun y => g y.ofLeft)
              cases hSum : (i.toNodeIndex).toSum with
              | inl _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex] using h'
              | inr _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex] using h'
          | ofRight i ih =>
              have h' := ih (fun x => f x.ofRight) (fun y => g y.ofRight)
              cases hSum : (i.toNodeIndex).toSum with
              | inl _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex] using h'
              | inr _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex] using h'
        · funext j
          induction j with
          | ofLeaf =>
              simp [SkeletonNodeIndex.toSum, SkeletonLeafIndex.toNodeIndex]
          | ofLeft j ih =>
              have h' := ih (fun x => f x.ofLeft) (fun y => g y.ofLeft)
              cases hSum : (j.toNodeIndex).toSum with
              | inl _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonLeafIndex.toNodeIndex] using h'
              | inr _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonLeafIndex.toNodeIndex] using h'
          | ofRight j ih =>
              have h' := ih (fun x => f x.ofRight) (fun y => g y.ofRight)
              cases hSum : (j.toNodeIndex).toSum with
              | inl _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonLeafIndex.toNodeIndex] using h'
              | inr _ =>
                  simpa [SkeletonNodeIndex.toSum, hSum, SkeletonLeafIndex.toNodeIndex] using h'
  , left_inv := by
      intro f; funext idx
      induction idx with
      | ofLeaf => simp [SkeletonNodeIndex.toSum, SkeletonLeafIndex.toNodeIndex]
      | ofInternal => simp [SkeletonNodeIndex.toSum, SkeletonInternalIndex.toNodeIndex]
      | ofLeft idx ih =>
          have h' := ih (fun x => f x.ofLeft)
          cases hSum : idx.toSum with
          | inl _ =>
              simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex,
                     SkeletonLeafIndex.toNodeIndex]
                using h'
          | inr _ =>
              simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex,
                     SkeletonLeafIndex.toNodeIndex]
                using h'
      | ofRight idx ih =>
          have h' := ih (fun x => f x.ofRight)
          cases hSum : idx.toSum with
          | inl _ =>
              simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex,
                     SkeletonLeafIndex.toNodeIndex]
                using h'
          | inr _ =>
              simpa [SkeletonNodeIndex.toSum, hSum, SkeletonInternalIndex.toNodeIndex,
                     SkeletonLeafIndex.toNodeIndex]
                using h'
}

/-- Equivalence between `FullData` and the product of `InternalData` and `LeafData` -/
def FullData.Equiv {α} (s : Skeleton) :
    FullData α s ≃ InternalData α s × LeafData α s := by
  calc
    FullData α s ≃ (SkeletonNodeIndex s → α) := FullData.EquivIndexFun s
    _ ≃ (SkeletonInternalIndex s → α) × (SkeletonLeafIndex s → α) := FunEquivNodeSum s
    _ ≃ InternalData α s × LeafData α s := by
      refine
        { toFun := (fun p => ((InternalData.EquivIndexFun s).invFun p.fst,
                               (LeafData.EquivIndexFun s).invFun p.snd))
          , invFun := (fun q => ((InternalData.EquivIndexFun s).toFun q.fst,
                                 (LeafData.EquivIndexFun s).toFun q.snd))
          , left_inv := ?_
          , right_inv := ?_ };
      · intro p; cases p with
        | mk f g =>
          exact Prod.ext
            ((InternalData.EquivIndexFun s).right_inv f)
            ((LeafData.EquivIndexFun s).right_inv g)
      · intro q; cases q with
        | mk tInt tLeaf =>
          exact Prod.ext
            ((InternalData.EquivIndexFun s).left_inv tInt)
            ((LeafData.EquivIndexFun s).left_inv tLeaf)


end Equivalences

end BinaryTree
