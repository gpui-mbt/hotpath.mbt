# 0006 — Apple Silicon macOS native clock and release qualification

Status: open — remaining qualification evidence
Date: 2026-10-07 (JST)
Updated: 2026-10-16 (JST)
Parent: [0002 — Production-ready roadmap](../polished/0002-production-roadmap.md)
Milestones: M3 native-clock baseline implemented; M3 shared runtime semantics and M9 support qualification outstanding

## Goal

Qualify the already-shipped native macOS clock and runtime behavior on verified Apple Silicon arm64 hosts. Intel/x86_64 macOS, Rosetta and universal binaries remain outside scope.

## Delivered baseline (not full OS qualification)

As of [`main` at `5202f653`](https://github.com/gpui-mbt/hotpath.mbt/commit/5202f65371630b4d9305d0ed14ff4a4adfe3fd88):

- macOS uses [`clock_gettime(CLOCK_MONOTONIC)` and `clock_getres(CLOCK_MONOTONIC)`](../../src/native_clock.c), checked for failed reads and nanosecond overflow; the [opt-in `ProfilerNs` native facade](../../src/native_clock.mbt) preserves the existing millisecond API.
- [Native clock tests](../../src/native_clock_wbtest.mbt) cover ordered reads, nonnegative timestamps, reported resolution and closure-return preservation. Clock unit is not a promise of nanosecond precision.
- [CI run 38716584202](https://github.com/gpui-mbt/hotpath.mbt/actions/runs/38716584202) completed/success for `macos-native` (`macos-15`), explicitly checking `uname -m = arm64`, then format, native check/test and native clock overhead bench.
- The present native build and test baseline is real arm64 CI evidence, but does not qualify all Apple Silicon devices, macOS versions, or suspend/resume conditions.

## Scope and dependencies

Reuse the existing clock adapter, native tests, `ProfilerNs` API and CI. M3 timing/finalization, error handling, async/cancellation and concurrency contracts shared across OSes remain in the [parent roadmap](../polished/0002-production-roadmap.md). Completed histogram/nanosecond packets 0003/0004 must not be reopened.

## Remaining acceptance

- [ ] Record explicitly supported macOS versions, Apple Silicon arm64 host/execution architecture, MoonBit/core and native toolchains. Reject Intel/x86_64, Rosetta and untested OS/toolchain combinations from the advertised matrix.
- [ ] Measure real `CLOCK_MONOTONIC` resolution/overhead, validate monotonicity and document suspend/resume behavior and failure/overflow handling under reproducible OS conditions.
- [ ] Verify macOS-specific error/unwind/shutdown semantics against shared M3. Do not imply async/cancellation safety before that contract exists; keep `ProfilerNs` synchronous and not thread-safe.
- [ ] Run bounded-label stress, clock-read overhead and complete native-measurement benchmarks on declared arm64 hosts; capture commands, host architecture, version and results.
- [ ] Publish qualification evidence and unresolved limitations in the README/support matrix, separate from CI target/build success.

## Completion boundary

Evidence for this OS contributes to M3/M9 but does not by itself complete either milestone, validate every host or establish production readiness.
