# 0005 — Windows native clock and release qualification

Status: open — remaining qualification evidence
Date: 2026-10-07 (JST)
Updated: 2026-10-16 (JST)
Parent: [0002 — Production-ready roadmap](../polished/0002-production-roadmap.md)
Milestones: M3 native-clock baseline implemented; M3 shared runtime semantics and M9 support qualification outstanding

## Goal

Qualify the already-shipped Windows monotonic clock implementation and runtime behavior on explicitly recorded Windows hosts; do not reimplement the existing adapter.

## Delivered baseline (not full OS qualification)

As of [`main` at `5202f653`](https://github.com/gpui-mbt/hotpath.mbt/commit/5202f65371630b4d9305d0ed14ff4a4adfe3fd88):

- Native [`QueryPerformanceCounter` / `QueryPerformanceFrequency`](../../src/native_clock.c) reads use checked integer conversion to nanoseconds; invalid reads, unsupported frequency and overflow return `-1` rather than an invented duration.
- [`ProfilerNs::measure_native_ns`](../../src/native_clock.mbt) and `native_clock_resolution_ns()` are opt-in native APIs. The original millisecond API is unchanged; the native adapter is not exposed on JavaScript targets.
- [Native clock tests](../../src/native_clock_wbtest.mbt) exercise ordered reads and positive reported resolution, plus Windows QPC tick conversion, large values, invalid frequencies and integral-nanosecond resolution.
- [CI run 38716584202](https://github.com/gpui-mbt/hotpath.mbt/actions/runs/38716584202) completed/success for the `windows` job (`windows-2025`): format, all-target check/test and native bench. This is a tested runner baseline, not an OS support-matrix certification.

## Scope and dependencies

Reuse the existing clock adapter, native tests, `ProfilerNs` API and CI. M3 timing/finalization, error handling, async/cancellation and concurrency contracts shared across OSes remain in the [parent roadmap](../polished/0002-production-roadmap.md). Completed histogram/nanosecond packets 0003/0004 must not be reopened.

## Remaining acceptance

- [ ] Publish an exact Windows edition/version, architecture, runtime, MoonBit/core and native toolchain matrix. Record the observed runner image and compiler; do not extrapolate `windows-2025` coverage to every Windows host.
- [ ] Record the QPC source, measured clock resolution/precision, monotonicity and suspend/resume limitations on each claimed host. Exercise and document clock failure, conversion bounds and explicit unsupported behavior with reproducible evidence.
- [ ] Verify OS-specific error/unwind/shutdown semantics against the shared M3 contract, including no fabricated duration after a clock failure. Async/cancellation guarantees remain out of scope until the parent contract is defined.
- [ ] Run bounded-label stress and native clock/measurement overhead checks against documented workloads on qualified host configurations. Preserve the synchronous, non-thread-safe `ProfilerNs` model.
- [ ] Link successful host/command logs and measured limitations from the README/support matrix. Keep untested combinations unqualified.

## Completion boundary

Evidence for this OS contributes to M3/M9 but does not by itself complete either milestone, validate every host or establish production readiness.
