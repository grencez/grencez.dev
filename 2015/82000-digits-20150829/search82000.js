"use strict";

class SearchState {
  constructor(base) {
    this.base = BigInt(base);
    this.high = 1n;
    this.higher = BigInt(base);
    this.guess = null;  // Set this directly.
  }
}


function check01(search) {
  const base = search.base;
  while (search.higher <= search.guess) {
    // Maintain search.high as the high digit's place value,
    // assuming that the high digit is 1 (even if it's not really).
    search.high = search.higher;
    search.higher *= search.base;
  }

  let passed = true;
  let high = search.high;
  let r1 = search.guess;
  while (high > 1) {
    if (r1 >= high) {
      const r2 = r1 - high;
      if (r2 >= high) {
        passed = false;
        break;
      }
      r1 = r2;
    }
    high /= base;  // Integer division.
  }
  passed = passed && (r1 <= 1);

  if (!passed) {
    search.guess = search.guess - r1 + high * base;
  }
  return passed;
}


function search01(min_base, max_base, initial_guess, max_guess) {
  let search_states = [];
  for (let base = max_base; base >= min_base; --base) {
    search_states.push(new SearchState(base));
  }

  let decimal_digit_count = 0;
  let decimal_place = 1n;

  let guess = initial_guess;
  let passing = false;
  while (!passing) {
    passing = true;
    while (decimal_place <= guess) {
      decimal_place *= 10n;
      decimal_digit_count += 1;
      if (decimal_digit_count % 100 == 0) {
        console.log("Searched " + decimal_digit_count + " decimal digits.");
      }
    }

    for (let search of search_states) {
      search.guess = guess;
      if (!check01(search)) {
        passing = false;
      }
      guess = search.guess;
    }
    if (max_guess != null && guess > max_guess) {
      return null;
    }
  }
  return guess;
}

let solution = search01(3, 5, 2n, null);
//let solution = search01(3, 5, 82001n, null);

if (solution != null) {
  console.log(solution);
} else {
  console.log("No solution found.");
}
