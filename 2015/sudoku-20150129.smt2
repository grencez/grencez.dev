
;; Run with: z3 sudoku.smt2

;; This file is structured as follows:
;; 1. Sets up the data types and helper functions.
;; 2. Assertions are made to define what a valid Sudoku solution is.
;; 3. An example board is given, though only some numbers are filled in!
;; 4. This leaves the SMT solver Z3 with the task of filling in the blanks.
;;    This is done with (check-sat), and then the board content is printed.

;; Technically this should be here for the use of (get-value) at the end.
(set-option :produce-models true)

;; Declare a finite-domain type called Val with 9 possible values V1..V9.
(declare-datatypes () ((Val V1 V2 V3 V4 V5 V6 V7 V8 V9)))

;; Uninterpreted function that serves as a Sudoku board
;; from (board 0 0) to (board 8 8) because 0-indexing is best indexing.
(declare-fun board (Int Int) Val)

;; Check that an index is in bounds.
(define-fun valid_index ((i Int)) Bool
  (and (>= i 0) (< i 9)))

;; If you use Int instead of Val for values on the board,
;; then uncomment this assertion to ensure that:
;; All values are between 1 and 9 (inclusive).
;(assert
;  (forall ((row Int) (col Int))
;    (and (>= (board row col) 1)
;         (<= (board row col) 9))))

;; All values in a row are unique.
(assert
  (forall ((row Int) (i Int) (j Int))
    (=>
      (and
        (not (= i j))
        (valid_index row)
        (valid_index i)
        (valid_index j))
      (not (= (board row i)
              (board row j))))))

;; All values in a column are unique.
(assert
  (forall ((col Int) (i Int) (j Int))
    (=>
      (and
        (not (= i j))
        (valid_index col)
        (valid_index i)
        (valid_index j))
      (not (= (board i col)
              (board j col))))))

;; All values in each box are unique.
(assert
  (forall ((row1 Int) (col1 Int)
           (row2 Int) (col2 Int))
    (=>
      ;; If the below 3 are true...
      (and
        ;; 1. Row and column indices are in bounds.
        (valid_index row1) (valid_index col1)
        (valid_index row2) (valid_index col2)
        ;; 2. They are not the same elements.
        (or (not (= row1 row2))
            (not (= col1 col2)))
        ;; 3. They do exist in the same box.
        (= (div row1 3) (div row2 3))
        (= (div col1 3) (div col2 3)))
      ;; ... then the values must differ!
      (not (= (board row1 col1)
              (board row2 col2))))))

;; Use this board:
; 0 0 0  8 0 6  7 0 0
; 0 0 0  2 9 0  0 4 0
; 9 0 0  0 0 7  0 0 6
;
; 5 0 0  0 0 8  4 0 0
; 6 0 0  0 0 0  2 5 0
; 0 0 2  7 6 0  0 0 0
;
; 0 0 0  6 0 0  1 7 0
; 0 0 0  0 7 0  5 0 4
; 0 4 0  0 1 0  0 9 0
;; Row 0
(assert (= (board 0 3) V8))
(assert (= (board 0 5) V6))
(assert (= (board 0 6) V7))
;; Row 1
(assert (= (board 1 3) V2))
(assert (= (board 1 4) V9))
(assert (= (board 1 7) V4))
;; Row 2
(assert (= (board 2 0) V9))
(assert (= (board 2 5) V7))
(assert (= (board 2 8) V6))
;; Row 3
(assert (= (board 3 0) V5))
(assert (= (board 3 5) V8))
(assert (= (board 3 6) V4))
;; Row 4
(assert (= (board 4 0) V6))
(assert (= (board 4 6) V2))
(assert (= (board 4 7) V5))
;; Row 5
(assert (= (board 5 2) V2))
(assert (= (board 5 3) V7))
(assert (= (board 5 4) V6))
;; Row 6
(assert (= (board 6 3) V6))
(assert (= (board 6 6) V1))
(assert (= (board 6 7) V7))
;; Row 7
(assert (= (board 7 4) V7))
(assert (= (board 7 6) V5))
(assert (= (board 7 8) V4))
;; Row 8
(assert (= (board 8 1) V4))
(assert (= (board 8 4) V1))
(assert (= (board 8 7) V9))

(check-sat)
;(get-model)

(echo "Row:0")
(get-value ((board 0 0) (board 0 1) (board 0 2) (board 0 3) (board 0 4) (board 0 5) (board 0 6) (board 0 7) (board 0 8)))
(echo "Row:1")
(get-value ((board 1 0) (board 1 1) (board 1 2) (board 1 3) (board 1 4) (board 1 5) (board 1 6) (board 1 7) (board 1 8)))
(echo "Row:2")
(get-value ((board 2 0) (board 2 1) (board 2 2) (board 2 3) (board 2 4) (board 2 5) (board 2 6) (board 2 7) (board 2 8)))
(echo "Row:3")
(get-value ((board 3 0) (board 3 1) (board 3 2) (board 3 3) (board 3 4) (board 3 5) (board 3 6) (board 3 7) (board 3 8)))
(echo "Row:4")
(get-value ((board 4 0) (board 4 1) (board 4 2) (board 4 3) (board 4 4) (board 4 5) (board 4 6) (board 4 7) (board 4 8)))
(echo "Row:5")
(get-value ((board 5 0) (board 5 1) (board 5 2) (board 5 3) (board 5 4) (board 5 5) (board 5 6) (board 5 7) (board 5 8)))
(echo "Row:6")
(get-value ((board 6 0) (board 6 1) (board 6 2) (board 6 3) (board 6 4) (board 6 5) (board 6 6) (board 6 7) (board 6 8)))
(echo "Row:7")
(get-value ((board 7 0) (board 7 1) (board 7 2) (board 7 3) (board 7 4) (board 7 5) (board 7 6) (board 7 7) (board 7 8)))
(echo "Row:8")
(get-value ((board 8 0) (board 8 1) (board 8 2) (board 8 3) (board 8 4) (board 8 5) (board 8 6) (board 8 7) (board 8 8)))

;(get-value ((board -1 -1)))
;(get-value ((board -1 -100)))
;(get-value ((board -1 -100000)))
;(get-value ((board -1 -100000000000)))

(exit)

