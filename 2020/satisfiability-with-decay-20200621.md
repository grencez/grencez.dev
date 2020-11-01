---
canonical_url: https://grencez.dev/2020/satisfiability-with-decay-20200621.md
date: 2020-06-21
last_modified_at: 2020-10-31
description: 3-satisfiability is still NP-complete if the truth of each variable can nondeterministically decay to false during evaluation of subsequent clauses.
---

{%- include mathjax.html -%}

# Satisfiability with Decay

Date: 2020-06-21 ([https://cs.stackexchange.com/a/127485/34520](https://cs.stackexchange.com/a/127485/34520))\
Update: 2020-10-28 (wrote this article)

## Motivation: Leapfrog Automata

[This cs.stackexchange question](https://cs.stackexchange.com/q/127268) from [user326210](https://cs.stackexchange.com/users/86017/user326210) asks whether the acceptance problem for "leapfrog automata" is NP-complete.
Recall: The acceptance problem asks, given an automaton $M$ and string $w$, "Does $M$ accept $w$?".

**Metaphor.**
Imagine a frog on a lily pad, determined to eat a gourmet, multi-course meal of flies.
The meal is planned as a sequence of different types of flies.
Flies are on nearby lily pads, which the frog can jump between, but it can only catch one before the rest fly away!
Luckily for the frog, the uneaten flies will soon come back to a lily pad once it jumps to a different one.
The frog needs proper nutrition to jump between so many lily pads, so it must catch a fly after each jump in order to have enough energy for its next jump.
The problem is: Given a multi-course meal plan and a specific assortment of flies on lily pads, can the frog eat the entire meal?

It's a cute metaphor, but let's rephrase it as an automaton for the rest of this article.
In short: (lily pad -> register), (frog -> active register), (flies -> symbols), (meal plan -> input string).

**Defining leapfrog automata.**
A leapfrog automaton has a set of registers, each with a collection of symbols.
It marks exactly one register as *active* at any time beginning with a unique "start" register.
Its input string is accepted when all of its inputs symbols are consumed in order of appearance.
To consume a symbol $\alpha$:

1. Activate a *different* register that has $\alpha$ in its collection.
   * Deactivate the old register.
2. *Remove* $\alpha$ from the new active register's collection.

Note the nondeterministic choice.
If there is no valid sequence of active registers that allows each input symbol to be consumed, then the input is rejected.

**NP-completeness proof idea.**
So, is the acceptance problem for leapfrog automata NP-complete?
For a reduction from **3-SAT**, we could create registers $2i$ and $2i+1$ for each clause $C_i$ of the **3-SAT** instance $\phi$.
For each variable in $\phi$, we use the input string to guide execution:

1. Nondeterministically activate register $0$ or $1$ to represent the variable's truthiness ($0$ represents false; $1$ represents true).
   * The register index (ideally) toggles between even and odd every step in order to keep a consistent truthiness.
2. Jump through increasing indices of register pairs.
3. When registers $2i$ and $2i+1$ represent a clause $C_i$ that the variable is in, remove a special clause symbol $c_i$.
   * There are only $2$ copies of $c_i$ that variable assignments *not satisfying* $C_i$ can remove.
     In this way, at least $1$ of the $3$ variables must have an assignment that satisfies $C_i$, otherwise the input string will be rejected.

This is the actual proof sketch, but I couldn't manage to guarantee that variables stay true.
