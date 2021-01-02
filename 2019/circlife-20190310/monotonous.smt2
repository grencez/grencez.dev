
(set-logic UFLIA)

(declare-fun planet (Int Int) Int)
(declare-fun population_size (Int) Int)
(assert (> (population_size 0) 0))
(assert (= (planet 0 0)
           (planet 0 (population_size 0))))

;; The step when the cell at index 0 dies.
;; We do not bother modeling that step.
(declare-const Lifespan Int)
(assert (> Lifespan 0))

(declare-fun spawn (Int) Int)
(declare-fun death (Int) Int)

(define-fun valid_event_time ((t Int)) Bool
  (and (> t 0) (< t Lifespan)))

(define-fun valid_cell_index ((t Int) (i Int)) Bool
  (and (>= t 0) (< t Lifespan)
       (>= i 0) (<= i (population_size t))))

(assert
  (forall ((t Int))
    (=> (valid_event_time t)
        (and
          (or (= (spawn t) 0)
              (= (death t) 0))
          (or (> (spawn t) 0)
              (> (death t) 0))
          (and (<= (spawn t) (population_size (- t 1)))
               (<  (death t) (population_size (- t 1))))))))
(assert
  (forall ((t Int))
    (=> (and (valid_event_time t)
             (> (spawn t) 0))
        (= (population_size t)
           (+ (population_size (- t 1)) 1)))))

(assert
  (forall ((t Int))
    (=> (and (valid_event_time t)
             (> (death t) 0))
        (= (population_size t)
           (- (population_size (- t 1)) 1)))))


;; Variables used for proofs.
(declare-const SomeCellIndex Int)
(declare-const SomeEventTime Int)

(check-sat)

(declare-const SingleEvent Bool)
(declare-const InductionBasisTime1 Bool)
(declare-const InductionBasisTime2 Bool)
(declare-const InductionBasisIndex0 Bool)
(declare-const InductionBasisIndex1 Bool)
(declare-const InductionBasisIndex2 Bool)
(declare-const InductionBasisIndexUltimate Bool)
(assert (= SingleEvent (= Lifespan 2)))
(assert (= InductionBasisTime1 (<= SomeEventTime 1)))
(assert (= InductionBasisTime2 (<= SomeEventTime 2)))
(assert (= InductionBasisIndex0 (<= SomeCellIndex 0)))
(assert (= InductionBasisIndex1 (<= SomeCellIndex 1)))
(assert (= InductionBasisIndex2 (<= SomeCellIndex 2)))
(assert (= InductionBasisIndexUltimate (= SomeCellIndex
                                          (population_size SomeEventTime))))


(echo "######################################################################")
(echo "Verifying that the population always grows or shrinks by 1.")
(echo "(expect unsat)")
(declare-const Lemma_PopulationGrowsOrShrinksBy1 Bool)
(assert
  (= Lemma_PopulationGrowsOrShrinksBy1
     (forall ((t Int))
       (=> (valid_event_time t)
           (or (= (population_size t)
                  (- (population_size (- t 1)) 1))
               (= (population_size t)
                  (+ (population_size (- t 1)) 1)))))))
(check-sat-assuming ((not Lemma_PopulationGrowsOrShrinksBy1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; How cells shift as time progresses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_event_time t) (>= i 0)
             (or (< i (spawn t))
                 (< i (death t))))
        (= (planet t i) (planet (- t 1) i)))))


(echo "######################################################################")
(echo "Verifying that the cell of interest is copied throughout its lifetime.")
(echo "(expect unsat)")
(define-fun Pred_CellOfInterestAtIndexZero ((t Int)) Bool
  (=> (valid_event_time t)
      (= (planet t 0) (planet 0 0))))

(declare-const Lemma_CellOfInterestAtIndexZero Bool)
(assert (= Lemma_CellOfInterestAtIndexZero
           (Pred_CellOfInterestAtIndexZero SomeEventTime)))
(declare-const Hypothesis_CellOfInterestAtIndexZero Bool)
(assert (= Hypothesis_CellOfInterestAtIndexZero
           (Pred_CellOfInterestAtIndexZero (- SomeEventTime 1))))

;;;; Proof by induction.
(check-sat-assuming ((not Lemma_CellOfInterestAtIndexZero)
                     InductionBasisTime1))
(check-sat-assuming ((not Lemma_CellOfInterestAtIndexZero)
                     (not InductionBasisTime1)
                     Hypothesis_CellOfInterestAtIndexZero))
;;;; Proved.
(assert (forall ((t Int)) (Pred_CellOfInterestAtIndexZero t)))


(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_event_time t)
             (> (spawn t) 0)
             (>= i (spawn t)) (<= i (population_size (- t 1))))
        (= (planet t (+ i 1))
           (planet (- t 1) i)))))

(assert
  (forall ((t Int) (i Int))
    (=> (and (valid_event_time t)
             (> (death t) 0)
             (> i (death t)) (<= i (population_size (- t 1))))
        (= (planet t (- i 1))
           (planet (- t 1) i)))))


(echo "######################################################################")
(echo "Verifying that the cell of interest is copied to the rightmost cell.")
(echo "(expect unsat)")
(define-fun Pred_CellOfInterestAtLastIndex ((t Int)) Bool
  (=> (valid_event_time t)
      (= (planet t (population_size t)) (planet 0 0))))

(declare-const Lemma_CellOfInterestAtLastIndex Bool)
(assert (= Lemma_CellOfInterestAtLastIndex
           (Pred_CellOfInterestAtLastIndex SomeEventTime)))
(declare-const Hypothesis_CellOfInterestAtLastIndex Bool)
(assert (= Hypothesis_CellOfInterestAtLastIndex
           (Pred_CellOfInterestAtLastIndex (- SomeEventTime 1))))

;;;; Proof by induction.
(check-sat-assuming ((not Lemma_CellOfInterestAtLastIndex)
                     InductionBasisTime1))
(check-sat-assuming ((not Lemma_CellOfInterestAtLastIndex)
                     (not InductionBasisTime1)
                     Hypothesis_CellOfInterestAtLastIndex))
;;;; Proved.
(assert (forall ((t Int)) (Pred_CellOfInterestAtLastIndex t)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawning Relation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Whether a cell with the middle given genome can result from
;; cells with the given left and right genomes spawning.
(declare-fun spawnable (Int Int Int) Bool)

;;; Whether a cell can result from cells with the given genomes spawning.
;(declare-fun compatible (Int Int) Bool)
(define-fun compatible ((p Int) (q Int)) Bool
  (exists ((c Int))
    (spawnable p c q)))

;; Incompatible with parents.
(assert
  (forall ((p Int) (c Int) (q Int))
    (=> (spawnable p c q)
        (and (not (compatible p c))
             (not (compatible c q))))))

;; This is how spawning works.
(assert
  (forall ((t Int))
    (=> (and (valid_event_time t) (> (spawn t) 0))
        (spawnable (planet t (- (spawn t) 1))
                   (planet t (spawn t))
                   (planet t (+ (spawn t) 1))))))


(declare-fun population_potential_rec (Int Int) Int)
(define-fun population_potential ((t Int)) Int
  (population_potential_rec t (population_size t)))

(assert
  (forall ((t Int))
    (=> (and (>= t 0) (< t Lifespan))
        (= (population_potential_rec t 0) 0))))

(assert
  (forall ((t Int) (i Int))
    (=> (and (>= t 0) (< t Lifespan) (> i 0) (<= i (population_size t)))
        (= (population_potential_rec t i)
           (+ (ite (compatible (planet t (- i 1)) (planet t i))
                   1 0)
              (population_potential_rec t (- i 1)))))))


(push)
(echo "######################################################################")
(echo "Verifying that population potential is less than or equal to its actual size.")
(echo "(expect unsat)")
(define-fun Predicate ((t Int) (i Int)) Bool
  (<= (population_potential_rec t i)
      i))
(declare-const t Int)
(declare-const i Int)
(assert (and (>= t 0) (< t Lifespan)
             (>= i 0) (<= i (population_size t))))
;;;; For a contradiction, assume:
(assert (not (Predicate t i)))
;;;; Inductive base.
(push)
(assert (<= i 0))
(check-sat) (pop)
;;;; Inductive step.
(assert (> i 0))
(assert (Predicate t (- i 1)))
(check-sat) (pop)


(echo "######################################################################")
(echo "Verifying that a spawn decreases the population potential by 1.")
(echo "(expect unsat)")
(define-fun Pred_SpawnDecreasesPopulationPotentialByOne ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index t i)
           (> (spawn t) 0))
      (and
        (=> (< i (spawn t))
            (= (population_potential_rec t i)
               (population_potential_rec (- t 1) i)))
        (=> (= i (spawn t))
            (= (population_potential_rec t i)
               (- (population_potential_rec (- t 1) i) 1)))
        (=> (> i (spawn t))
            (= (population_potential_rec t i)
               (- (population_potential_rec (- t 1) (- i 1)) 1)))
        (=> (= i (population_size t))
            (= (population_potential t)
               (- (population_potential (- t 1)) 1))))))

(declare-const Lemma_SpawnDecreasesPopulationPotentialByOne Bool)
(assert (= Lemma_SpawnDecreasesPopulationPotentialByOne
           (Pred_SpawnDecreasesPopulationPotentialByOne
             SomeEventTime SomeCellIndex)))
(declare-const Hypothesis_SpawnDecreasesPopulationPotentialByOne Bool)
(assert (= Hypothesis_SpawnDecreasesPopulationPotentialByOne
           (Pred_SpawnDecreasesPopulationPotentialByOne
             SomeEventTime (- SomeCellIndex 1))))

;;;; Proof by induction.
(check-sat-assuming ((not Lemma_SpawnDecreasesPopulationPotentialByOne)
                     SingleEvent
                     InductionBasisIndex1))
(check-sat-assuming ((not Lemma_SpawnDecreasesPopulationPotentialByOne)
                     SingleEvent
                     (not InductionBasisIndex1)
                     Hypothesis_SpawnDecreasesPopulationPotentialByOne))
;;;; Proved.
(assert (forall ((t Int) (i Int))
          (Pred_SpawnDecreasesPopulationPotentialByOne t i)))



(echo "######################################################################")
(echo "Verifying that a death at most increases the population potential by 1.")
(echo "(expect unsat)")
(define-fun Pred_DeathIncreasesPopulationPotentialByAtMostOne ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index t i)
           (> (death t) 0))
      (and
        (=> (< i (death t))
            (= (population_potential_rec t i)
               (population_potential_rec (- t 1) i)))
        (=> (>= i (death t))
            (<= (population_potential_rec t i)
                (+ (population_potential_rec (- t 1) (+ i 1)) 1)))
        (=> (= i (population_size t))
            (<= (population_potential t)
               (+ (population_potential (- t 1)) 1))))))

(declare-const Lemma_DeathIncreasesPopulationPotentialByAtMostOne Bool)
(assert (= Lemma_DeathIncreasesPopulationPotentialByAtMostOne
           (Pred_DeathIncreasesPopulationPotentialByAtMostOne
             SomeEventTime SomeCellIndex)))
(declare-const Hypothesis_DeathIncreasesPopulationPotentialByAtMostOne Bool)
(assert (= Hypothesis_DeathIncreasesPopulationPotentialByAtMostOne
           (Pred_DeathIncreasesPopulationPotentialByAtMostOne
             SomeEventTime (- SomeCellIndex 1))))

;;;; Proof by induction.
(check-sat-assuming ((not Lemma_DeathIncreasesPopulationPotentialByAtMostOne)
                     SingleEvent
                     InductionBasisIndex1))
(check-sat-assuming ((not Lemma_DeathIncreasesPopulationPotentialByAtMostOne)
                     SingleEvent
                     (not InductionBasisIndex1)
                     Hypothesis_DeathIncreasesPopulationPotentialByAtMostOne))
;;;; Proved.
(assert (forall ((t Int) (i Int))
          (Pred_DeathIncreasesPopulationPotentialByAtMostOne t i)))


(echo "######################################################################")
(echo "Verifying that the sum of population size and potential is non-increasing.")
(echo "(expect unsat)")
(define-fun Pred_NonIncreasingPopulationSizePlusPotential ((t Int)) Bool
  (=> (and (valid_event_time t))
      (<= (+ (population_size t) (population_potential t))
          (+ (population_size (- t 1)) (population_potential (- t 1))))))
(declare-const Lemma_NonIncreasingPopulationSizePlusPotential Bool)
(assert (= Lemma_NonIncreasingPopulationSizePlusPotential
           (Pred_NonIncreasingPopulationSizePlusPotential SomeEventTime)))
(check-sat-assuming ((not Lemma_NonIncreasingPopulationSizePlusPotential)))
;;;; Proved.
(assert (forall ((t Int))
          (Pred_NonIncreasingPopulationSizePlusPotential t)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sustainability.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; In order to sustain life, the population size plus its potential cannot ever
;; decrease. This sum cannot increase, so any decrease would be permanent.
(define-fun SustainedLife ((t Int)) Bool
  (=> (valid_event_time t)
      (= (+ (population_size t) (population_potential t))
         (+ (population_size (- t 1)) (population_potential (- t 1))))))

(declare-const Lit_SustainedLife Bool)
(assert (= Lit_SustainedLife
           (SustainedLife SomeEventTime)))

(echo "######################################################################")
(echo "Verifying that each cell that dies must be incompatible with its neighbors,")
(echo "and those neighbors must be compatible with each other if life is sustained.")
(define-fun Pred_SustainableDeathAddsCompatibility ((t Int)) Bool
  (=> (and (valid_event_time t)
           (> (death t) 0)
           (SustainedLife t))
      (and
        (not (compatible (planet (- t 1) (- (death t) 1))
                         (planet (- t 1) (death t))))
        (not (compatible (planet (- t 1) (death t))
                         (planet (- t 1) (+ (death t) 1))))
        (compatible (planet (- t 1) (- (death t) 1))
                    (planet (- t 1) (+ (death t) 1))))))


(define-fun Pred_SustainableDeath ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index t i)
           (> (death t) 0))
    (and
      (=> (< i (death t))
          (= (population_potential_rec t i)
             (population_potential_rec (- t 1) i)))
      (=> (= i (death t))
          (= (population_potential_rec t i)
             (+ (population_potential_rec (- t 1) i)
                1)))
      (=> (= i (death t))
          (not (compatible (planet (- t 1) (- i 1))
                           (planet (- t 1) i))))
      (=> (= i (death t))
          (not (compatible (planet (- t 1) i)
                           (planet (- t 1) (+ i 1)))))
      (=> (= i (death t))
          (compatible (planet (- t 1) (- i 1))
                      (planet (- t 1) (+ i 1))))
      (=> (>= i (death t))
          (= (population_potential_rec t i)
             (+ (population_potential_rec (- t 1) (+ i 1))
                1))))))


(echo ".. Proving that we can apply downward induction on Pred_SustainableDeath.")
(echo "(expect unsat)")
(define-fun Pred_Downward_SustainableDeath ((t Int) (i Int)) Bool
  (=> (and (valid_event_time t)
           (valid_cell_index t i))
      (=> (Pred_SustainableDeath t i)
          (Pred_SustainableDeath t (- i 1)))))

(declare-const Lemma_Downward_SustainableDeath Bool)
(assert (= Lemma_Downward_SustainableDeath
           (Pred_Downward_SustainableDeath SomeEventTime SomeCellIndex)))

(check-sat-assuming ((not Lemma_Downward_SustainableDeath)
                     SingleEvent))
(assert (forall ((t Int) (i Int))
          (Pred_Downward_SustainableDeath t i)))
(assert (forall ((t Int) (i Int) (j Int))
          (=> (and (< j i)
                   (valid_event_time t)
                   (valid_cell_index t i)
                   (Pred_SustainableDeath t i))
              (Pred_SustainableDeath t j))))


(echo ".. Verifying that SustainedLife implies Pred_SustainableDeath.")
(echo "(expect unsat)")

(declare-const Lit_SustainableDeath Bool)
(assert (= Lit_SustainableDeath
           (Pred_SustainableDeath SomeEventTime SomeCellIndex)))

(check-sat-assuming ((not Lit_SustainableDeath)
                     InductionBasisIndexUltimate
                     Lit_SustainedLife))
(assert (forall ((t Int))
          (=> (SustainedLife t)
              (Pred_SustainableDeath t (population_size t)))))

(check-sat-assuming ((not Lit_SustainableDeath)
                     Lit_SustainedLife))
(assert (forall ((t Int) (i Int))
          (=> (SustainedLife t)
              (Pred_SustainableDeath t i))))

(echo ".. Verifying the actual lemma.")
(echo "(expect unsat)")

(declare-const Lemma_SustainableDeathAddsCompatibility Bool)
(assert (= Lemma_SustainableDeathAddsCompatibility
           (Pred_SustainableDeathAddsCompatibility SomeEventTime)))
(check-sat-assuming ((not Lemma_SustainableDeathAddsCompatibility)
                     SingleEvent))

;;;; Proved.
(assert (forall ((t Int))
          (Pred_SustainableDeathAddsCompatibility t)))


; vim: ft=lisp:lw+=define-fun,forall,exists:
