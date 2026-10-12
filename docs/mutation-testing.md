# Bounded nearest-rank mutation pilot

The pilot scopes turtles to the private, pure `percentile_rank` helper. Its body
was moved unchanged from `hotpath.mbt`; no public API or timing behavior changes.
There are no wall-clock assertions, performance thresholds, or global state.

## Run

The recorded run used MoonBit `moon 0.1.20260920 (914d7da 2026-09-20)`
and turtles `0.4.6` on Linux. CI currently installs its latest toolchain; hosted
CI was not run for this local pilot.

```sh
moon fmt --check
moon check --target all -j 2
moon test --target all -j 2
python3 -m unittest discover -s scripts/tests -p 'test_release_version.py' -v
turtles --target native --list
turtles --target native -j 2 --timeout 20 --json after.json
```

The checked-in config intentionally limits the mutation surface. Check that
`--list` is nonempty before interpreting a score. The campaign tests the full
module, uses at most two workers, and imposes a 20-second per-command timeout.
It is not a full-repository quality score.

## Properties and regression

Official `moonbitlang/core/quickcheck.check` runs 2,000 tuple cases with seed
20261012, max_size 2147483647, and max_shrinks 1000. Generated percentiles
span 1..100. The independent oracle defines ceiling through integer inequalities
rather than repeating the implementation's rounded division. All relevant
products fit Int64. Explicit examples cover nonpositive counts, exact and
adjacent rounding boundaries, and Int-max counts at 1/50/95/99/100 percentiles.

Production callers use 50/95/99 percentiles and nonnegative sample counts.
Negative-count checks validate the private helper's existing defensive guard;
they do not establish a production-reachable defect.

At source 097025f748de93d5285d02e3dab7218a39acce36, two untouched native
baselines passed 17/17 tests. A third baseline after unchanged helper extraction
also passed. Before adding tests, the nine-mutant campaign killed eight and
left one survivor: replacing `calls <= 0` with `false`. With the same source,
config, mutant IDs and toolchain, the new tests killed all nine. Neither run
had timeouts, unviable or target-inactive mutants. The score change from
88.89% to 100% is solely improved defensive-guard coverage.

The property itself killed that survivor and shrank to `(-3, 0x42)` (67th
percentile). Independent replay falsified after two cases, with 25 successful
shrinks from 58 attempts. The compact permanent regression uses calls=-2, percentile=100.
Running just that regression passed on pristine source and failed on an
isolated guard-disabled copy with -1 instead of 0.

Final local checks passed: formatting, all-target checking, native 20/20 tests,
wasm/wasm-gc/js each 18/18 tests, and ten release-guard Python tests.
Existing deprecation warnings were unchanged. Native benchmarks, hosted CI,
Windows and macOS qualification were not run. No commit, push or PR was made.
