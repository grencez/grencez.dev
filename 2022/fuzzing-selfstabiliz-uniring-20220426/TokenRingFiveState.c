/**
 * This ring of 5-state processes.
 * It is self-stabilizing for rings of all sizes.
 **/

#include "uniring_protocol.h"

const uint8_t fsm_state_max = 4;

uint8_t local_uniring_transition(unsigned id, uint8_t x_i, uint8_t x_p)
{
  if (id == 0) {
    if (x_p==0 && x_i==0) {return 1;}
    if (x_p==1 && x_i<=1) {return 2;}
    if (x_p> 1 && x_i> 1) {return 0;}
  }
  else {
    if (x_p==0 && x_i> 1) {return x_i/4;}
    if (x_p==1 && x_i!=1) {return 1;}
    if (x_p==2 && x_i<=1) {return 2+x_i;}
    if (x_p>=3 && x_i<=1) {return 4;}
  }
  return x_i;
}

bool global_uniring_legitimate(const uint8_t* x, unsigned n)
{
  uint8_t token_count = 0;
  if (false
      || (x[n-1]==0 && x[0]==0)
      || (x[n-1]==1 && x[0]<=1)
      || (x[n-1]> 1 && x[0]> 1)
     ) {
    token_count = 1;
  }
  for (unsigned i = 1; i < n; ++i) {
    if (false
        || (x[i-1]==0 && x[i]> 1)
        || (x[i-1]==1 && x[i]!=1)
        || (x[i-1]>=2 && x[i]<=1)
       ) {
      token_count += 1;
    }
  }
  return (token_count == 1);
}

