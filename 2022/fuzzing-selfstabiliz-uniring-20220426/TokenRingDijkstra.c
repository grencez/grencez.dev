/**
 * Token passing around a ring defined in
 * Title: Self-stabilizing Systems in Spite of Distributed Control
 * Author: Edsger W. Dijkstra
 * Year: 1974
 *
 * It is self-stabilizing iff the ring size is less than or equal to
 * the number of states that participating machines can be in.
 * Since our machine states are represented by uint8_t,
 * this will not reliably stabilize for rings of size 257 and up.
 * You can lower the FSM_STATE_COUNT to make smaller rings non-stabilizing.
 **/

#include "uniring_protocol.h"

#ifndef FSM_STATE_COUNT
#define FSM_STATE_COUNT 256
#endif

const uint8_t fsm_state_max = FSM_STATE_COUNT-1;

uint8_t local_uniring_transition(unsigned id, uint8_t x_i, uint8_t x_p)
{
  if (id == 0) {
    if (x_p == x_i) {
      if (x_i == fsm_state_max) {return 0;}
      return x_i + 1;
    }
  }
  else {
    if (x_p != x_i) {return x_p;}
  }
  return x_i;
}

bool global_uniring_legitimate(const uint8_t* x, unsigned n)
{
  uint8_t token_count = 0;
  if (x[n-1] == x[0]) {
    token_count = 1;
  }
  for (unsigned i = 1; i < n; ++i) {
    if (x[i-1] != x[i]) {
      token_count += 1;
    }
  }
  return (token_count == 1);
}
