///|
/// Nearest rank is the unique integer r with (r - 1) * 100 < calls * p
/// and calls * p <= r * 100. This inequality oracle does not reproduce the
/// implementation's rounded division. Int64 products are safe for Int calls.
/// Percentiles 1..100 are meaningful; nonpositive counts exercise the private
/// helper's defensive guard, not a reachable negative profiler sample count.
test "nearest rank satisfies independent rounding inequalities" {
  @quickcheck.check(
    (input : (Int, Byte)) => {
      let (calls, raw_percentile) = input
      let percentile = raw_percentile.to_int() % 100 + 1
      let rank = percentile_rank(calls, percentile)
      if calls <= 0 {
        rank == 0L
      } else {
        let scaled = calls.to_int64() * percentile.to_int64()
        (rank - 1L) * 100L < scaled && scaled <= rank * 100L
      }
    },
    count=2000,
    max_size=2147483647,
    max_shrinks=1000,
    seed=20261012,
  )
}

///|
test "nearest rank boundaries and defensive nonpositive counts" {
  for calls in [-2147483648, -100, -2, -1, 0] {
    for percentile in [1, 50, 95, 99, 100] {
      assert_eq(percentile_rank(calls, percentile), 0L)
    }
  }
  for
    (calls, percentile, expected) in [
      (1, 1, 1L),
      (1, 100, 1L),
      (99, 1, 1L),
      (100, 1, 1L),
      (101, 1, 2L),
      (99, 50, 50L),
      (100, 50, 50L),
      (101, 50, 51L),
      (100, 95, 95L),
      (101, 95, 96L),
      (100, 99, 99L),
      (101, 99, 100L),
      (2147483647, 1, 21474837L),
      (2147483647, 50, 1073741824L),
      (2147483647, 95, 2040109465L),
      (2147483647, 99, 2126008811L),
      (2147483647, 100, 2147483647L),
    ] {
    assert_eq(percentile_rank(calls, percentile), expected)
  }
}

///|
/// Regression for the baseline survivor: disabling the nonpositive guard.
test "negative count regression" {
  assert_eq(percentile_rank(-2, 100), 0L)
}
