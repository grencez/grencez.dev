---
canonical_url: https://grencez.dev/2015/82000-digits-20150829
date: 2015-08-29
description: A clever algorithm to search for integers that can be written with ones and zeroes in several bases.
last_modified_at: 2020-12-19
---

# Digits of 82000

Date: 2015-08-29 (searched for a number of [https://oeis.org/A146025](https://oeis.org/A146025) after 82000 up to 11 million decimal digits)

Updated: 2020-11-29 (wrote this article), 2020-12-19 (added caching for better time complexity)

Download code: [search82000.js](search82000.js), [search82000.c](search82000.c)

## Problem

You can write the number 82000 in different bases, but a few after base 2 still look like binary:

* Base 2: 10100000001010000
* Base 3: 11011111001
* Base 4: 110001100
* Base 5: 10111000
* Base 6: 1431344
* Base 10: 82000

Wow that's a lot of ones and zeroes.
You might ask how rare that is.
The sequence at [https://oeis.org/A146025](https://oeis.org/A146025) lists the currently-known integers that can be written using digits 0 and 1 in all bases 2, 3, 4, and 5.
That list currently has 3 numbers (0, 1, and 82000), so you could say that 82000 is quite rare!
Is there another number in the sequence?

Perhaps a better question to ask is whether [https://oeis.org/A263684](https://oeis.org/A263684), the same sequence for bases 4 and 5, contains any numbers larger than 82005.
But I'll leave that one for another day.

## Search

Nonexistence proofs can be pretty challenging, so maybe it's worth letting a computer search for one!
[This reddit.com/r/math comment](https://www.reddit.com/r/math/comments/36jq0k/a_curious_property_of_82000/crf0pkn) from [threenplusone](https://www.reddit.com/user/threenplusone/) outlines a clever way to search:

1. Start with a guess of 82001.
2. Check whether the guess is written with all 0 and 1 digits in base 3.
   * If not, then increase the guess to the next-largest number that can be.
3. Repeat step 2 using base 4.
4. Repeat step 2 using base 5.
5. Did we have to change our guess in the last 3 steps?
   * If so, then go back to step 2.
   * If not, then we have an answer!

The clever part is skipping to the next-largest number written with all 0 and 1 digits when the check fails.
It seems to let us search more digits at a near-constant rate with respect to number of checks performed.
My code prints how many iterations (of steps 2, 3, and 4 combined) it takes to grow the guess by each successive 100 decimal digits.
The following commands generate that output and graph it with a linear regression:

```shell
node search82000.js | tee iterations.log
# Let it run for a while... then make a graph.
cat iterations.log | tail -n +2 | sed -E -e 's/^.*\+([0-9]*) .*$/\1/' > iterations.dat
gnuplot -e 'set terminal png; f(x) = a*x + b; fit f(x) "iterations.dat" via a,b; plot f(x), "iterations.dat" with points' > iterations.png
```

After searching up to 500k decimal digits, the linear regression plot is a horizontal line indicating an average of about 430 iterations per 100 new digits.
If truly constant, then this would mean the search can reach any guess *N* with *n* bits (or digits) in O(n) checks.
Furthermore, each `{0,1}-digits` check involves O(n) divisions by a constant base at worst, which makes each check O(n&sup2;lg(n)), and lets us reach any guess *N* in O(n&sup3;lg(n)) time.

The seemingly constant bound on iterations is a result of another observation: When excluding base 3, I have not yet encountered a {0,1}-digit base 4 number has more than 131 leading {0,1} digits in base 5.
Likewise, I have not encountered a {0,1}-digit base 5 number has more than 155 leading {0,1} digits in base 4.
Therefore if we only consider bases 4 and 5, the checks may be O(n lg(n)), which is further reduced to O(n) if we replace division with cache lookups.
This means our {0,1}-digit search in bases 4 and 5 may reach any guess *N* with *n* bits in O(n&sup2;) time (aka O(lg(N)&sup2;)).
Even if there likely isn't a constant bound on the leading {0,1} digits, especially when base 3 is included, this quadratic complexity is basically what you can expect.

```javascript
function check01_simple(guess, base) {
  // Both inputs have the BigInt type.

  // Assuming that the high digit is 1, calculate its place value.
  // The actual code calculates this from the previous high digit value
  // since we already keep it and older ones in a cache.
  let high = base ** (count_digits_in_base(guess, base) - 1);

  let r1 = guess;
  let passed = true;
  while (high > 1) {
    if (r1 >= high) {
      const r2 = r1 - high;
      if (r2 >= high) {
        passed = false;
        break;
      }
      r1 = r2;
    }
    // Integer division. Actually a cache lookup.
    high /= base;
  }
  passed = passed && (r1 <= 1);

  if (!passed) {
    guess = guess - r1 + high * base;
  }
  return [guess, passed];
}
```
