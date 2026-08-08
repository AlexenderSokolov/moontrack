///|
fn make_compare_store() -> TrackingStore {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  // Baseline run
  let _ = store.start_run("baseline", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric(
    "baseline",
    Metric::new("accuracy", 0.80, 1, "t1").with_direction(HigherBetter),
  )
  let _ = store.log_metric(
    "baseline",
    Metric::new("loss", 0.50, 1, "t1").with_direction(LowerBetter),
  )
  let _ = store.complete_run("baseline", "2026-01-01T01:00:00Z")
  // Comparison run - improved
  let _ = store.start_run("improved", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric(
    "improved",
    Metric::new("accuracy", 0.90, 1, "t1").with_direction(HigherBetter),
  )
  let _ = store.log_metric(
    "improved",
    Metric::new("loss", 0.40, 1, "t1").with_direction(LowerBetter),
  )
  let _ = store.complete_run("improved", "2026-01-01T02:00:00Z")
  store
}

///|
test "compare_runs computes deltas for common metrics" {
  let store = make_compare_store()
  let result = store.compare_runs("baseline", "improved")
  assert_true(result is Ok(_))
  match result {
    Ok(cmp) => {
      assert_eq(cmp.baseline_id(), "baseline")
      assert_eq(cmp.comparison_id(), "improved")
      assert_eq(cmp.deltas().length(), 2)
      assert_eq(cmp.added_keys().length(), 0)
      assert_eq(cmp.removed_keys().length(), 0)
    }
    Err(_) => fail("compare_runs failed")
  }
}

///|
test "compare_runs marks improved metrics correctly" {
  let store = make_compare_store()
  let cmp = store.compare_runs("baseline", "improved").unwrap()
  for delta in cmp.deltas() {
    if delta.key() == "accuracy" {
      assert_true(delta.improved()) // 0.80 -> 0.90, higher better
      assert_true(delta.delta() > 0.099 && delta.delta() < 0.101)
    }
    if delta.key() == "loss" {
      assert_true(delta.improved()) // 0.50 -> 0.40, lower better
      assert_true(delta.delta() > -0.101 && delta.delta() < -0.099)
    }
  }
}

///|
test "compare_runs returns error for unknown baseline" {
  let store = make_compare_store()
  let result = store.compare_runs("nonexistent", "improved")
  assert_true(result is Err(_))
}

///|
test "compare_runs returns error for unknown comparison" {
  let store = make_compare_store()
  let result = store.compare_runs("baseline", "nonexistent")
  assert_true(result is Err(_))
}

///|
test "compare_runs handles metrics only in baseline" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run_a", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric("run_a", Metric::new("unique_metric", 1.0, 1, "t1"))
  let _ = store.log_metric("run_a", Metric::new("shared", 0.5, 1, "t1"))
  let _ = store.complete_run("run_a", "2026-01-01T01:00:00Z")
  let _ = store.start_run("run_b", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric("run_b", Metric::new("shared", 0.6, 1, "t1"))
  let _ = store.complete_run("run_b", "2026-01-01T01:00:00Z")
  let cmp = store.compare_runs("run_a", "run_b").unwrap()
  assert_true(array_contains_string(cmp.removed_keys(), "unique_metric"))
  assert_eq(cmp.deltas().length(), 1) // only "shared" has a delta
}

///|
test "compare_runs percent_change is correct" {
  let store = make_compare_store()
  let cmp = store.compare_runs("baseline", "improved").unwrap()
  for delta in cmp.deltas() {
    if delta.key() == "accuracy" {
      // (0.90 - 0.80) / 0.80 * 100 = 12.5
      assert_true(delta.percent_change() > 12.0)
      assert_true(delta.percent_change() < 13.0)
    }
  }
}
