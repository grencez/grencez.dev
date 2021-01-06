---
canonical_url: https://grencez.dev/2008/bf-possi-20080602
date: 2008-06-02
description: Coefficients of a polynomial after exponentiation.
last_modified at: 2021-01-05
---

{%- include mathjax.html -%}

# Coefficients of a Polynomial after Exponentiation

Date: 2008-06-02

Update: 2021-01-05 (format for the web)

## Power of Sum of Variables

Suppose we have $n$ numeric variables ($v_1,\dots,v_n$) and want to raise their sum to a certain exponent $r$.
We can multiply the exponent away, expanding our "power of sum of variables" to be a summation.

$$\left({\displaystyle \sum_{i=1}^{n}}v_{i}\right)^{r}=(v_{1}+v_{2}+\cdots+v_{n})^{r}={\displaystyle \sum_{k=1}^{A}\left(c_{k}{\displaystyle \prod_{i=1}^{n}}v_{i}^{r_{k,i}}\right)}$$

Each term in the expansion has a different combination of multiples of the variables $v_1,\dots,v_n$ such that those multiples add up to $n$.

$$\forall k: {\displaystyle \sum_{i=1}^{n}}r_{k,i}=r$$

Therefore $A$, the number of terms, is equal to the number of ways to make $r$ unordered copies of $n$ distinct elements.
This choice without order that allows repeats can be written with the [multiset coefficient](https://en.wikipedia.org/wiki/Multiset#Counting_multisets) as "$n$ multichoose $r$".
It can also be written as a binomial coefficient or directly with factorials.

$$A={n+r-1 \choose r}=\dfrac{(n+r-1)!}{r!(n-1)!}$$

As for the coefficients, we know that their sum is equal to $n^r$ (obvious when you consider the case of $(1+\cdots+1)^r$).

$$\sum_{k=1}^{A} c_{k}=n^{r}$$

The coefficient of any given term is $n!$ divided by the product of the factorials of the variables' exponents in that term.

$$c_{k}=\dfrac{n!}{{\displaystyle \prod_{i=1}^{n} r_{k,i}!}}$$

If there are just two variables, the coefficients make up the $r$th row of Pascal's Triangle (if the top is the $0$th row).
So, when there are two variables, the binomial coefficient can be used: $c_{k}={n \choose r_{k,1}}$.
