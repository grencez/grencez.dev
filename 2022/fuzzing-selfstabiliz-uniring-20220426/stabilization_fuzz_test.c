#include <assert.h>
#include <stddef.h>
#include <string.h>

#include "uniring_protocol.h"

#ifndef FSM_COUNT_MAX
#define FSM_COUNT_MAX 64
#endif

#ifndef FSM_COUNT_MIN
#define FSM_COUNT_MIN 1
#endif

#ifndef FSM_SYNCHRONOUS
#ifndef FSM_INTERLEAVING
/* Default is to have interleaving semantics (1 FSM acts at a time).*/
#define FSM_INTERLEAVING
#endif
#endif

static
  unsigned
synchronous_step(uint8_t* next, const uint8_t* statevec, unsigned n)
{
  next[0] = local_uniring_transition(0, statevec[0], statevec[n-1]);
  for (unsigned i = 1; i < n; ++i) {
    next[i] = local_uniring_transition(i, statevec[i], statevec[i-1]);
  }
  unsigned difference_count = 0;
  for (unsigned i = 0; i < n; ++i) {
    if (statevec[i] != next[i]) {
      difference_count += 1;
    }
  }
  return difference_count;
}

  bool
check_stabilizing_uniring_execution(const uint8_t* initial_statevec, unsigned fsm_count)
{
  // Code assumes that a ring exists.
  // Return otherwise to avoid warnings.
  if (fsm_count == 0) {return false;}

  uint8_t slow_statevec[FSM_COUNT_MAX];
  uint8_t statevec[FSM_COUNT_MAX];
  uint8_t next_statevec[FSM_COUNT_MAX];
  for (unsigned i = 0; i < fsm_count; ++i) {
    statevec[i] = initial_statevec[i];
    if (statevec[i] > fsm_state_max) {
      statevec[i] %= (uint8_t)(fsm_state_max+1);
    }
  }
#ifdef FSM_INTERLEAVING
  /* We want to model interleaving execution.
   * Luckily, on a unidirectional ring of self-disabling FSMs,
   * we can still model a unique "worst case" asynchronous execution
   * using synchronous steps as long as 1 FSM is disabled.
   *
   * Here, we simply detect if no FSM is disabled in the first step
   * and arbitrarily choose the first FSM to act on its own.
   * This ensures that 1 FSM is disabled for the rest of the execution.
   */
  if (fsm_count == synchronous_step(next_statevec, statevec, fsm_count)) {
    statevec[0] = local_uniring_transition(
        0, statevec[0], statevec[fsm_count-1]);
    synchronous_step(next_statevec, statevec, fsm_count);
  }
#else
  synchronous_step(next_statevec, statevec, fsm_count);
#endif
  memcpy(slow_statevec, statevec, fsm_count);
  while (0 != memcmp(next_statevec, slow_statevec, fsm_count)) {
    // Progress `next_statevec` by 2 steps.
    synchronous_step(statevec, next_statevec, fsm_count);
    synchronous_step(next_statevec, statevec, fsm_count);
    // Test loop condition for the intermediate step.
    if (0 == memcmp(statevec, slow_statevec, fsm_count)) {
      break;
    }
    // Only progress the `slow_statevec` by 1 step.
    synchronous_step(statevec, slow_statevec, fsm_count);
    memcpy(slow_statevec, statevec, fsm_count);
  }
  return global_uniring_legitimate(slow_statevec, fsm_count);
}

extern
#ifdef __cplusplus
  "C"
#endif
int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
{
  if (size < FSM_COUNT_MIN) {return 0;}
  if (size > FSM_COUNT_MAX) {size = FSM_COUNT_MAX;}
  assert(check_stabilizing_uniring_execution(data, size));
  return 0;  // Always return 0.
}
