///|
fn percentile_rank(calls : Int, percentile : Int) -> Int64 {
  if calls <= 0 {
    return 0L
  }
  (calls.to_int64() * percentile.to_int64() + 99L) / 100L
}
