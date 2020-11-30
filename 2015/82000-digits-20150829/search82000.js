"use strict";


/**
 * Count digits of a number written in a certain base.
 *
 * Like mpz_sizeinbase() but slower and exact.
 */
function count_digits_in_base(x, base) {
  base = BigInt(base);
  x = BigInt(x);
  let place_values = []
  let high = base;
  while (high <= x) {
    place_values.push(high);
    high *= high;
  }
  place_values.reverse();
  high = 1n;
  let count = 0n;
  for (const place_value of place_values) {
    count = (count << 1n);
    const higher = high * place_value;
    if (higher <= x) {
      high = higher;
      count |= 1n;
    }
  }
  return count + 1n;
}


class SearchState {
  constructor(guess, base) {
    guess = BigInt(guess);
    base = BigInt(base);
    this.base = base;
    this.high = base ** (count_digits_in_base(guess, base) - 1n);
    this.higher = this.high * base;
    this.guess = null;  // Set this directly before calling check01().
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


function search01(bases, initial_guess, max_guess) {
  let guess = BigInt(initial_guess);
  let search_states = [];
  for (const base of bases) {
    search_states.push(new SearchState(guess, base));
  }

  const print_digits_difference = 100n;
  let decimal_digit_count = count_digits_in_base(guess, 10);
  decimal_digit_count -= decimal_digit_count % print_digits_difference;
  let print_value_threshold = 10n**BigInt(decimal_digit_count);


  let passing = false;
  let print_iteration_count = 0;
  while (!passing && (max_guess == null || guess <= max_guess)) {
    // Condition to display progress.
    while (guess >= print_value_threshold) {
      console.log("Searched " + decimal_digit_count + " decimal digits." +
        " (+" + print_iteration_count + " iterations)");
      print_value_threshold *= 10n ** BigInt(print_digits_difference);
      decimal_digit_count += print_digits_difference;
      print_iteration_count = 0;
    }
    print_iteration_count += 1;

    // Run check for all bases.
    passing = true;
    for (let search of search_states) {
      search.guess = guess;
      if (!check01(search)) {
        passing = false;
      }
      guess = search.guess;
    }
  }
  if (!passing) {
    return null;
  }
  return guess;
}

let solution = search01([3,4,5], 2, null);
//let solution = search01([3,4,5], 82001, null);
//let solution = search01([4,5], 82002, null);
//let solution = search01([4,5], 82006, null);


if (solution != null) {
  console.log(solution);
} else {
  console.log("No solution found.");
}
