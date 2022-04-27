---
canonical_url: https://grencez.dev/2022/fuzzing-selfstabiliz-uniring-20220426
date: 2022-04-26
description: An attempt to verify self-stabilizing token rings by fuzzing their initial states.
---

# Fuzz testing self-stabilization on unidirectional rings

Date: 2022-04-26

Code: [https://github.com/grencez/grencez.dev/tree/trunk/2022/fuzzing-selfstabiliz-uniring-20220426](https://github.com/grencez/grencez.dev/tree/trunk/2022/fuzzing-selfstabiliz-uniring-20220426)

## Abstract
In this article, I model some unidirectional token ring protocols in C, write a test that detects whether a protocol eventually provides mutual exclusion from a given initial state, and use a fuzzer to choose that initial state.
This is essentially treating the fuzzer as a model checker.

After refining the test code, [libFuzzer](https://llvm.org/docs/LibFuzzer.html) performs decently but still worse than a custom random fuzzer.
This is somewhat expected due to the relative ease with which random inputs can trigger failures (in cases where there are failures to detect).

## Motivation
Using fuzzed inputs, you can often write a test that is only guaranteed to pass if the system under test is provably correct.
This statement is tempered by a "can often" qualifier because most fuzz tests are not written with completeness in mind.
Fuzzers themselves make no attempt to exhaust the input space anyway.
Reality notwithstanding, it's nice to think of correctness as a direct consequence of an everyday test.

In that light, fuzzing is probably the closest thing to a formal method that sees widespread use in software development.
Let's see how well it performs in a formal setting: verifying self-stabilizing token rings.

## What is a self-stabilizing token ring?
A token ring protocol provides mutual exclusion by passing exactly 1 token around the ring.
A [self-stabilizing](https://en.wikipedia.org/wiki/Self-stabilization) token ring is one that converges to this behavior from any initial state.

Dijkstra coined the "self-stabilization" term in a paper ([Self-stabilizing Systems in Spite of Distributed Control](https://doi.org/10.1145%2F361179.361202)) that introduced a such a token ring.
Actually, the paper introduced 3 different token rings, but let's talk about the unidirectional one.
In this protocol, each finite-state machine in the ring can read the preceding machine's state and change its own state in one atomic step.
Tokens in this protocol are held by any machine that is eligible to act based on the following rules:
* A unique machine named `Bot` increments its state (modulo its number of states) whenever the preceding state maches its own.
* Each other machine in the ring simply copies its predecessor's state when that value does not match its own.

```
// TL;DR:
Bot:   t[N-1] == t[0] --> t[0] := (t[0]+1) mod K;
P[i]:  t[i-1] != t[i] --> t[i] := t[i-1];
// for 0 < i < N.
```

This protocol is self-stabilizing iff each machine in the ring has at least as many different states as the number of machines participating in the ring.
In fact, machines can have 1 state less than the ring size if actions are atomic.

Dijkstra's unidirectional token ring is my favorite because of how fast it converges to its intended behavior.
I discovered a similar protocol that uses 5-state machines, but its convergence can involve passing extra tokens around the ring many times before they are forced to collide.
Long paths to convergence can make verification expensive, and the journey to find a minimal-state protocol was full of examples that failed at large ring sizes.
In this study, `NonStabilizing_TokenRingSixState.c` is one such example that becomes non-stabilizing when 13 or more of its 6-state machines participate in the ring.

## Fuzz test implementation
Let's walk through the fuzz test implementation in `stabilization_fuzz_test.c`.
Remember, the link to all the code can be found at the top of this article.

We'll be targeting libFuzzer since it seems like the most accessible option.
In the most minimal sense, this fuzzer is just some code that calls a function named `LLVMFuzzerTestOneInput()`, which we define, with a random-ish bytestring.

### How to use the fuzzed bytestring?
A global state `statevec` of the modeled token ring is initialized from fuzzed data like this:
```c
// Defined in protocol-specific source file.
// Largest value a finite-state machine can hold.
extern const uint8_t fsm_state_max;

// Lower and upper bounds on the number of finite-state machines in a ring.
// In the code, these are wrapped with #ifndef to allow compile-time overrides.
#define FSM_COUNT_MIN 1
#define FSM_COUNT_MAX 64

  bool
check_stabilizing_uniring_execution(const uint8_t* initial, unsigned fsm_count)
{
  uint8_t statevec[FSM_COUNT_MAX];
  for (unsigned i = 0; i < fsm_count; ++i) {
    statevec[i] = initial_statevec[i];
    if (statevec[i] > fsm_state_max) {
      statevec[i] %= (uint8_t)(fsm_state_max+1);
    }
  }
  // ... see next section ...
}

extern  // Needs to be `extern "C"` when compiling as C++.
  int
LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
{
  if (size < FSM_COUNT_MIN) {return 0;}
  if (size > FSM_COUNT_MAX) {size = FSM_COUNT_MAX;}
  assert(check_stabilizing_uniring_execution(data, size));
  return 0;  // Always return 0.
}
```

LibFuzzer is guided by coverage in some aspect and can infer how fuzzed data is used.
I found some coding patterns to be particularly impactful:

1. Make the tested code as small and simple as possible.
   * We're trying verify liveness, so it's best to keep it simple.
1. Return early to avoid excessively small input bytestrings.
   * LibFuzzer learns quickly.
1. Ignore the extra data if the input bytestring is too large.
   * LibFuzzer seems to learn this too.
1. Use mod when out-of-range data needs to be clamped.
   * This preserves input "randomness" and gives the fuzzer direct control over the most useful range (where mod is a no-op).
   * Bitmasks are acceptable substitutes for power-of-2 moduli.

### How to model the scheduler?
If all machines are ready to act, let one act so it put itself in a waiting state.
```c
// Defined in protocol-specific source file.
// Returns the next state of a finite-state machine
// given its own state and its predecessor's state.
// An `id` is also provided so the machine at `id==0` can behave uniquely.
uint8_t local_uniring_transition(unsigned id, uint8_t state, uint8_t state_bwd);

// Fills in `next` state vector as the result of every machine acting at once.
// Returns the number of machines that did act (changed state).
unsigned synchronous_step(uint8_t* next, const uint8_t* statevec, unsigned n)
{ /* A loop that calls local_uniring_transition() for each FSM.*/ }

  bool
check_stabilizing_uniring_execution(const uint8_t* initial, unsigned fsm_count)
{
  uint8_t next_statevec[FSM_COUNT_MAX];
  // ... see previous section ...
  if (fsm_count == synchronous_step(next_statevec, statevec, fsm_count)) {
    statevec[0] = local_uniring_transition(
        0, statevec[0], statevec[fsm_count-1]);
    synchronous_step(next_statevec, statevec, fsm_count);
  }
  // ... see next section ...
}
```

For all subsequent steps, we can let machines act synchronously (next section).
Most other topologies require you to model nondeterministic scheduling choices, but unidirectional rings are a special case.
During design, we trivially avoided creating machines that would be ready to act immediately after acting.
Therefore, the number of machines that are ready to act will not increase over time.
This is why we lose no generality by looking at these "worse case" executions.
A full proof can be found in [Local Reasoning for Global Convergence of Parameterized Rings](https://doi.org/10.1109/ICDCS.2012.66) by Aly Farahat and Ali Ebnenasir.

### How to model executions?
Let machines act until the system revits some global state.
I use the [tortoise and hare](https://en.wikipedia.org/wiki/Cycle_detection#Floyd's_tortoise_and_hare) cycle detection algorithm for simplicity.
```c
  bool
check_stabilizing_uniring_execution(const uint8_t* initial, unsigned fsm_count)
{
  uint8_t slow_statevec[FSM_COUNT_MAX];
  // ... see previous section ...
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
  // ... see next section ...
}
```

### How to test stabilization?
The test fails if execution ends (or cycles) in a global state with more than token.
I didn't bother implementing a closure check (e.g., that exactly 1 token is maintained forever), but you could check for that during execution.
```c
// Defined in protocol-specific source file.
// Returns true if and only if exactly 1 token exists in the ring.
bool global_uniring_legitimate(const uint8_t* statevec, unsigned n);

  bool
check_stabilizing_uniring_execution(const uint8_t* initial, unsigned fsm_count)
{
  // ... see previous section ...
  return global_uniring_legitimate(slow_statevec, fsm_count);
}
```

### How to compile?
I'm using Bazel to compile, so fuzz test targets are defined by [rules_fuzzing](https://github.com/bazelbuild/rules_fuzzing)'s `cc_fuzz_test()` rule.
With `@rules_fuzzing` pointing to that project (configured in the [WORKSPACE](https://github.com/grencez/grencez.dev/blob/trunk/WORKSPACE) file), a fuzz test target can be defined in `BUILD.bazel` like:
```python
load("@rules_fuzzing//fuzzing:cc_defs.bzl", "cc_fuzz_test")

cc_fuzz_test(
    name = "NonStabilizing_TokenRingFourState_fuzz_test",
    srcs = [
        "stabilization_fuzz_test.c",  # Test driver.
        "uniring_protocol.h",  # Protocol-specific declarations.
        "NonStabilizing_TokenRingFourState.c",  # Protocol-specific definitions.
    ],
    copts = ["-std=c99"],  # Limit myslf to C99.
    # Rule uses Bash scripts, so Windows probably won't work.
    target_compatible_with = select({
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    # Optional lower and upper bounds on the number of finite-state machines.
    defines = ["FSM_COUNT_MIN=8", "FSM_COUNT_MAX=8"],
)
```

Compiling it is not very useful but can catch syntax errors:
```shell
bazel build :NonStabilizing_TokenRingFourState_fuzz_test
```

## Running the trials

### How to run?
To actually run the fuzz test, the target must be built with `clang` and some flags that link in libFuzzer.
These lines in my [.bazelrc](https://github.com/grencez/grencez.dev/blob/trunk/.bazelrc) file let me specify all those settings with a single `--config=libfuzzer` or `--config=asan-libfuzzer` flag:
```
# --config=clang
build:clang --action_env=CC=clang --action_env=CXX=clang++
# --config=libfuzzer
build:libfuzzer --config=clang
build:libfuzzer --@rules_fuzzing//fuzzing:cc_engine=@rules_fuzzing//fuzzing/engines:libfuzzer
build:libfuzzer --@rules_fuzzing//fuzzing:cc_engine_instrumentation=libfuzzer
# --config=asan-libfuzzer
build:asan-libfuzzer --config=libfuzzer
build:asan-libfuzzer --@rules_fuzzing//fuzzing:cc_engine_sanitizer=asan
```

I'm only looking for assertion failures, so ASAN isn't necessary.
To avoid reusing past results, I pass `-clean` to `@rules_fuzzing`'s wrapper script.
Additional arguments will apply to libFuzzer directly.
```shell
bazel run --config=libfuzzer :NonStabilizing_TokenRingFourState_fuzz_test_run -- -clean --
```

### Expectation
The median number of guesses that we expect a random fuzzer to need to find a test failure is calculated more directly as `log(0.5)/log(1-probability_of_test_failure)`.
For the smaller rings of 4-state machine, the probability comes from an exhaustive search.
For the larger fixed-size rings, an approximate probability is obtained by a lot of guessing.
```c
#include <math.h>
#include <stdio.h>
int main() {
  unsigned guess_count = 100000;
  unsigned violation_count = 0;
  for (unsigned guess = 0; guess < guess_count; ++i) {
    uint8_t initial_statevec[FSM_COUNT_MAX] = /* random */;
    if (!check_stabilizing_uniring_execution(initial_statevec, fsm_count)) {
      violation_count += 1;
    }
  }
  double probability_of_violation = (double)violation_count / trial_count;
  fprintf(stdout, "Expect median number of guesses to be: %.0f.\n",
          ceil(-1.0 / log2(1 - probability_of_violation)))
  return 0;
}
```

### Methodology
A `median_trials.sh` script runs fuzz tests several times and extracts the median number of guesses reported by libFuzzer.
```shell
# Run 101 times and get median number of guesses.
./median_trials.sh 101 NonStabilizing_TokenRingFourState
```

Notice how there's no parameter for the number of machines in the ring?
That's because the range of ring sizes is defined at compile-time in `BUILD.bazel` with lines lke `defines = ["FSM_COUNT_MIN=8", "FSM_COUNT_MAX=8"]`.
This adds toill to rerunning trials , so an [alternative](#compiling_in_the_range) approach may have been better.

## Results
Compared to random guessing, how well does libFuzzer detect non-stabilizing token rings?

| Token Ring       | Ring Size | Failure Chance | Random Guesses | LibFuzzer Guesses |
| ---------------- |:---------:|:--------------:|:--------------:|:-----------------:|
| 5-State          |     1--64 |  0%            |       infinity |          infinity |
| 4-state          |         8 |  0.415%        |            167 |             ~1150 |
| 4-state          |         9 |  0.83%         |             84 |             ~1300 |
| 4-state          |        10 |  1.482%        |             47 |             ~1100 |
| 4-state          |        11 |  2.207%        |             32 |             ~1050 |
| 4-state          |        12 |  3.073%        |             23 |             ~1300 |
| 4-state          |     1--64 |  N/A           |            N/A |             ~1500 |
| 6-state Buggy    |        13 | ~0.042%        |          ~1650 |             ~8500 |
| 6-state Buggy    |        14 | ~0.0006%       |        ~115525 |            ~60000 |
| 6-state Buggy    |        15 | ~0.24%         |           ~289 |             ~4500 |
| 6-state Buggy    |        16 | ~0.012%        |          ~5776 |            ~20000 |
| 6-state Buggy    |        17 | ~0.73%         |            ~95 |             ~2700 |
| 6-State Dijkstra |         8 |  0.004287%     |          16170 |             ~8200 |
| 7-State Dijkstra |         9 |  0.000243%     |         285418 |           ~260000 |
| N-State Dijkstra |     1--64 |  0%            |       infinity |          infinity |

While random chance clearly influences libFuzzer's expected number of guesses, there appears to be more going on.
In fact, this data warrants a whole list of anomalies and caveats:

1. LibFuzzer guess count can vary a lot.
   * What is reported is often a median of medians. I tried to make the numbers representative of my experience.
1. LibFuzzer guess count is low.
   * The number is from libFuzzer's last progress report before finding a test failure, so it's slightly below reality.
1. LibFuzzer guess count is high.
   * There appears to be a constant-ish number in the 4-state results, which I suspect are trivial guesses made to increase coverage.
1. LibFuzzer guesses are slower than random ones.
   * It does extra work to analyze coverage, which yields a 4x slowdown for my tests (which surely isn't representative).
1. Individual trials can be extremely unlucky and appear stuck.
   * For the case of 9 7-state machines ("7-State Dijkstra"), there are 98 failure cases hiding among ~40.35 million possibilities, yet libFuzzer managed to exceed 60 million guesses in one trial! It did always find its mark though.
1. LibFuzzer sometimes outperformed random chance!
   * Specifically in the case of 14 6-state machines.
   * Time-wise, random guessing was still faster.

## Conclusion
Even though a randomized fuzzer worked best, I think libFuzzer performed well.
LibFuzzer may not be designed to test for reachability, livelocks, or liveness propertiess in general, but it certainly did do its job.
Its knack for exposing bugs was quite useful while I was writing the test code, and it did provide random enough data to solve my problems.

## Appendix: Alternatives Considered
In an effort to share something useful about fuzzing, I made a few decisions that might be worth mentioning but would have detracted from the main article above.

### Why not an easier problem than self-stabilization?
As a way to test whether a system behaves correctly in any state, fuzzing seemed like a natural fit.
Pairing the two is still a nice thought, but fuzzing wasn't made for checking liveness properties (e.g., livelock detection).
Fuzzing surely would have performed better if deadlocks or other safety violations were our primary concern.
Maybe that or a similarly easy problem domain would be a fun exercise.

### Why not use real threads?
It would be cool to use threads to implement the actual protocol and test it, but that gets complicated.
* Execution model is different.
* Fairness model is different.
* Distributed livelock detection is hard!
* The test itself would be more expensive.

### Why not let the fuzzer determine scheduling?
I initially did let the fuzzer control the order that machines could act, but this resulted in no test failures.
This is partially due to a slower test (more steps to revisit a state), but it was mostly due to randomness working against us.
Test failures at the smallest ring sizes require all but 1 machine to remain active at every step.
For example, given a state where 8 of the 4-state machines can be in a livelock, the scheduler must choose a specific 1 out of 7 ready machines 48 times to reproduce that livelock.
Choosing getting a random 1 out of 7 choice correct 48 times in succession is infeasible, to say the least.

Perhaps adding a branch in the code could guide libFuzzer to make better scheduling choices.
For example, the `check_stabilizing_uniring_execution()` function could return `true` if the number of ready machines decreases.
I didn't explore this possibility because it still makes assumptions about the nature of livelocks.
Unlike on unidirectional rings, livelocks on general topologies may require the number of ready machines to fluctuate.

### Why not use libFuzzer parameters to control the number of FSMs? {#compiling_in_the_range}
I somewhat regret the decision to define the range of ring sizes at compile time.
However, it does feel like compile-time constants should give libFuzzer a more accurate view of how it should focus its efforts.

In retrospect, it would be easier to just run fuzz tests with `-max_len=$N` to model a ring of up to `$N` machines.
Passing in `-len_control=0` would further ensure that smaller rings would not be tested as much as larger ones.

### Why not use model checking?
Model checkers intend to check "models" of programs that have been simplified enough to make an exhaustive search feasible.
For example, when a model is small enough, all of its possible behaviors across all reachable states can be represented as a transition graph, which lets claims about system behavior to be verified by graph algorithms (like cycle detection).

A complete solve is great, but it quickly becomes expensive.
For perspective, the transition graph for 13 6-state machines would need a node for each of its 13 billion reachable states, and recording arcs between those could easily consume over 100 GiB!
Binary decision diagrams can represent the transition system more efficiently, but checking it is still pretty expensive (cycle detection takes ~25 minutes).
Aside from cost, fuzzing is just more accessible.
