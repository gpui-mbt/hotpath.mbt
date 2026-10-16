///|
fn percentile_rank(calls : Int32, percentile : Int32) -> Int64 {
  if calls <= 0 {
    return 0L
  }
  (calls.to_int64() * percentile.to_int64() + 99L) / 100L
}
