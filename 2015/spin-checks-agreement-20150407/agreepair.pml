
// There are always 2 processes!
#define N 2

// Maximimum value to agree on.
#define AgreeMax 5

// Index of the other process.
#define OTHER (1-i)

byte x[N];
byte initializing = N;

// Start up all the processes.
active[N] proctype P() {
  int i = _pid;

  // Randomize this process's x value.
  atomic {
    int tmp;
    select(tmp : 0 .. AgreeMax);
    x[i] = tmp;
  }
  // Done initializing.
  initializing --;
  // Block until both processes are ready to go!
  initializing == -1;

end:
  do
  :: x[i] < x[OTHER] ->
     x[i] ++;

  :: x[i] > x[OTHER] ->
     x[i] --;
  od;
}


// NOTE: Ensure that at most one LTL claim exists.
// Spin v6.4.3 has a bug that TOTALLY BREAKS the search for livelocks
// when a file contains more than one LTL claim.

// NOTE: Ensure that no LTL claims exist when using jSpin to verify safety.
// It won't look for deadlocks if claims exist.

#if 0
// Eventually, the x values will always differ by at most 1.
ltl close_enough {
  <> [] (-1 <= x[0] - x[1] && x[0] - x[1] <= 1)
}
#elif 0
// Eventually, the x values will always be equal.
ltl exactly_equal {
  <> [] (x[0] == x[1])
}
#endif

