# 0007 — Linux native clock and release qualification

Status: open — remaining qualification evidence
Date: 2026-10-07 (JST)
Updated: 2026-10-16 (JST)
Parent: [0002 — Production-ready roadmap](../polished/0002-production-roadmap.md)
Milestones: M3 native-clock baseline implemented; M3 shared runtime semantics and M9 support qualification outstanding

## Goal

Qualify the already-shipped Linux native clock on explicitly supported distributions and architectures, retaining the Ubuntu CI baseline without generalizing it to all Linux systems.

## Delivered baseline (not full OS qualification)

As of [`main` at `5202f653`](https://github.com/gpui-mbt/hotpath.mbt/commit/5202f65371630b4d9305d0ed14ff4a4adfe3fd88):

- Linux uses [`clock_gettime(CLOCK_MONOTONIC)` and `clock_getres(CLOCK_MONOTONIC)`](../../src/native_clock.c) with explicit failures/overflow signaled by `-1` and the [native `ProfilerNs` facade](../../src/native_clock.mbt). No duplicate Linux clock adapter is needed.
- [Native clock tests](../../src/native_clock_wbtest.mbt) exercise ordered reads, reported positive resolution and successful closure measurement. They do not establish an OS/distro support matrix.
- [CI run 38716584202](https://github.com/gpui-mbt/hotpath.mbt/actions/runs/38716584202) completed/success for the Ubuntu `test` job: format, all-target check/test and native bench. All MoonBit targets passing on Ubuntu does not qualify other distributions or host architectures.
- Nanosecond storage is not nanosecond measurement accuracy; `ProfilerNs` remains synchronous, not thread-safe, and does not retain raw samples.

## Scope and dependencies

Reuse the existing clock adapter, native tests, `ProfilerNs` API and CI. M3 timing/finalization, error handling, async/cancellation and concurrency contracts shared across OSes remain in the [parent roadmap](../polished/0002-production-roadmap.md). Completed histogram/nanosecond packets 0003/0004 must not be reopened.

## Remaining acceptance

- [ ] List supported distro/version, architecture, libc/native build dependencies, MoonBit/core versions and runtimes. Leave untested combinations unqualified.
- [ ] Measure native clock resolution and monotonicity, document suspend/resume behavior and real clock failure/fallback limits. Record the actual host and toolchain for each claim.
- [ ] Verify Linux error/unwind/shutdown behavior against shared M3; do not claim async/cancellation guarantees until the shared contract and tests exist.
- [ ] Keep the Ubuntu CI baseline and run native bench, bounded-label stress and measured overhead across each further qualified host configuration. Different MoonBit targets on one runner are not separate OS qualifications.
- [ ] Link per-host evidence and remaining limitations from the README/support matrix.

## Completion boundary

Evidence for this OS contributes to M3/M9 but does not by itself complete either milestone, validate every host or establish production readiness.
