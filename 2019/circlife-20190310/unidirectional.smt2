

;(set-option :produce-models true)

(set-logic UFLIA)

(declare-fun planet (Int Int) Int)

;; The population size + its potential.
(declare-const PlanetSize Int)
(assert (> PlanetSize 0))

;; The step where the initial configuration is repeated.
(declare-const Timespan Int)
(assert (> Timespan 0))

(define-fun valid_time       ((t Int)) Bool  (and (>= t 0) (<= t Timespan)))
(define-fun valid_event_time ((t Int)) Bool  (and (>  t 0) (<= t Timespan)))
(define-fun valid_cell_index ((i Int)) Bool  (and (>= i 0) (< i PlanetSize)))


(declare-const SomeCellIndex Int)
(declare-const SomeEventTime Int)


(declare-const SingleEvent Bool)
(declare-const InductionBasisTime2 Bool)
(declare-const InductionBasisTime3 Bool)
(declare-const InductionBasisTime5 Bool)
(declare-const InductionBasisIndex2 Bool)
(assert (= SingleEvent (= Timespan 1)))
(assert (= InductionBasisTime2 (<= SomeEventTime 2)))
(assert (= InductionBasisTime3 (<= SomeEventTime 3)))
(assert (= InductionBasisTime5 (<= SomeEventTime 5)))
(assert (= InductionBasisIndex2 (<= SomeCellIndex 2)))

(declare-const Lit_TimespanUpTo4  Bool)
(assert (= Lit_TimespanUpTo4 (<= Timespan 4)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Boundary Conditions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Values wrap around.
(assert
  (forall ((t Int))
    (=> (valid_time t)
        (and
          (= (planet t -1)
             (planet t (- PlanetSize 1)))
          (= (planet t PlanetSize)
             (planet t 0))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dead cells have negative values.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-fun alive ((t Int) (i Int)) Bool
  (>= (planet t i) 0))

;; Just make them all -1.
(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_time t)
             (valid_cell_index i)
             (not (alive t i)))
        (= (planet t i) -1))))

(define-fun spawn_event ((t Int) (i Int)) Bool
  (and (not (alive (- t 1) i))
       (alive t i)))

(define-fun death_event ((t Int) (i Int)) Bool
  (and (alive (- t 1) i)
       (not (alive t i))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; How cells change as time progresses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Adjacent cells cannot be dead if life is sustained.
(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_time t)
             (valid_cell_index i))
        (or (alive t i)
            (alive t (+ i 1))))))

;; Unless there is a spawn or death, a cell's genome remains constant.
(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_event_time t)
             (valid_cell_index i)
             (= (alive t i) (alive (- t 1) i)))
        (= (planet t i)
           (planet (- t 1) i)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawning Relation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Whether a cell with the middle given genome can result from
;; cells with the given left and right genomes spawning.
(declare-fun spawnable (Int Int Int) Bool)

;; Restricted to natural numbers.
(assert
  (forall ((p Int) (c Int) (q Int))
    (=> (spawnable p c q)
        (and (>= p 0) (>= c 0) (>= q 0)))))

;;; Whether a cell can result from cells with the given genomes spawning.
(define-fun compatible ((p Int) (q Int)) Bool
  (exists ((c Int))
    (spawnable p c q)))

;; Incompatible with grandparents.
(assert
  (forall ((g Int) (p Int) (c Int)  (q Int) (h Int))
    (=> (and (spawnable g p h)
             (spawnable p c q))
        (not (compatible g c)))))
(assert
  (forall ((g Int) (p Int) (c Int)  (q Int) (h Int))
    (=> (and (spawnable g q h)
             (spawnable p c q))
        (not (compatible c h)))))

;; This is how spawning works.
(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_event_time t)
             (valid_cell_index i)
             (spawn_event t i))
        (spawnable (planet (- t 1) (- i 1))
                   (planet t i)
                   (planet (- t 1) (+ i 1))))))

(check-sat)



(define-fun Pred_SustainableDeathAddsCompatibility ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index i)
           (death_event t i))
      (compatible (planet t (- i 1))
                  (planet t (+ i 1)))))

(define-fun Pred_SustainableDeath ((t0 Int) (t1 Int) (i Int)) Bool
  (=> (and (valid_event_time t1)
           (> t1 t0)
           (spawn_event t1 i))
      (Pred_SustainableDeathAddsCompatibility t0 i)))

(declare-const Lemma_SustainableDeath Bool)
(assert (= Lemma_SustainableDeath
           (Pred_SustainableDeath 1 SomeEventTime SomeCellIndex)))
(check-sat-assuming ((not Lemma_SustainableDeath)
                     InductionBasisTime5))


;; We proved this in a  different file, so just assert it here.
(assert (forall ((t Int) (i Int))
          (Pred_SustainableDeathAddsCompatibility t i)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Proof that a spawned cell outlives its parents.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(echo "######################################################################")
(echo "Verifying both of a cell's parents must die before it dies.")

(declare-const GenomeOfLeftParent Int)
(declare-const GenomeOfInterest Int)
(declare-const GenomeOfRightParent Int)

(assert (= GenomeOfLeftParent (planet 0 (- SomeCellIndex 1))))
(assert (= GenomeOfInterest (planet 1 SomeCellIndex)))
(assert (= GenomeOfRightParent (planet 0 (+ SomeCellIndex 1))))

(define-fun Pred_ToProveSpawnedCellOutlivesParents ((i Int)) Bool
  (and
    (= i SomeCellIndex)
    (valid_cell_index i)

    ;; Cell of interest spawns at time 1.
    (spawn_event 1 i)
    ;; Wlog, assume that the right parent dies.
    (death_event 2 (+ i 1))
    ;; Except for the last step,
    ;; the cell of interest and its left parent stay alive.
    ;; Its left parent also stays alive.
    (forall ((t Int))
      (=> (and (>= t 1) (< t Timespan))
          (and (= (planet t i) GenomeOfInterest)
               (= (planet t (- i 1)) GenomeOfLeftParent))))))

(declare-const Lit_ToProveSpawnedCellOutlivesParents Bool)
(assert (= Lit_ToProveSpawnedCellOutlivesParents
           (Pred_ToProveSpawnedCellOutlivesParents SomeCellIndex)))

(echo ".. Verifying that the assumptions are sound.")
(echo "(expect sat)")
(check-sat-assuming (Lit_ToProveSpawnedCellOutlivesParents Lit_TimespanUpTo4))


(echo ".. Verifying that the left parent remains incompatible")
(echo ".. with the right neighbor as long as the left parent does not die")
(echo "(expect unsat)")
(define-fun Pred_LeftParentIncompatibleWithRightNeighbor ((t Int) (i Int)) Bool
  (=> (and (>= t 2) (< t Timespan)
           (Pred_ToProveSpawnedCellOutlivesParents i))
      (not (compatible GenomeOfLeftParent
                       (planet t (+ i 1))))))

(declare-const Lemma_LeftParentIncompatibleWithRightNeighbor Bool)
(assert (= Lemma_LeftParentIncompatibleWithRightNeighbor
           (Pred_LeftParentIncompatibleWithRightNeighbor SomeEventTime
                                                         SomeCellIndex)))
(declare-const Hypothesis_LeftParentIncompatibleWithRightNeighbor Bool)
(assert (= Hypothesis_LeftParentIncompatibleWithRightNeighbor
           (Pred_LeftParentIncompatibleWithRightNeighbor (- SomeEventTime 1)
                                                         SomeCellIndex)))

;;;; Proof by induction.
(check-sat-assuming ((not Lemma_LeftParentIncompatibleWithRightNeighbor)
                     InductionBasisTime2))
(check-sat-assuming ((not Lemma_LeftParentIncompatibleWithRightNeighbor)
                     (not InductionBasisTime2)
                     Hypothesis_LeftParentIncompatibleWithRightNeighbor))
(assert (forall ((t Int) (i Int))
          (Pred_LeftParentIncompatibleWithRightNeighbor t i)))


(echo ".. Verifying that the assumptions are sound.")
(echo "(expect sat)")
(check-sat-assuming (Lit_ToProveSpawnedCellOutlivesParents Lit_TimespanUpTo4))

(echo ".. Verifying the cell of interest cannot die")
(echo ".. because its left parent is still alive.")
(echo "(expect unsat)")
(declare-const Lit_SpawnedCellOutlivesParents Bool)
(assert (= Lit_SpawnedCellOutlivesParents
           (=> (Pred_ToProveSpawnedCellOutlivesParents SomeCellIndex)
               (not (death_event Timespan SomeCellIndex)))))

(check-sat-assuming ((not Lit_SpawnedCellOutlivesParents)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Progress.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(echo "######################################################################")
(echo "Assuming sustained life, we can force progress in our model wlog.")

(define-fun parentl ((t Int) (i Int)) Bool
  (exists ((p Int))
    (spawnable (planet t i)
               (planet t (+ i 1))
               p)))
(define-fun parentr ((t Int) (i Int)) Bool
  (exists ((p Int))
    (spawnable p
               (planet t (- i 1))
               (planet t i))))

(echo ".. Wlog assuming that, in any continuous pair of cells,")
(echo ".. one cell must have spawned the other.")
(assert (forall ((i Int))
          (=> (and (valid_cell_index i)
                   (alive 0 i)
                   (alive 0 (+ i 1)))
              (or (parentl 0 i)
                  (parentr 0 (+ i 1))))))

(define-fun death_event_if ((t Int) (i Int) (b Bool)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index i)
           b)
      (death_event t i)))

(echo ".. Wlog force parent cells compatible with a neighbor to spawn and die.")
(echo ".. Wlog force cells compatible with both neighbors to spawn 2 and die.")
(assert
  (forall ((t Int) (i Int))
    (and
      (death_event_if t i (and (not (alive (- t 1) (- i 1)))
                               (parentl (- t 1) i)))
      (death_event_if t i (and (parentr (- t 1) i)
                               (not (alive (- t 1) (+ i 1)))))
      (death_event_if t i (and (not (alive (- t 1) (- i 1)))
                               (not (alive (- t 1) (+ i 1))))))))

(echo ".. Verifying that if all cells that have spawned two others die,")
(echo ".. such parent cells will never exist at future times.")
(echo "(expect unsat)")

(define-fun Pred_ParentHasUniqueSide ((t Int) (i Int)) Bool
  (=> (and (valid_time t)
           (valid_cell_index i))
      (not (and (parentl t i)
                (parentr t i)))))

(define-fun Pred_UniqueParentSideAfterOneStep ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (death_event_if t i (not (Pred_ParentHasUniqueSide (- t 1) i))))
      (Pred_ParentHasUniqueSide t i)))

(declare-const Lemma_UniqueParentSideAfterOneStep Bool)
(assert (= Lemma_UniqueParentSideAfterOneStep
           (Pred_UniqueParentSideAfterOneStep SomeEventTime SomeCellIndex)))
(check-sat-assuming ((not Lemma_UniqueParentSideAfterOneStep)))

(assert (forall ((i Int))
          (Pred_ParentHasUniqueSide 0 i)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unidirectionality.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(echo "######################################################################")
(echo "Verifying that spawns eventually propagate in one direction.")

(echo ".. Verifying that, when enforcing necessary deaths, the distance")
(echo ".. from a right parent to a left parent strictly increases")
(echo ".. as time goes on.")
(echo ".. This means that either left or right parents will become extinct.")
(echo "(expect unsat)")

(define-fun Pred_DirectionCorrection ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index i)
           (parentr (- t 1) 0)
           (parentl (- t 1) i)
           (forall ((j Int))
             (=> (and (> j 0) (< j i))
                 (and (not (parentr (- t 1) j))
                      (not (parentl (- t 1) j))))))
      (forall ((j Int))
        (=> (and (>= j 0) (<= j i))
            (and (not (parentr t j))
                 (not (parentl t j)))))))

(declare-const Lemma_DirectionCorrection Bool)
(assert (= Lemma_DirectionCorrection
           (Pred_DirectionCorrection SomeEventTime SomeCellIndex)))

(check-sat-assuming ((not Lemma_DirectionCorrection)
                     SingleEvent))

(echo ".. Wlog removing right parents.")
(echo ".. Verifying that they are not created in subsequent steps.")
(echo "(expect unsat)")
(define-fun Pred_AllParentsHaveSameSide ((t Int)) Bool
  (forall ((i Int))
    (=> (and (valid_time t)
             (valid_cell_index i))
        (not (parentr t i)))))

(assert (Pred_AllParentsHaveSameSide 0))

(declare-const Lemma_AllParentsHaveSameSide Bool)
(assert (= Lemma_AllParentsHaveSameSide
           (Pred_AllParentsHaveSameSide SomeEventTime)))
(check-sat-assuming ((not Lemma_AllParentsHaveSameSide)
                     SingleEvent))


(echo ".. Verifying that every spawn has a death to its right side.")
(echo ".. This proves unidirectionality.")
(echo "(expect unsat)")
(define-fun Pred_Unidirectional ((t Int)) Bool
  (forall ((i Int))
    (=> (and (valid_event_time t)
             (valid_cell_index i)
             (spawn_event t i))
        (death_event t (+ i 1)))))

(declare-const Lemma_Unidirectional Bool)
(assert (= Lemma_Unidirectional
           (Pred_Unidirectional SomeEventTime)))

(check-sat-assuming ((not Lemma_Unidirectional)
                     SingleEvent))


; vim: ft=lisp:lw+=define-fun,forall,exists:
