import ArkLib.OracleReduction.Composition.Sequential.General
import ArkLib.ProofSystem.Fri.Spec.SingleRound
import ArkLib.ProofSystem.Fri.Domain

namespace Fri

open OracleSpec OracleComp ProtocolSpec Domain

namespace Spec

variable {F : Type} [NonBinaryField F] [Finite F]
variable (D : Subgroup Fˣ) {n : ℕ} [DIsCyclicC : IsCyclicWithGen D] [DSmooth : SmoothPowerOfTwo n D]
variable (x : Fˣ)
variable (k s d : ℕ) (k_le_n : 2 ^ ((k + 1) * s) * d ≤ 2 ^ n) [NeZero s] [NeZero d] (i : Fin k)
variable (l : ℕ)

@[reducible]
def pSpecFold : ProtocolSpec (Fin.vsum fun (_ : Fin k) ↦ 2) :=
  ProtocolSpec.seqCompose (fun (i : Fin k) => FoldPhase.pSpec D x s i)

instance : ∀ j, OracleInterface ((pSpecFold D x k s).Message j) :=
  instOracleInterfaceMessageSeqCompose

instance : ∀ j, OracleInterface (((pSpecFold D x k s ++ₚ FinalFoldPhase.pSpec F)).Message j) :=
  instOracleInterfaceMessageAppend

instance :
    ∀ i, OracleInterface
          ((pSpecFold D x k s ++ₚ FinalFoldPhase.pSpec F ++ₚ QueryRound.pSpec D x l).Message i) :=
  instOracleInterfaceMessageAppend

@[reducible]
noncomputable def reductionFold :
  OracleReduction []ₒ
    (Statement F (0 : Fin (k + 1))) (OracleStatement D x s (0 : Fin (k + 1))) (Witness F)
    (FinalStatement F k) (FinalOracleStatement D x s k) (Witness F)
    (pSpecFold D x k s ++ₚ FinalFoldPhase.pSpec F)
 := OracleReduction.append
      (OracleReduction.seqCompose _ _ (fun (_ : Fin (k + 1)) => Witness F)
        (FoldPhase.foldOracleReduction D x s))
      (FinalFoldPhase.finalFoldOracleReduction D x (k := k) s d)

@[reducible]
noncomputable def reduction [DecidableEq F] :
  OracleReduction []ₒ
    (Statement F (0 : Fin (k + 1))) (OracleStatement D x s (0 : Fin (k + 1))) (Witness F)
    (FinalStatement F k) (FinalOracleStatement D x s k) (Witness F)
    (pSpecFold D x k s ++ₚ FinalFoldPhase.pSpec F ++ₚ QueryRound.pSpec D x l) :=
  OracleReduction.append (reductionFold D x k s d)
    (QueryRound.queryOracleReduction (k := k) D x s d k_le_n l)

end Spec

end Fri
