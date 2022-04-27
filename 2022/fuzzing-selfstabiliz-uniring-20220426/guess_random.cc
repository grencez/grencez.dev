#include <random>
extern "C" {
#include "uniring_protocol.h"
}

#ifndef FSM_COUNT_MAX
#define FSM_COUNT_MAX 8
#endif

#ifndef GUESS_COUNT
#define GUESS_COUNT 1000000
#endif

int main() {
  const unsigned fsm_count = FSM_COUNT_MAX;
  const unsigned guess_count = GUESS_COUNT;
  unsigned violation_count = 0;
  std::random_device rndev;
  std::mt19937 rngen(rndev());
  std::uniform_int_distribution<uint8_t> state_distrib(0, fsm_state_max);

  for (unsigned guess_id = 0; guess_id < guess_count; ++guess_id) {
    uint8_t initial_statevec[FSM_COUNT_MAX];
    for (unsigned i = 0; i < fsm_count; ++i) {
      initial_statevec[i] = state_distrib(rngen);
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
