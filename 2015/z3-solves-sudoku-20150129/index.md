---
canonical_url: https://grencez.dev/2015/z3-solves-sudoku-20150129
date: 2015-01-29
description: How to find solutions to Sudoku puzzles with the Z3 SMT solver.
---

# Solving Sudoku with Z3

Date: 2015-01-29

Updated: 2020-10-25, when I wrote this article and retested everything.

File: [sudoku.smt2](sudoku.smt2)

## Running the Sudoku example {#run}

Jump to the [instructions below](#setup) if you need to install Z3.

[sudoku.smt2](sudoku.smt2) defines the rules of Sudoku that constrain the valid ways that a 9x9 grid can be filled with values ranging from 1 to 9.
The 9x9 grid is represented by a function `board` that maps 2 integers (row and column) to a value (the number at that cell).
Values are represented as enums V1 to V9 to inform the solver that each cell in the grid has a finite number of options.
It would have been nice to restrict the row and column indices as well.
While not ideal, we hint to the solver that the grid is 9x9 by only applying constraints on rows and columns that in the range 0..8 (the `valid_index` predicate).

The example Sudoku board is specified by `assert`ing values at certain cells, which are:

```
-------------------------
|       | 8   6 | 7     |
|       | 2 9   |   4   |
| 9     |     7 |     6 |
|-----------------------|
| 5     |     8 | 4     |
| 6     |       | 2 5   |
|     2 | 7 6   |       |
|-----------------------|
|       | 6     | 1 7   |
|       |   7   | 5   4 |
|   4   |   1   |   9   |
-------------------------
```

Try solving it with `z3`:

```shell
cd /tmp
wget https://grencez.dev/2015/z3-solves-sudoku-20150129/sudoku.smt2
z3 sudoku.smt2
```

The `get-value` calls should print out the following solution:

```
-------------------------
| 1 5 4 | 8 3 6 | 7 2 9 |
| 7 3 6 | 2 9 1 | 8 4 5 |
| 9 2 8 | 4 5 7 | 3 1 6 |
|-----------------------|
| 5 7 9 | 3 2 8 | 4 6 1 |
| 6 8 3 | 1 4 9 | 2 5 7 |
| 4 1 2 | 7 6 5 | 9 8 3 |
|-----------------------|
| 3 9 5 | 6 8 4 | 1 7 2 |
| 8 6 1 | 9 7 2 | 5 3 4 |
| 2 4 7 | 5 1 3 | 6 9 8 |
-------------------------
```

## Setting up Z3 {#setup}

### Installing from source

Prefer to install via a Linux package manager (e.g., `sudo apt-get install z3` on Debian or `sudo emerge -a sci-mathematics/z3` on Gentoo).
Alternatively, you can find pre-built versions of Z3 available for other platforms at https://github.com/z3prover/bin.
But if you would prefer to install from source in Linux as a normal user,  read on!
Otherwise, skip this section.

We will install `z3` using `stow`, so follow [these instructions](../../2016/stow-tutorial-20160505.md) to install it and configure your system accordingly.

After that, check https://github.com/Z3Prover/z3/releases/latest for the latest release of Z3.
At the time of writing this article, the latest tag is `z3-4.8.9`.
Use that to set a `$release_name` variable and download the source:

```shell
release_tag=z3-4.8.9
release_name=$release_tag  # The tag is suitable to use as a name.

mkdir -p ~/local/src
cd ~/local/src
git clone --depth 1 --branch $release_tag https://github.com/Z3Prover/z3.git $release_name
```

Then build and install:

```shell
mkdir -p ~/local/src/$release_name/build
cd ~/local/src/$release_name/build
cmake -DCMAKE_INSTALL_PREFIX="${HOME}/local/stow/${release_name}" ..
make -j6
make install
cd ~/local/stow
stow $release_name
```

### Editing with Vim

If you're using Vim, put this as the last line any file:
```
; vim: ft=lisp:lw+=define-fun,forall,exists:
```
Or do it properly by putting the following line in `~/.vim/filetype.vim`:
```
autocmd BufRead,BufNewFile *.smt2 set ft=lisp lisp lw+=define-fun,forall,exists
```

### Tutorials

Follow this interactive tutorial to learn more: http://rise4fun.com/Z3/tutorial/guide

