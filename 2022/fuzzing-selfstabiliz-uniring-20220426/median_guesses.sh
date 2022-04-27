#!/bin/sh

set -e

n="$1"
middle=$(echo "$n / 2 + 1" | bc)
target="$2"

for i in $(seq 1 $n) ; do
  bazel run --config=libfuzzer ":${target}_fuzz_test_run" -- -clean -- 2>&1 |
  tee /dev/stderr |
  grep "^#" |
  tail -n 1
done |
sed -E -e 's/^#([0-9]*).*$/\1/' |
sort -n |
head -n "$middle" |
tail -n 1 |
sed -e 's/^/median is: /'
