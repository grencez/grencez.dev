---
canonical_url: https://grencez.dev/2008/bf-possi-20080705
date: 2008-07-05
description: Counting the number of possible Brainfuck programs of a given length.
last_modified at: 2021-01-05
---

{%- include mathjax.html -%}

# Counting BF Programs of a Given Length

Date: 2008-07-05

Update: 2021-01-05 (formatting for the web)

## Problem

There is a language, which I'll affectionately call the [BF programming language](https://en.wikipedia.org/wiki/Brainfuck), that is written using only $8$ different keyboard characters.
Of the $8$ characters, $2$ of them are brackets and must come in pairs for the program to be valid.
That is, when a `[` appears, there must be a matching `]` somewhere to the right.
The brackets don't have to appear next to each other.

How many valid BF programs can be written using $n$ characters?

To avoid burying the lead, the answer is:

$$\sum_{j=0}^{\left\lfloor \frac{n}{2}\right\rfloor }\frac{n!6^{n-2j}}{(n-2j)!j!(j+1)!}$$

## Solution Process

This problem was given to me by Stefan Zwanenburg, and we spent a good week hacking up programs to generate solutions.
The explanation presented here is the process I went through to get the final solution.
Some neat things happened along the way, though it is by no means the best or most efficient way of tackling the problem.

Say $V(b,c)$ is a function that returns the total valid combinations of $b$ open brackets and $c$ closed brackets.

You can take the solution step by step, starting with no brackets at all, and adding pair of brackets with each consecutive step.
The count of possible BF programs at each step can be added together to get the final answer.

For each step, there are:

* $j$ open brackets and therefore $j$ closed brackets,
* $\binom{n}{n-2j}=\binom{n}{2j}$ ways the non-bracket characters can be arranged,
* $6^{n-2j}$ possible combinations of non-bracket characters in those spaces, and
* $V(j,j)$ ways the brackets can be arranged.

Since the amount of brackets cannot exceed the specified amount of characters $n$, the pairs of brackets $j$ cannot exceed $\frac{n}{2}$.
Since there can only be an integer amount of pairs $(j\in\mathbb{Z})$, we can use the floor function $\left\lfloor \frac{n}{2}\right\rfloor$.

Thus, the solution may be written as

$$\sum_{j=0}^{\left\lfloor \frac{n}{2}\right\rfloor }\left(\binom{n}{2j}6^{n-2j}V(j,j)\right)\label{eq:first-solution}\tag{1}$$

Which still leaves $V(j,j)$ to be dealt with.
When $j=0$, it must be true that $V(j,j)=1$ for the first term in the above summation to make sense.
Through trial, it can be found for $j=1,2,3$ that $V(j,j)$ yields $1,2,5$

Finding $V(4,4)=14$ begins to stress a stricter method.
It is beneficial to work through it a bit, I used my fingers; those of the right hand as open brackets and closed brackets from the right.
Meshing them together, the "bracket" combination is valid if and only if each finger of the right hand is somewhere above the matching finger on the left hand.
It helped to attack the problem vertically for some reason.

$V(5,5)=42$ is harder to count "by hand" since thumbs don't reach far enough to keep the layout straight.

Without further explanation, it is the case that

$$\begin{equation}V(b,c)=\begin{cases}
1 & \mbox{if }b=0\mbox{,}\\
\sum_{k=b}^{c} V(b-1,k) & \mbox{if }b>0\mbox{.}
\end{cases}\label{eq:first-v}\end{equation}\tag{2}$$


From there, we can work a few cases out.

$$\begin{eqnarray*}
V(2,2) & = & \sum_{k=2}^{2}V(1,k)\\
 & = & V(1,2)\\
 & = & \sum_{k=1}^{2}V(0,k)\\
 & = & V(0,1)+V(0,2)\\
 & = & 1+1\\
 & = & 2
\end{eqnarray*}$$


$$\begin{eqnarray*}
V(3,3) & = & \sum_{k=3}^{3} V(2,k)\\
 & = & V(2,3)\\
 & = & \sum_{k=2}^{3} V(1,k)\\
 & = & V(1,2)+V(1,3)\\
 & = & \sum_{k=1}^{2} V(0,k)+\sum_{k=1}^{3} V(0,k)\\
 & = & 2\sum_{k=1}^{2} V(0,k)+V(0,3)\\
 & = & 2V(0,1)+2V(0,2)+V(0,3)\\
 & = & 2+2+1\\
 & = & 5
\end{eqnarray*}$$


Now I'll progressively skip more steps to save room and lead into
the generalization.

$$\begin{eqnarray*}
V(4,4) & = & V(3,4)\\
 & = & \sum_{k=3}^{4} V(2,k)=V(2,3)+V(2,4)\\
 & = & \sum_{k=2}^{3} V(1,k)+\sum_{k=2}^{4} V(1,k)\\
 & = & 2\sum_{k=2}^{3} V(1,k)+V(1,4)\\
 & = & 2V(1,2)+2V(1,3)+V(1,4)\\
 & = & 2\sum_{k=1}^{2} V(0,k)+2\sum_{k=1}^{3} V(0,k)+\sum_{k=1}^{4} V(0,k)\\
 & = & 5\sum_{k=1}^{2} V(0,k)+3\sum_{k=3}^{3} V(0,k)+\sum_{k=4}^{4} V(0,k)\\
 & = & 5V(0,1)+5V(0,2)+3V(0,3)+V(0,4)\\
 & = & 5+5+3+1\\
 & = & 14
\end{eqnarray*}$$


$$\begin{eqnarray*}
V(5,5) & = & V(4,5)\\
 & = & \sum_{k=4}^{5} V(3,k)=V(3,4)+V(3,5)\\
 & = & 2\sum_{k=3}^{4} V(2,k)+V(2,5)\\
 & = & 2V(2,3)+2V(2,4)+V(2,5)\\
 & = & 5\sum_{k=2}^{3} V(1,k)+2V(1,4)+V(1,4)+V(1,5)\\
 & = & 5V(1,2)+5V(1,3)+3V(1,4)+V(1,5)\\
 & = & 14\sum_{k=1}^{2} V(0,k)+9\sum_{k=3}^{3} V(0,k)+4\sum_{k=4}^{4} V(0,k)+\sum_{k=5}^{5} V(0,5)\\
 & = & 14V(0,1)+14V(0,2)+9V(0,3)+4V(0,4)+V(0,5)\\
 & = & 14+14+9+4+1\\
 & = & 42
\end{eqnarray*}$$


Now without showing the summations at all,

$$\begin{eqnarray*}
V(6,6) & = & V(5,6)\\
 & = & V(4,5)+V(4,6)\\
 & = & 2V(3,4)+2V(3,5)+V(4,6)\\
 & = & 5V(2,3)+5V(2,4)+3V(2,5)+V(2,6)\\
 & = & 14V(1,2)+14V(1,3)+9V(1,4)+4V(1,5)+V(1,6)\\
 & = & 42V(0,1)+42V(0,2)+28V(0,3)+14V(0,4)+5V(0,5)+V(0,6)\\
 & = & 42+42+28+14+5+1\\
 & = & 132
\end{eqnarray*}$$


So following that pattern, reversing the order of coefficients, and starting with $j=2$ on the first row, the coefficients in the expansions for $V(j,j)$ are as follows:

$$\begin{array}{ccccccccc}
1 & 1\\
1 & 2 & 2\\
1 & 3 & 5 & 5\\
1 & 4 & 9 & 14 & 14\\
1 & 5 & 14 & 28 & 42 & 42\\
1 & 6 & 20 & 48 & 90 & 132 & 132\\
1 & 7 & 27 & 75 & 165 & 297 & 429 & 429\\
1 & 8 & 35 & 110 & 275 & 572 & 1001 & 1430 & 1430
\end{array}$$


Summing the coefficients of the expansion for $V(j,j)$ gives the highest coefficient of in the expansion of $V(j+1,j+1)$.

Computationally, this isn't so bad since you only need to keep one row of coefficients and work your way up with the values of $j$.

But there is a simpler pattern to jump from $V(j,j)$ to $V(j+1,j+1)$ which can be (and really should have been) found just by looking at consecutive results.

For $j=0,1,2,\ldots,7$, terms of $\dfrac{V(j+1,j+1)}{V(j,j)}$ look like:

$$\begin{array}{cccccccc}
\frac{1}{1}, & \frac{2}{1}, & \frac{5}{2}, & \frac{14}{5}, & \frac{42}{14}, & \frac{132}{42}, & \frac{429}{132}, & \frac{1430}{429}
\end{array}$$


Simplified, it's:

$$\begin{array}{cccccccc}
1, & 2, & \frac{5}{2}, & \frac{14}{5}, & 3, & \frac{22}{7}, & \frac{13}{4}, & \frac{10}{3}
\end{array}$$


The pattern is a little easier to see in terms 3, 4, 5, and 6...

$$\begin{array}{cccccccc}
\frac{2}{2}, & \frac{6}{3}, & \frac{10}{4}, & \frac{14}{5}, & \frac{18}{6}, & \frac{22}{7}, & \frac{26}{8}, & \frac{30}{9}
\end{array}$$


Very nice! So $\dfrac{V(j+1,j+1)}{V(j,j)}=\dfrac{4j+2}{j+2}=\dfrac{2(2j+1)}{j+2}$

Or equivalently, $V(j+1,j+1)=\dfrac{2(2j+1)}{j+2}V(j,j)$


Shifting each $j$ to $j-1$ we get a recursive definition: $V(j,j)=\dfrac{2(2j-1)}{j+1}V(j-1,j-1)$


Recalling that $V(0,c)=1$ from \ref{eq:first-v}, we have a place
to stop the recursion.

To get a feel for the pattern:

$$V(0,0)=1$$

$$V(1,1)=\frac{2(2\cdot1-1)}{1+1}\cdot V(0,0)=\frac{2(2\cdot1-1)}{1+1}\cdot 1$$

$$V(2,2)=\frac{2(2\cdot2-1)}{2+1}V(1,1)=\frac{2(2\cdot2-1)}{2+1}\cdot\frac{2(2\cdot1-1)}{1+1}$$

Generalized, it becomes

$$\begin{eqnarray*}
V(j,j) & = & \prod_{k=1}^{j}\frac{2(2k-1)}{k+1}\\
 & = & 2^{j}\prod_{k=1}^{j}\frac{2k-1}{k+1}\\
 & = & \frac{2^{j}}{(j+1)!}\prod_{k=1}^{j}(2k-1)
\end{eqnarray*}$$

Thus giving the new definition

$$\begin{equation}
V(j,j)=\frac{2^{j}}{(j+1)!}\prod_{k=1}^{j}(2k-1)
\label{eq:final-v}\tag{3}\end{equation}$$

Notice that ${\displaystyle \prod_{k=1}^{j}}(2k-1)$ is the product of the first $j$ positive odd numbers.

Now work from the full solution we have so far \ref{eq:first-solution}, and substitute in the new definition for $V(j,j)$ \ref{eq:final-v} to get:

$$\sum_{j=0}^{\left\lfloor \frac{n}{2}\right\rfloor}\left(\binom{n}{2j}6^{n-2j}V(j,j)\right)=\sum_{j=0}^{\left\lfloor \frac{n}{2}\right\rfloor }\left(\frac{n!6^{n-2j}}{(2j)!(n-2j)!}\cdot\frac{2^{j}}{(j+1)!} \prod_{k=1}^{j}(2k-1)\right)$$

Now make the simplification:

$$\begin{equation}
\frac{2^{j}}{(2j)!} \prod_{k=1}^{j} (2k-1)=\frac{1}{j!}
\label{eq:prod-simp}\tag{4}\end{equation}$$

And to get the **final answer**:

$$\sum_{j=0}^{\left\lfloor \frac{n}{2}\right\rfloor }\frac{n!6^{n-2j}}{(n-2j)!j!(j+1)!}$$

## Proof of Simplification

We must prove a lemma that the \ref{eq:prod-simp} simplification is valid.

**Lemma.** $\dfrac{2^{j}}{(2j)!}{\displaystyle \prod_{k=1}^{j}}(2k-1)=\dfrac{1}{j!}$, assuming that $j\in\mathbb{Z}^+$ and ${\displaystyle \prod_{k=1}^{0}}(2k-1)=1$.

**Proof.** First show the theorem holds for $j=0$.

Then do an inductive proof for $j>0$.

**Case.** Show that the statement is true for $j=0$.

$$\begin{eqnarray*}
\frac{2^{j}}{(2j)!} \prod_{k=1}^{j} (2k-1) & = & \frac{2^{0}}{(2\cdot0)!} \prod_{k=1}^{0} (2k-1)\\
 & = & \frac{1}{0!}\cdot1\\
 & = & \frac{1}{j!}
\end{eqnarray*}$$


**Inductive Basis.** Show that the statement holds
for $j=1$

$$\begin{eqnarray*}
\frac{2^{j}}{(2j)!} \prod_{k=1}^{j} (2k-1) & = & \frac{2^{1}}{(2\cdot1)!}\prod_{k=1}^{1}(2k-1)\\
 & = & \frac{2}{2!}(2\cdot1-1)\\
 & = & \frac{1}{1}\cdot1\\
 & = & \frac{1}{1!}\\
 & = & \frac{1}{j!}
\end{eqnarray*}$$


**Inductive Step.** Show that $\dfrac{2^{j+1}}{(2(j+1))!} \prod_{k=1}^{j+1} (2k-1)=\dfrac{1}{(j+1)!}$

$$\begin{eqnarray*}
\frac{2^{j+1}}{(2(j+1))!}\prod_{k=1}^{j+1}(2k-1) & = & \frac{2\cdot2^{j}}{(2j+2)!}(2(j+1)-1)\prod_{k=1}^{j}(2k-1)\\
 & = & \frac{2\cdot2^{j}(2j+2-1)}{(2j+2)(2j+1)(2j)!}\prod_{k=1}^{j}(2k-1)\\
 & = & \frac{2\cdot2^{j}(2j+1)}{2(j+1)(2j+1)(2j)!}\prod_{k=1}^{j}(2k-1)\\
 & = & \frac{2^{j}}{(j+1)(2j)!}\prod_{k=1}^{j}(2k-1)
\end{eqnarray*}$$

Since $\dfrac{2^{j}}{(2j)!} \prod_{k=1}^{j} (2k-1)=\dfrac{1}{j!}$ by the inductive hypothesis,

$$\begin{eqnarray*}
\frac{2^{j}}{(j+1)(2j)!}\prod_{k=1}^{j}(2k-1) & = & \frac{1}{(j+1)j!}\\
 & = & \frac{1}{(j+1)!}
\end{eqnarray*}$$


Therefore:

$$\frac{2^{j+1}}{(2(j+1))!}\prod_{k=1}^{j+1}(2k-1)=\frac{1}{(j+1)!}$$
