
/** Find a number that can be represented by 0 and 1 digits
 * in base 2, base 3, ..., base {MaxBase}.
 *
 * 82000 works for base 2 thru 5.
 * Can you find anything higher?
 * I have checked up to 11 million decimal digits without finding anything.
 * Perhaps a nonexistence proof is needed!
 *
 * Compile with:
 *   gcc -fopenmp -O3 -Wextra search82000.c -o search82000 -lgmp
 *
 * The -fopenmp flag is optional for a multithread version.
 * See also the search82000-mpi.c file for an MPI version.
 *
 * Modify parameters by changing {MinGuess}, {MinGuessDecimalDigits}, or {MaxBase}.
 *
 * Code adapted from /u/threenplusone's comment:
 *   http://www.reddit.com/r/math/comments/36jq0k/a_curious_property_of_82000/crf0pkn
 */

#include <assert.h>
#include <stdio.h>
#include <gmp.h>
/* #include <mpir.h> */
#ifndef NO_MAIN_FUNC
typedef unsigned int uint;
typedef int Bool;
#endif

#if 1
static const uint MinGuess = 2;
#else
static const uint MinGuess = 82001;
#endif

#if 1
/* Ignore.*/
static const uint MinGuessDecimalDigits = 0;
#else
/* Start checking beyond 11 million digits!*/
static const uint MinGuessDecimalDigits = 11000000;
#endif

static const uint MinBase = 3; /* We don't need to test base 2.*/
static const uint MaxBase = 5;

/** The core algorithm.
 *
 * Assume {nbits_max} is infinity if this is your first time reading the function.
 * Then this algorithm will terminate only when a solution is found.
 *
 * In general, we try until the number of bits
 * needed to represent {guess} exceeds {nbits_max}.
 * This allows the search to be partitioned across threads.
 */
static
  Bool
try_until (mpz_t guess, mp_bitcnt_t nbits_max,
           /* The rest are just temporaries.*/
           mpz_t high, mpz_t r1, mpz_t r2)
{
  uint base = MaxBase;
  Bool passing = 1;

  /* Keep guessing in this order:
   *   base == MaxBase
   *   base == MaxBase-1
   *   ...
   *   base == MinBase
   * And if {passing} is still true, the loop terminates with:
   *   base == MinBase-1 (success!)
   */
  while (base >= MinBase) {
    size_t ndigits;
    Bool passed = 1;
    ndigits = mpz_sizeinbase(guess, base);
    mpz_ui_pow_ui(high, base, ndigits);
    mpz_set(r1, guess);

    while (mpz_cmp_ui(high, 1) > 0) {
      if (mpz_cmp(r1, high) >= 0) {
        mpz_sub(r2, r1, high);
        if (mpz_cmp(r2, high) >= 0) {
          passed = 0;
          break;
        }
        mpz_set(r1, r2);
      }
      mpz_divexact_ui(high, high, base);
    }
    if (mpz_cmp_ui(r1, 1) > 0) {
      passed = 0;
    }

    if (!passed) {
      mpz_sub(guess, guess, r1);
      mpz_mul_ui(high, high, base);
      mpz_add(guess, guess, high);
      passing = 0;
    }

    if (base == MinBase && !passing) {
      base = MaxBase;
      passing = 1;
      if (nbits_max == 0 || nbits_max < mpz_sizeinbase(guess, 2)) {
        return 0;
      }
    }
    else {
      base -= 1;
    }
  }
  return 1;
}

static
  void
init_search_vbls (mpz_t guess, mpz_t high, mpz_t r1, mpz_t r2)
{
  if (MinGuessDecimalDigits > 0)
  {
    size_t base10digits = MinGuessDecimalDigits;
    mpz_init_set_ui (guess, 10);
    mpz_pow_ui (guess, guess, base10digits-1);
  }
  else {
    mpz_init_set_ui (guess, MinGuess);
  }

  mpz_init (high);
  mpz_init (r1);
  mpz_init (r2);

  assert(1 < MinBase);
  assert(MinBase <= MaxBase);
}

static
  void
lose_search_vbls (mpz_t guess, mpz_t high, mpz_t r1, mpz_t r2)
{
  mpz_clear (guess);
  mpz_clear (high);
  mpz_clear (r1);
  mpz_clear (r2);
}

static
  void
print_progress (FILE* out, mpz_t guess, size_t* progress, size_t progress_freq)
{
  size_t base10digits = mpz_sizeinbase(guess, 10);
  if (base10digits > *progress) {
    *progress = base10digits + progress_freq;
    fprintf (out, "digits: %u\n", (uint)base10digits);
    fflush (out);
  }
}

static
  void
assign_partition_range (uint work_idx, uint nbits_inc, mpz_t guess, mp_bitcnt_t* ret_nbits_max)
{
  mp_bitcnt_t nbits_max = work_idx;
  nbits_max *= nbits_inc;

  mpz_set_ui (guess, 0);
  mpz_setbit (guess, nbits_max);
  nbits_max += nbits_inc;

  if (mpz_cmp_ui(guess, MinGuess) < 0) {
    mpz_set_ui (guess, MinGuess);
  }
  *ret_nbits_max = nbits_max;
}

#ifndef NO_MAIN_FUNC
/** The main function.
 *
 * Here we have logic for partitioning the search across threads.
 * Also some progress reporting.
 */
int main()
{
  FILE* out = stdout;
#ifdef _OPENMP
  /* For parallel code, partition the search
   * into chunks of 128 binary digits.
   */
  static const uint nbits_inc = 128;
#else
  /* No partitioning for sequential code.*/
  static const uint nbits_inc = 0;
#endif
#ifdef _OPENMP
  /* Report progress whenever thread 0 finishes an iteration.*/
  static const uint progress_freq = 0;
#else
  /* Report progress every 100 decimal digits added.*/
  static const uint progress_freq = 100;
#endif
  Bool some_found = 0;
  size_t progress = 0;
  mpz_t answer;
  uint global_work_idx = 0;

  mpz_init (answer);

#pragma omp parallel shared(some_found, global_work_idx, answer)
  {
  mpz_t guess;
  mpz_t high, r1, r2;

  init_search_vbls (guess, high, r1, r2);

#pragma omp master
  if (nbits_inc > 0)
  {
    uint nbits_lowlim = mpz_sizeinbase (guess, 2);
    global_work_idx = nbits_lowlim / nbits_inc;
  }
#pragma omp barrier

  while (!some_found) {
    mp_bitcnt_t nbits_max = 0;
    Bool solution_found;

    if (nbits_inc > 0) {
      uint work_idx;
#pragma omp atomic capture
      work_idx = global_work_idx ++;
      assign_partition_range (work_idx, nbits_inc, guess, &nbits_max);
    }

    solution_found = try_until (guess, nbits_max, high, r1, r2);

    if (solution_found) {
#pragma omp critical (answer)
      {
        if (some_found) {
          if (mpz_cmp(guess, answer) < 0) {
            mpz_set (answer, guess);
          }
        }
        else {
          mpz_set (answer, guess);
          some_found = 1;
        }
      }
    }

#pragma omp master
    print_progress (out, guess, &progress, progress_freq);
  }

  lose_search_vbls (guess, high, r1, r2);
  }

  fputs ("SUCCESS: ", out);
  mpz_out_str (out, 10, answer);
  fputs ("\n", out);
  mpz_clear (answer);


  return 0;
}
#endif

