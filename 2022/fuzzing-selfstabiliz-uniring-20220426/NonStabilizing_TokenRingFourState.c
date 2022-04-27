/**
 * This ring of 4-state processes.
 * It is not self-stabilizing for ring sizes 8 and above.
 **/

#include "uniring_protocol.h"

const uint8_t fsm_state_max = 3;

uint8_t local_uniring_transition(unsigned id, uint8_t state, uint8_t state_bwd)
{
  const uint8_t t_bwd = 1 & state_bwd;
  const uint8_t x_bwd = 1 & (state_bwd >> 1);
  uint8_t t = 1 & state;
  uint8_t x = 1 & (state >> 1);

  if (id == 0) {
    if (x_bwd == x && t_bwd != t) {
      x ^= 1;
    }
    else if (x_bwd == x && t_bwd == t) {
      x ^= 1;
      t = x_bwd;
    }
  }
  else {
    if (x_bwd != x && t_bwd == t) {
      x ^= 1;
    }
    else if (x_bwd != x && t_bwd != t) {
      x ^= 1;
      t = x_bwd;
    }
  }
  return (x << 1) | t;
}

bool global_uniring_legitimate(const uint8_t* statevec, unsigned n)
{
  uint8_t token_count = 0;
  if ((statevec[n-1] & 1) == (statevec[0] & 1)) {
    token_count = 1;
  }
  for (unsigned i = 1; i < n; ++i) {
    if ((statevec[i-1] & 1) != (statevec[i] & 1)) {
      token_count += 1;
    }
  }
  return (token_count == 1);
}

