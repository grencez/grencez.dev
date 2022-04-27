/**
 * This ring of 6-state processes.
 * It is not self-stabilizing for ring size 13.
 **/

#include "uniring_protocol.h"

const uint8_t fsm_state_max = 5;

uint8_t local_uniring_transition(unsigned id, uint8_t s_i, uint8_t s_p)
{
#define v(t, x) (t+2*x)
  if (id == 0) {
    if (s_p==v(0,1) && s_i==v(0,0)) {return v(1,1);}
    if (s_p==v(0,1) && s_i==v(0,1)) {return v(1,0);}
    if (s_p==v(0,1) && s_i==v(0,2)) {return v(1,2);}
    if (s_p==v(0,2) && s_i==v(0,0)) {return v(1,1);}
    if (s_p==v(0,2) && s_i==v(0,1)) {return v(1,1);}
    if (s_p==v(0,2) && s_i==v(0,2)) {return v(1,0);}
    if (s_p==v(1,0) && s_i==v(1,0)) {return v(0,1);}
    if (s_p==v(1,0) && s_i==v(1,2)) {return v(0,2);}
    if (s_p==v(1,1) && s_i==v(0,0)) {return v(0,2);}
    if (s_p==v(1,1) && s_i==v(1,0)) {return v(0,1);}
    if (s_p==v(1,1) && s_i==v(1,1)) {return v(0,2);}
    if (s_p==v(1,1) && s_i==v(1,2)) {return v(0,1);}
    if (s_p==v(1,2) && s_i==v(1,0)) {return v(0,0);}
    if (s_p==v(1,2) && s_i==v(1,2)) {return v(0,2);}

  }
  else {
    if (s_p==v(0,0) && s_i==v(0,0)) {return v(0,1);}
    if (s_p==v(0,0) && s_i==v(1,0)) {return v(1,1);}
    if (s_p==v(0,0) && s_i==v(1,2)) {return v(0,2);}
    if (s_p==v(0,1) && s_i==v(0,0)) {return v(0,2);}
    if (s_p==v(0,1) && s_i==v(1,0)) {return v(0,1);}
    if (s_p==v(0,1) && s_i==v(1,1)) {return v(0,1);}
    if (s_p==v(0,1) && s_i==v(1,2)) {return v(0,2);}
    if (s_p==v(0,2) && s_i==v(0,0)) {return v(0,2);}
    if (s_p==v(0,2) && s_i==v(1,0)) {return v(0,1);}
    if (s_p==v(0,2) && s_i==v(1,1)) {return v(0,1);}
    if (s_p==v(0,2) && s_i==v(1,2)) {return v(0,1);}
    if (s_p==v(1,0) && s_i==v(0,0)) {return v(1,1);}
    if (s_p==v(1,0) && s_i==v(0,1)) {return v(1,2);}
    if (s_p==v(1,0) && s_i==v(0,2)) {return v(1,1);}
    if (s_p==v(1,1) && s_i==v(0,0)) {return v(1,1);}
    if (s_p==v(1,1) && s_i==v(0,1)) {return v(1,1);}
    if (s_p==v(1,1) && s_i==v(0,2)) {return v(1,1);}
    if (s_p==v(1,1) && s_i==v(1,0)) {return v(1,1);}
    if (s_p==v(1,1) && s_i==v(1,2)) {return v(1,1);}
    if (s_p==v(1,2) && s_i==v(0,0)) {return v(1,1);}
    if (s_p==v(1,2) && s_i==v(0,1)) {return v(1,2);}
    if (s_p==v(1,2) && s_i==v(0,2)) {return v(1,0);}
  }
#undef v
  return s_i;
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

