---
canonical_url: https://grencez.dev/2015/spin-checks-agreement-20150407
date: 2015-04-07
last_modified_at: 2020-10-27
description: Introductory exercises using the Spin model checker to verify, or rather find deadlocks and livelocks in, a simple agreement protocol.
---

# Finding your first deadlock and livelock with the Spin model checker

Date: 2015-04-07

Updated: 2020-10-27, when I wrote this article and retested everything.

## Exercises in agreement {#exercises}

Jump to the [setup instructions below](#setup) if you haven't installed `spin` or my helper scripts (`spinsafe`, `spinlive`, `spinltl`, and `spinplay`).

Download [agreepair.pml](agreepair.pml) (or [view it on GitHub](https://github.com/grencez/grencez.dev/blob/trunk/2015/spin-checks-agreement-20150407/agreepair.pml)).
This Promela code models a pair of processes that *should* eventually agree on an `x` value.
It doesn't quite work though.
Using Spin, perhaps you can fix it!

### Exercise 1: Verify the program's safety properties

**Exercise 1.a.** What is the deadlock (**invalid end state**) that you find?

* GUI: Select **safety** and run the verification. Ensure that the verification searched for **invalid end states**.
* CLI: Run `spinsafe agreepair.pml`.

To view the deadlock in `ispin`, navigate to the **Simulate/Replay** tab, ensure **Guided, with trail** is selected and filled in, and click **Run**.
In **jspin**, just click **Guided**. On the command line, run `spinplay agreepair.pml`.

**Exercise 1.b.** How can the deadlock be fixed?\
Make the fix and verify that no deadlocks exist.

### Exercise 2: Verify the program's LTL properties

**Exercise 2.a.** Verify the **LTL claim** named `close_enough`.\
Instructions: Uncomment the claim by changing `#if 0` to `#if 1` near the end of the file.

* GUI: Select **acceptance cycles** and run the verification. Ensure that the verification uses the **never clause**.
* CLI: Run `spinltl agreepair.pml`.

This should succeed if the deadlock was fixed in the previous exercise.

**Exercise 2.b.** Verify the **LTL claim** named `exactly_equal`.\
Instructions: Same as before, but change `#if 1` back to `#if 0`, and change `#elif 0` to `#elif 1`.

This should fail, but we'll fix it in the next exercise.

### Exercise 3: Verify the program's other liveness properties

**Exercise 3.a.** What is the livelock (**non-progress cycle**) that you find?

* GUI: Select **non-progress cycles** and run the verification.
* CLI: Run `spinlive agreepair.pml`.

**Exercise 3.b.** How can the livelock be fixed without adding an `atomic` block?
*Remove* the livelock and verify that no other livelocks exist.


## Setting up Spin {#setup}

We will use `stow` as a maintainable way of installing files as a normal user in `~/local/bin`.
Follow [these instructions](../2016/stow-tutorial-20160505.md) to install it and configure your system accordingly.

### Install helper scripts {#install-spinsafe}

I wrote some scripts for checking safety properties (`spinsafe`), liveness properties (`spinlive`), LTL properties (`spinltl`), and replaying a trace (`spinplay`).
They handle the `spin` invocation, compile the verifier, run the verifier, and remove temporary files ([review it on GitHub](https://github.com/grencez/grencez.dev/blob/trunk/2015/spin-checks-agreement-20150407/spinsafe)).
The scripts also try to give helpful context and advice to avoid common pitfalls.

To install, run the following commands:

```shell
release_name=spin-checks-agreement-20150407
mkdir -p ~/local/stow/$release_name/bin
cd ~/local/stow/$release_name/bin
curl "https://grencez.dev/2015/$release_name/{spinsafe,spinlive,spinltl,spinplay}" -o "#1"
chmod 0755 spinsafe spinlive spinltl spinplay
cd ~/local/stow
stow $release_name
```

For completeness, the individual files can be: [spinsafe](spinsafe), [spinlive](spinlive), [spinltl](spinltl), [spinplay](spinplay)

### Install Spin {#install-spin}

Ideally you can obtain `spin` (which comes with `ispin`) through a Linux package manager:

* Debian/Ubuntu: `sudo apt-get install spin`
* Gentoo: `sudo emerge -a sci-mathematics/spin`

Otherwise, run the following to install in your `~/local/` directory:

```shell
release_name=spin-git
mkdir -p ~/local/src
cd ~/local/src
git clone https://github.com/nimble-code/Spin.git $release_name
cd $release_name
make -C Src
mkdir -p ~/local/stow/$release_name/bin
install 0755 Src/spin ~/local/stow/$release_name/bin/spin
install 0755 optional_gui/ispin.tcl ~/local/stow/$release_name/bin/ispin
cd ~/local/stow
stow $release_name
```

### Install Vim settings

If you use Vim, the following will set up indentation and syntax for Promela (the language of Spin models).
```shell
mkdir -p ~/.vim/indent ~/.vim/syntax
curl https://https://raw.githubusercontent.com/grencez/config/trunk/home/grencez/.vim/indent/promela.vim -o ~/.vim/indent/promela.vim
curl https://https://raw.githubusercontent.com/grencez/config/trunk/home/grencez/.vim/syntax/promela.vim -o ~/.vim/syntax/promela.vim
echo 'autocmd BufNewFile,BufRead *.pml set ft=promela sw=2 ts=2' >> ~/.vim/filetype.vim
```

If you don't have a `~/.vimrc` already, this will make it:
```shell
cd ~/
echo 'set nocompatible' >> .vimrc
echo 'filetype on' >> .vimrc
echo 'filetype plugin indent on' >> .vimrc
echo 'syntax enable' >> .vimrc
```

If you have no idea what's going on with this editor:
```shell
vimtutor
```
