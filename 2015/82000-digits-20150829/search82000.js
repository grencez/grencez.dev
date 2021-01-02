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
  constructor(guess, base, cached_digit_depth) {
    guess = BigInt(guess);
    base = BigInt(base);
    this.base = base;

    this.digit_count = count_digits_in_base(guess, base);
    this.higher = base ** this.digit_count;

    this.cached_digit_depth = BigInt(cached_digit_depth);
    this.digit_value_cache = new Map();

    this.guess = null;  // Set this directly before calling check01().
    this.max_digit_depth = 0;
  }

  one_digit_higher() {
    this.digit_value_cache.set(this.digit_count, this.higher);
    // Can't cache everything!
    this.digit_value_cache.delete(this.digit_count - this.cached_digit_depth);
    console.assert(this.digit_value_cache.size <= this.cached_digit_depth,
      "Cache size should be bounded.");

    this.higher *= this.base;
    this.digit_count += 1n;
  }

  get_one_digit_lower(current_digit_index, current_digit_value) {
    let lower_digit_index = BigInt(current_digit_index) - 1n;
    let value = this.digit_value_cache.get(lower_digit_index);
    if (value) {
      return value;
    }
    value = current_digit_value / this.base;
    if (this.digit_count - 1n - lower_digit_index < this.cached_digit_depth) {
      this.digit_value_cache.set(lower_digit_index, value);
    }
    return value;
  }

  get_high_digit_value() {
    return this.get_one_digit_lower(this.digit_count, this.higher);
  }
}


function check01(search) {
  const base = search.base;
  while (search.higher <= search.guess) {
    // Maintain search.higher as the next higher digit's place value,
    // assuming the digit is 1.
    search.one_digit_higher();
  }

  let digit_depth = 0;
  let passed = true;
  let high = search.get_high_digit_value();
  let r1 = search.guess;
  while (high > 1) {
    digit_depth += 1;
    if (r1 >= high) {
      const r2 = r1 - high;
      if (r2 >= high) {
        passed = false;
        break;
      }
      r1 = r2;
    }
    high = search.get_one_digit_lower(
      search.digit_count - BigInt(digit_depth),
      high);
  }
  passed = passed && (r1 <= 1);
  search.max_digit_depth = Math.max(search.max_digit_depth, digit_depth);

  if (!passed) {
    search.guess = search.guess - r1 + high * base;
  }
  return passed;
}


function search01(bases, initial_guess, max_guess=null, cached_digit_depth=100) {
  let guess = BigInt(initial_guess);
  let search_states = [];
  for (const base of bases) {
    search_states.push(new SearchState(guess, base, cached_digit_depth));
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
      let max_digit_depths = [];
      for (let search of search_states) {
        max_digit_depths.push(search.max_digit_depth);
        search.max_digit_depth = 0;
      }
      console.log("Searched " + decimal_digit_count + " decimal digits." +
        " Checked +" + print_iteration_count + " iterations." +
        " Descended [" + max_digit_depths + "] digits max.");
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

// Find 82000.
let solution = search01([3,4,5], 2);
// Find 82005.
//let solution = search01([4,5], 82002);

// Search a little farther.
//let solution = search01([3,4,5], 82001, 10n**30000n, 35);
//let solution = search01([4,5], 82006, 10n**20000n, 133);

// Search a lot farther (no limit).
//let solution = search01([3,4,5], 82001, null, 155);
//let solution = search01([4,5], 82006, null, 155);

// Search a lot farther (no limit) from where I stopped:
//let solution = search01([3,4,5], 10n**11000000n, null, 155);
//let solution = search01([4,5], 10n**4600000n, null, 155);

if (solution != null) {
  console.log(solution);
} else {
  console.log("No solution found.");
}
