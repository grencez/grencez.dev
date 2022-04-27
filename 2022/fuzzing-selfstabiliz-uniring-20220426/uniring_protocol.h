#include <stdbool.h>
#include <stdint.h>
extern const uint8_t fsm_state_max;
uint8_t local_uniring_transition(unsigned id, uint8_t state, uint8_t state_bwd);
bool global_uniring_legitimate(const uint8_t* statevec, unsigned n);

// In stabilizing_fuzz_test.c.
bool check_stabilizing_uniring_execution(const uint8_t* initial_statevec, unsigned fsm_count);
