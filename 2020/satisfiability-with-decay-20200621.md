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

## Motivation

[This cs.stackexchange question](https://cs.stackexchange.com/q/127268) from [user326210](https://cs.stackexchange.com/users/86017/user326210) asks whether the acceptance problem for "leapfrog automata" is NP-complete.
Recall: The acceptance problem asks, given an automaton M and string w, "Does M accept w?".

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

So, is the acceptance problem for leapfrog automata NP-complete?
The reduction from **3-SAT** isn't the easiest, but this part is important:

* For each clause $C_i$, make a symbol $c_i$ and put $2$ copies at register $2i$ and put $3$ copies at register $2i+1$.

