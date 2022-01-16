"use strict";

const guess_increment = 5592405n;
console.assert(guess_increment == BigInt(3*5*7*13*17*241));

/**
 * There are 48 different guess seeds.
 **/
function first_guess(seed_index) {
  console.assert(0 <= seed_index);
  console.assert(seed_index < 48);

  /* By analogy, we have 6 clocks that tick
   * once every 24, 2, 4, 8, 12, and 3 seconds respectively,
   * and we want to offset them so at least 1 of them ticks every second.
   * The first way is to use offsets       0,  1,  2,  4,  8, 16 respectively.
   * Doing so puts their next ticks at:   24,  3,  6, 12, 20, 19.
   * Clocks cycle every 24 seconds. Next: ..,  5, 10, 20, .., 22.
   * The ".." signifies passing 24. Next: ..,  7, 14, .., .., ...
   *                                Next: ..,  9, 18, .., .., ...
   *                                Next: .., 11, 22, .., .., ...
   *                                Next: .., 13, .., .., .., ...
   *                                (5 more rows to fill out 15,17,19,21)
   *
   * The trick is to offset the 24-second clock from the 12-second clock
   * by either 8 or 16 seconds. That's 24 options for the 24-second clock
   * each having 2 options for the 12-second clock, making 48 options in total.
   *
   * These are the "clock tick" offsets:
   */
  const covered_bit = [
    seed_index >> 1,
    ((seed_index >> 1) + 1) % 2,
    ((seed_index >> 1) + 2) % 4,
    ((seed_index >> 1) + 4) % 8,
    ((seed_index >> 1) + 8*(1 + (seed_index & 1))) % 12,
    ((seed_index >> 1) + 8*(2 - (seed_index & 1))) % 3,
  ];

  /* Instead of considering a clock at every second `t`,
   * we're actually trying to find a number that, when summed with any 2**t,
   * becomes divisible by one of the following moduli.
   */
  const moduli = [ 241, 3, 5, 17, 13, 7 ];
  let residues = new Array(moduli.length);
  for (let i = 0; i < moduli.length; ++i) {
    residues[i] = moduli[i] - ((1 << covered_bit[i]) % moduli[i]);
  }

  /* Didn't want to use BigInt.*/
  const M = 5592405;
  console.assert(BigInt(M) == guess_increment);

  for (let guess = 0; guess < M; ++guess) {
    let good = true;
    for (let i = 0; i < moduli.length; ++i) {
      if (guess % moduli[i] != residues[i]) {
        good = false;
        break;
      }
    }
    if (good) {
      return guess;
    }
  }
  console.assert(false, "unreachable!");
  return 0;
}

/* Find all 48 initial guesses.*/
function first_guesses() {
  let guesses = new Array(48);
  for (let i = 0; i < guesses.length; ++i) {
    guesses[i] = BigInt(first_guess(i));
  }
  guesses.sort(function(a, b) {
    if (a > b)  return 1;
    if (a < b)  return -1;
    return 0;
  });
  return guesses;
}

/** Simple primality test.**/
function is_prime(p) {
  p = BigInt(p);
  if (p % 2n == 0 || p % 3n == 0 || p % 5n == 0) {
    return false;
  }
  for (let i = 6n; i*i < p; i=i+6n) {
    if (p % (i+1n) == 0 || p % (i+5n) == 0) {
      return false;
    }
  }
  return true;
}

/** Given a prime, check if it's delicate within a range of bits.**/
function is_delicate(p, bit_index, bit_count) {
  const higher_bit_index = bit_index + bit_count;
  for (let i = bit_index; i < higher_bit_index; i += 1n) {
    if (is_prime(p ^ (1n << i))) {
      console.assert(0n != (p & (1n << i)),
                     "Setting a 0 bit to 1 should make the number composite.");
      return false;
    }
  }
  return true;
}

function main() {
  let guesses = first_guesses();
  console.log(first_guesses());

  const guess_limit = 10n**9n;
  const sanity_check_bit_count = 10000n;

  let higher_bit = 2n;
  let bit_count = 1n;
  while (higher_bit < (guess_limit << 1n)) {
    for (let guess_shard = 0; guess_shard < guesses.length; ++guess_shard) {
      const guess = guesses[guess_shard];
      guesses[guess_shard] += guess_increment;
      while (higher_bit <= guess) {
        higher_bit = higher_bit << 1n;
        bit_count += 1n;
      }
      if (is_prime(guess)) {
        if (is_delicate(guess, 0n, bit_count)) {
          console.log(guess.toString());
          console.assert(is_delicate(guess, bit_count, sanity_check_bit_count),
                         "Not widely delicate?!");
        }
      }
    }
  }
}

main();
