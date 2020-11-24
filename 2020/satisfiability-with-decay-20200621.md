---
canonical_url: https://grencez.dev/2020/satisfiability-with-decay-20200621
date: 2020-06-21
last_modified_at: 2020-11-23
description: 3-satisfiability is still NP-complete if the truth of each variable can nondeterministically decay to false during evaluation of subsequent clauses.
---

{%- include mathjax.html -%}

# Boolean Satisfiability with Decay

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
In short: (lily pad $\to$ register), (frog $\to$ active register), (flies $\to$ symbols), (meal plan $\to$ input string).

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
3. For each clause $C_i$ that the variable is in, remove a special clause symbol $c_i$ when jumping past registers $2i$ and $2i+1$.
   * There are only $2$ copies of $c_i$ at register $2i$ and $3$ copies at register $2i+1$.
     In this way, at least $1$ of the $3$ variables must have an assignment that satisfies $C_i$, otherwise the input string will be rejected.

This is the actual proof sketch, but I couldn't manage to guarantee that an initial odd register choice would remain odd.
That is, I couldn't guarantee that variables stayed true while evaluating the 3CNF formula.
I could however ensure that the registers (resp. variables) stay odd (resp. false).
You'd think that a broken mapping like this, where the true variables could nondeterministally decay to false, would completely invalidate the NP-completeness proof.
It turns out that a restricted version of **3-SAT** is indifferent to whether decay can occur.

## The Repeated 3-SAT Problem {#repeat}

Let **3-SAT-REPEAT** be a version of **3-SAT** whose input is a 3CNF formula ANDed with itself at least as many times as it has variables (i.e., the 3CNF $\phi$ with $n$ variables is repeated at least $n+1$ times).

**3-SAT-REPEAT** is NP-complete by a polynomial-time mapping reduction from **3-SAT**.
In this mapping, let the instance of **3-SAT** be a 3CNF formula $\phi$.
The corresponding instance of **3-SAT-REPEAT** is $\phi'=\phi\land\dots\land\phi$, where $\phi$ is repeated $n+1$ times.
$\phi'$ can be constructed in a number of steps that is polynomial (quadratic) with respect to the size of $\phi$, therefore **3-SAT-REPEAT** is in NP.
Furthermore, $\phi'$ is satisfiable if and only if $\phi$ is satisfiable, therefore **3-SAT-REPEAT** is NP-hard.

Notice that we only considered 3CNF formulas.
A mapping reduction from **A** to **B** means that $\forall w: w\in \textbf{A} \iff f(w) \in \textbf{B}$.
But from what *universe* is the problem instance $w$?
It is often an implicit (though completely sound) assumption that each problem instance $w$ is a valid input (aka in the problem domain) of **A**.
Therefore, a reduction from **3-SAT-REPEAT** will only consider a 3CNF formula ANDed with itself at least $n+1$ times.

### The Decaying 3-SAT Problem Is NP-Complete {#problem}

Let **DECAY-3SAT** be the problem of satisfying a 3CNF formula where variables can change their values to false (aka *decay*) during evaluation of subsequent clauses (but not back to true).

**DECAY-3SAT** is NP-complete by a trivial reduction from **3-SAT-REPEAT**.
Consider satisfiable instance of $\phi'=\phi\land\dots\land\phi$ of **3-SAT-REPEAT** when decay can occur.
$\phi$ appears $n+1$ times in $\phi'$, and $\phi'$ only has $n$ variables, therefore some $\phi$ must be evaluated without decay.
This proves that decay cannot make $\phi'$ satisfiable.
Furthermore, the nondeterminism of decay cannot make $\phi'$ unsatisfiable.
Thus, any instance $\phi'$ of **3-SAT-REPEAT** is satisfiable if and only if it satisfiable with decay, proving that **DECAY-3SAT** is NP-complete.

### Similar Decay Problems

My original proof reduced **DECAY-3SAT** to leapfrog automaton acceptance, but I think it would have been better to reduce from **3-SAT-REPEAT**.
That way, the proof would be valid even if the leapfrog automaton construction didn't have as much freedom to decay as **DECAY-3SAT**.
It would cover the following cases:

* Not all variables can decay.
* Decay to an unspecified truthiness.
  * It really doesn't matter whether a variable can change to true or false during the evaluation of $\phi'$. What matters is that it can only change once.
* Multiple decay steps.
  * As long as the number of decay steps is polynomially bounded by the size of $\phi$, we can make any instance $\phi'$ of **3-SAT-REPEAT** have one more copy of $\phi$ than that bound without violating leaving the class of NP problems.

## Leapfrog Automata Acceptance Is NP-Complete {#leapfrog-sat}

The full proof lives at [https://cs.stackexchange.com/a/127485/34520](https://cs.stackexchange.com/a/127485/34520), with an excellent illustrative [reply by user326210](https://cs.stackexchange.com/a/128208/34520).
However, I'm sure you're wondering how to reduce **3-SAT-REPEAT** instances to leapfrog automaton acceptance.

For each clause $C_i$ in the **3-SAT-REPEAT** instance $\phi'$:

* Create symbols $c_i$, $\lambda_i$, and $\delta_i$.
* Put $2$ copies of $c_i$ at register $2i$.
  * This represents the maximum number of literals that can evaluate to false in the clause, which is $2$ because at least $1$ of the $3$ literals must be true.
* Put copies of $c_i$ at register $2i+1$.
  * $3$ is enough. It represents the number of literals that can evaluate to true.
* Put copies of $\lambda_i$ at registers $2i$ and $2i+1$.
  * $n+3$ is enough for each.
  * These are used to toggle between odd and even regesters without leaving the clause.
* Put copies of $\delta_i$ at registers $2i$ and $2i+3$.
  * $n$ is enough for each.
