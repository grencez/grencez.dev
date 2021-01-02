
; Reduction from Wang tiles by transforming
; each tile with colors a, b, c, and d:
; ---------
; |   b   |
; | a   d |
; |   c   |
; ---------

; into 9 SE-identical tiles and their 9 flipped versions:
; -------------------------------------    -------------------------------------
; |     b_V   |     HH    |     $     |    |    a_H    |     VV    |     $     |
; | a_H       | c_d       | d_{HH}    |    | b_V       | cd        | c_{VV}    |
; |       c_d |    d_{HH} |       d_H |    |        cd |    c_{VV} |       c_V |
; -------------------------------------    -------------------------------------
; |     c_d   |   d_{HH}  |    d_H    |    |     cd    |   c_{VV}  |    c_V    |
; | VV        | c_{VV}    | #         |    | HH        | d_{HH}    | #         |
; |    c_{VV} |         # |        VV |    |    d_{HH} |         # |        HH |
; -------------------------------------    -------------------------------------
; |   c_{VV}  |     #     |    VV     |    |   d_{HH}  |     #     |    HH     |
; | $         | c_V       | HH        |    | $         | d_H       | VV        |
; |       c_V |        HH |         $ |    |       d_H |        VV |         $ |
; -------------------------------------    -------------------------------------

; The new tiles use multiple colors based on each old tile color.
; These are differentiated with subscripts.
; The new tile set introduces some constant colors as well: HH, VV, #, $.

; This file ensures that the new tiles will be arranged 3x3 blocks as shown
; above (either the block on the left or the mirrored version on the right).
; We do this by placing the new tiles arbitrarily on a 7x7 grid such that
; adjacent edge colors match.
; Then, we verify that the middle tile is part of one of the 3x3 blocks.

; Finally, we verify that all tiles would be mirrored or all would be
; non-mirrored if placed on an infinite plane.
; We do this by verifying that the middle tile of our 7x7 grid and its neighbors
; are either all mirrored or are all non-mirrored.

(set-option :produce-models true)

(declare-datatypes () ((Tile T00 T01 T02 T10 T11 T12 T20 T21 T22
                             M00 M01 M02 M10 M11 M12 M20 M21 M22)))

(declare-datatypes () ((Color ColorColor ColorH ColorV ColorHH ColorVV
                              ArrowHH ArrowVV CrossHatch Dollar)))

(declare-fun row_in_block (Tile) Int)
(declare-fun col_in_block (Tile) Int)

(declare-fun color_W  (Tile) Color)
(declare-fun color_N  (Tile) Color)
(declare-fun color_SE (Tile) Color)

(define-fun tile_form ((tile Tile) (mirror Tile)
                       (row Int) (col Int)
                       (W Color) (N Color) (SE Color)) Bool
  (and (= (row_in_block tile) row) (= (col_in_block mirror) row)
       (= (col_in_block tile) col) (= (row_in_block mirror) col)
       (= (color_W      tile)   W) (= (color_N      mirror)   W)
       (= (color_N      tile)   N) (= (color_W      mirror)   N)
       (= (color_SE     tile)  SE) (= (color_SE     mirror)  SE)))

(assert (tile_form T00 M00 0 0 ColorH     ColorV     ColorColor))
(assert (tile_form T01 M10 0 1 ColorColor ArrowHH    ColorHH))
(assert (tile_form T02 M20 0 2 ColorHH    Dollar     ColorH))
(assert (tile_form T10 M01 1 0 ArrowVV    ColorColor ColorVV))
(assert (tile_form T11 M11 1 1 ColorVV    ColorHH    CrossHatch))
(assert (tile_form T12 M21 1 2 CrossHatch ColorH     ArrowVV))
(assert (tile_form T20 M02 2 0 Dollar     ColorVV    ColorV))
(assert (tile_form T21 M12 2 1 ColorV     CrossHatch ArrowHH))
(assert (tile_form T22 M22 2 2 ArrowHH    ArrowVV    Dollar))

(declare-fun board (Int Int) Tile)

;; Ensure that east/west and north/south colors of adjacent tiles match.
(assert
  (forall ((row Int) (col Int))
    (=> (and (>= row 0) (< row 7) (>= col 0) (< col 6))
        (= (color_SE (board row col)) (color_W (board row (+ col 1)))))))
(assert
  (forall ((row Int) (col Int))
    (=> (and (>= row 0) (< row 6) (>= col 0) (< col 7))
        (= (color_SE (board row col)) (color_N (board (+ row 1) col))))))

(define-fun block_has ((tile Tile) (block_row Int) (block_col Int)) Bool
  (= (board (+ block_row (row_in_block tile))
            (+ block_col (col_in_block tile)))
     tile))

(define-fun mirrored ((tile Tile)) Bool
  (or (= tile M00) (= tile M01) (= tile M02)
      (= tile M10) (= tile M11) (= tile M12)
      (= tile M20) (= tile M21) (= tile M22)))

(define-fun valid_block ((r Int) (c Int)) Bool
  (or (and (block_has T00 r c) (block_has T01 r c) (block_has T02 r c)
           (block_has T10 r c) (block_has T11 r c) (block_has T12 r c)
           (block_has T20 r c) (block_has T21 r c) (block_has T22 r c))
      (and (block_has M00 r c) (block_has M01 r c) (block_has M02 r c)
           (block_has M10 r c) (block_has M11 r c) (block_has M12 r c)
           (block_has M20 r c) (block_has M21 r c) (block_has M22 r c))))

(push)
(echo "##############################################################################")
(echo "Checking if the middle tile can be part of a 3x3 block that does not match either of:")
(echo "-------------------------------------    -------------------------------------")
(echo "|     b_V   |     HH    |     $     |    |    a_H    |     VV    |     $     |")
(echo "| a_H       | c_d       | d_{HH}    |    | b_V       | cd        | c_{VV}    |")
(echo "|       c_d |    d_{HH} |       d_H |    |        cd |    c_{VV} |       c_V |")
(echo "-------------------------------------    -------------------------------------")
(echo "|     c_d   |   d_{HH}  |    d_H    |    |     cd    |   c_{VV}  |    c_V    |")
(echo "| VV        | c_{VV}    | #         |    | HH        | d_{HH}    | #         |")
(echo "|    c_{VV} |         # |        VV |    |    d_{HH} |         # |        HH |")
(echo "-------------------------------------    -------------------------------------")
(echo "|   c_{VV}  |     #     |    VV     |    |   d_{HH}  |     #     |    HH     |")
(echo "| $         | c_V       | HH        |    | $         | d_H       | VV        |")
(echo "|       c_V |        HH |         $ |    |       d_H |        VV |         $ |")
(echo "-------------------------------------    -------------------------------------")
(echo "(expect unsat)")
(assert (not (valid_block (- 3 (row_in_block (board 3 3)))
                          (- 3 (col_in_block (board 3 3))))))
;(assert (valid_block (- 3 (row_in_block (board 3 3)))
;                     (- 3 (col_in_block (board 3 3)))))
(check-sat)
(pop)

(push)
(echo "##############################################################################")
(echo "Checking if the middle tile and an adjacent tile can be from")
(echo "different mirrored and non-mirrored sets.")
(echo "(expect unsat)")
(assert
  (not (and (= (mirrored (board 3 3)) (mirrored (board 3 2)))
            (= (mirrored (board 3 3)) (mirrored (board 2 3)))
            (= (mirrored (board 3 3)) (mirrored (board 4 3)))
            (= (mirrored (board 3 3)) (mirrored (board 3 4))))))
(check-sat)
(pop)

;;; If one of the models 
;(echo "Row:0")
;(get-value ((board 0 0) (board 0 1) (board 0 2) (board 0 3) (board 0 4) (board 0 5) (board 0 6)))
;(echo "Row:1")
;(get-value ((board 1 0) (board 1 1) (board 1 2) (board 1 3) (board 1 4) (board 1 5) (board 1 6)))
;(echo "Row:2")
;(get-value ((board 2 0) (board 2 1) (board 2 2) (board 2 3) (board 2 4) (board 2 5) (board 2 6)))
;(echo "Row:3")
;(get-value ((board 3 0) (board 3 1) (board 3 2) (board 3 3) (board 3 4) (board 3 5) (board 3 6)))
;(echo "Row:4")
;(get-value ((board 4 0) (board 4 1) (board 4 2) (board 4 3) (board 4 4) (board 4 5) (board 4 6)))
;(echo "Row:5")
;(get-value ((board 5 0) (board 5 1) (board 5 2) (board 5 3) (board 5 4) (board 5 5) (board 5 6)))
;(echo "Row:6")
;(get-value ((board 6 0) (board 6 1) (board 6 2) (board 6 3) (board 6 4) (board 6 5) (board 6 6)))

(exit)

; vim: ft=lisp:lw+=define-fun,forall,exists:
