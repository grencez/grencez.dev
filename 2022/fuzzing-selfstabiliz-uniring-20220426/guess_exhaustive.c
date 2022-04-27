#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include "uniring_protocol.h"

#ifndef FSM_COUNT_MAX
#define FSM_COUNT_MAX 8
#endif

int main() {
  static const unsigned fsm_count = FSM_COUNT_MAX;
  unsigned violation_count = 0;
  unsigned guess_count = 1;
  for (unsigned j = 0; j < fsm_count; ++j) {
    assert(guess_count <= UINT_MAX / (1+fsm_state_max));
    guess_count *= 1+(unsigned)fsm_state_max;
  }

  for (unsigned i = 0; i < guess_count; ++i) {
    uint8_t initial_statevec[FSM_COUNT_MAX];
    unsigned x = i;
    for (unsigned j = 0; j < fsm_count; ++j) {
      initial_statevec[j] = x % (1+(unsigned)fsm_state_max);
      x /= (1+(unsigned)fsm_state_max);
    }
    if (!check_stabilizing_uniring_execution(initial_statevec, fsm_count)) {
      violation_count += 1;
    }
  }
  fprintf(
      stdout,
      "%u out of %u are non-stabilizing (%f%%).\n",
      violation_count, guess_count,
      100.0*violation_count/guess_count);
  double probability_of_violation = (double)violation_count / guess_count;
  fprintf(stdout, "Expect median number of guesses to be: %.0f.\n",
          ceil(-1.0 / log2(1 - probability_of_violation)));
  return 0;
}
