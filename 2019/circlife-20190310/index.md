---
canonical_url: https://grencez.dev/2019/circlife-20190310
date: 2019-03-10
description: A simple, restricted, yet still undecidable version of the Periodic Domino Problem.
last_modified at: 2021-01-10
---

{%- include mathjax.html -%}

# Monotonous Life on a Circle Planet

Date: 2019-03-10

Imagine unicellular alien lifeforms inhabiting the edge of a circle planet, where adjacent cells can spawn a new cell between them if their genomes are compatible.
A cell's genome is chosen from a finite set based on its parents' genomes.
Furthermore, to achieve diversity, a cell's genome must be incompatible with its parents and grandparents.
Cells can also die, which is necessary since cells can't pass by each other on the planet's 1-dimensional surface.
Given these rules and those for compatibility/spawning, does there exist some number of cells with genomes that can sustain life indefinitely?

**Theorem:** Is it possible to learn this answer? Not from a Turing machine. It's undecidable!

This behavior is summarized by a partial function $\xi$ that evaluates to $\xi(a,b)=c$ iff adjacent cells with genomes $a$ and $b$ can spawn a cell with genome $c$.
$\xi$ has the following properties:

1. $\forall a,b: \xi(a,b)=\xi(b,a)$ (commutativity)
2. $\vert \{\xi(a,b): \xi(a,b) \ne \bot \}\vert \in \mathbb{N}$ (finite set of genomes)
3. $\forall a,b: \xi(a,(a,b)) = \bot$ (incompatible with parents)
4. $\forall a,b,c: \xi(a,\xi(\xi(a,b),c)) = \bot$ (incompatible with grandparents)
5. $\xi$ can be nondeterministic, even though we are writing it as a function here

Life on such a planet becomes rather monotonous because a planet's life can only visit and revisit a finite set of configurations.
To see this, let the *population potential* be defined as the number of compatible pairs.
When a spawn occurs, the planet's population increases by 1, but its potential population decreases by 1 since the new cell is incompatible with its parents.
In this way, the sum of the planet's actual and potential populations is non-increasing.
Since the number of genomes is finite as well (no evolution), only a finite set of configurations can be reached.

In [monotonous.smt2](monotonous.smt2), we prove that when life is sustained, the sum of a planet's actual and potential populations must remain constant, therefore each cell that dies must be incompatible with its neighbors, and those neighbors must be compatible with each other.

In [unidirectional.smt2](unidirectional.smt2), we prove that sustained life can be modeled as each newly-spawned cell replacing its parent.
Furthermore, as the filename implies, we prove that the spawns eventually propagate in one direction.
Given these two facts, the problem of determining whether a given $\xi$ can yield sustainable life (i.e., the CircLife problem) is equivalent to [finding a livelock](https://doi.org/10.1007/978-3-319-03089-0_12) in an arbitrarily sized unidirectional ring of finite state machines that each have the same transition function $\xi$.

In [reduction.smt2](reduction.smt2), we give a reduction from the Periodic Domino Problem (for NW-deterministic Wang tiles) to our CircLife problem.
This is just the key step of the reduction, whereas the rest of the proof is identical to the [undecidability proof](https://doi.org/10.1007/978-3-319-03089-0_12) of livelock detection for unidirectional rings of finite state machines.
