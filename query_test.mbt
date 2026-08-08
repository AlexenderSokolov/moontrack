///|
fn make_store_with_runs() -> TrackingStore {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  // run1: completed, tag=baseline, lr=0.01, accuracy=0.85
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_param("run1", Param::new_float("lr", 0.01))
  let _ = store.log_param("run1", Param::new_string("model", "resnet18"))
  let _ = store.log_metric(
    "run1",
    Metric::new("accuracy", 0.85, 1, "t1").with_direction(HigherBetter),
  )
  let _ = store.complete_run("run1", "2026-01-01T01:00:00Z")
  // run2: completed, tag=experiment, lr=0.001, accuracy=0.90
  let _ = store.start_run("run2", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_param("run2", Param::new_float("lr", 0.001))
  let _ = store.log_param("run2", Param::new_string("model", "resnet50"))
  let _ = store.log_metric(
    "run2",
    Metric::new("accuracy", 0.90, 1, "t1").with_direction(HigherBetter),
  )
  let _ = store.complete_run("run2", "2026-01-01T02:00:00Z")
  // run3: failed, tag=experiment, lr=0.1, accuracy=0.60
  let _ = store.start_run("run3", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_param("run3", Param::new_float("lr", 0.1))
  let _ = store.log_metric(
    "run3",
    Metric::new("accuracy", 0.60, 1, "t1").with_direction(HigherBetter),
  )
  let _ = store.fail_run("run3", "2026-01-01T00:30:00Z", "diverged")
  store
}

///|
test "search_runs with empty filter returns all runs" {
  let store = make_store_with_runs()
  let filter = RunFilter::new()
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 3)
}

///|
test "search_runs filters by status completed" {
  let store = make_store_with_runs()
  let filter = RunFilter::new().with_statuses([Completed])
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 2)
}

///|
test "search_runs filters by status failed" {
  let store = make_store_with_runs()
  let filter = RunFilter::new().with_statuses([Failed])
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run3")
}

///|
test "search_runs filters by param match" {
  let store = make_store_with_runs()
  let filter = RunFilter::new().with_param("model", "resnet50")
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run2")
}

///|
test "search_runs filters by metric min" {
  let store = make_store_with_runs()
  let filter = RunFilter::new().with_metric_min("accuracy", 0.88)
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run2")
}

///|
test "search_runs filters by metric max" {
  let store = make_store_with_runs()
  let filter = RunFilter::new().with_metric_max("accuracy", 0.70)
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run3")
}

///|
test "search_runs combines multiple filters" {
  let store = make_store_with_runs()
  let filter = RunFilter::new()
    .with_statuses([Completed])
    .with_metric_min("accuracy", 0.88)
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run2")
}

///|
test "search_runs sorts by metric ascending" {
  let store = make_store_with_runs()
  let filter = RunFilter::new()
  let sort = SortKey::by_metric_ascending("accuracy")
  let results = store.search_runs(filter, Some(sort))
  assert_eq(results.length(), 3)
  assert_eq(results[0].id(), "run3") // 0.60
  assert_eq(results[1].id(), "run1") // 0.85
  assert_eq(results[2].id(), "run2") // 0.90
}

///|
test "search_runs sorts by metric descending" {
  let store = make_store_with_runs()
  let filter = RunFilter::new()
  let sort = SortKey::by_metric_descending("accuracy")
  let results = store.search_runs(filter, Some(sort))
  assert_eq(results.length(), 3)
  assert_eq(results[0].id(), "run2") // 0.90
  assert_eq(results[1].id(), "run1") // 0.85
  assert_eq(results[2].id(), "run3") // 0.60
}

///|
test "RunFilter::with_param chains multiple params" {
  let store = make_store_with_runs()
  let filter = RunFilter::new()
    .with_param("model", "resnet18")
    .with_param("lr", "0.01")
  let results = store.search_runs(filter, None)
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "run1")
}
