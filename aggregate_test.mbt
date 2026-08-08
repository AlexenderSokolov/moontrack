///|
fn make_aggregate_store() -> TrackingStore {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Aggregation Test"))
  // run1: accuracy=0.80, loss=0.50
  ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
  ignore(
    store.log_metric(
      "run1",
      Metric::new("accuracy", 0.80, 1, "t1").with_direction(HigherBetter),
    ),
  )
  ignore(
    store.log_metric(
      "run1",
      Metric::new("loss", 0.50, 1, "t1").with_direction(LowerBetter),
    ),
  )
  ignore(store.complete_run("run1", "2026-01-01T01:00:00Z"))
  // run2: accuracy=0.90, loss=0.30
  ignore(store.start_run("run2", "exp1", "2026-01-02T00:00:00Z"))
  ignore(
    store.log_metric(
      "run2",
      Metric::new("accuracy", 0.90, 1, "t1").with_direction(HigherBetter),
    ),
  )
  ignore(
    store.log_metric(
      "run2",
      Metric::new("loss", 0.30, 1, "t1").with_direction(LowerBetter),
    ),
  )
  ignore(store.complete_run("run2", "2026-01-02T02:00:00Z"))
  // run3: accuracy=0.85, loss=0.40
  ignore(store.start_run("run3", "exp1", "2026-01-03T00:00:00Z"))
  ignore(
    store.log_metric(
      "run3",
      Metric::new("accuracy", 0.85, 1, "t1").with_direction(HigherBetter),
    ),
  )
  ignore(
    store.log_metric(
      "run3",
      Metric::new("loss", 0.40, 1, "t1").with_direction(LowerBetter),
    ),
  )
  ignore(store.complete_run("run3", "2026-01-03T01:30:00Z"))
  store
}

///|
test "aggregate_metric computes min, max, mean" {
  let store = make_aggregate_store()
  match store.aggregate_metric("exp1", "accuracy") {
    Ok(stats) => {
      assert_eq(stats.count(), 3)
      assert_true(stats.min_val() > 0.79 && stats.min_val() < 0.81)
      assert_true(stats.max_val() > 0.89 && stats.max_val() < 0.91)
      assert_true(stats.mean_val() > 0.84 && stats.mean_val() < 0.86)
    }
    Err(err) => fail("aggregate_metric failed: \{err.message()}")
  }
}

///|
test "aggregate_metric computes variance and std_dev" {
  let store = make_aggregate_store()
  match store.aggregate_metric("exp1", "accuracy") {
    Ok(stats) => {
      let v = stats.variance()
      let sd = stats.std_dev()
      assert_true(v > 0.0)
      assert_true(sd > 0.0)
    }
    Err(err) => fail("aggregate_metric failed: \{err.message()}")
  }
}

///|
test "aggregate_metric returns error for unknown experiment" {
  let store = make_aggregate_store()
  let result = store.aggregate_metric("nonexistent", "accuracy")
  assert_true(result is Err(_))
}

///|
test "aggregate_metric returns error for unknown metric" {
  let store = make_aggregate_store()
  let result = store.aggregate_metric("exp1", "nonexistent")
  assert_true(result is Err(_))
}

///|
test "aggregate_all_metrics collects stats for all metric keys" {
  let store = make_aggregate_store()
  match store.aggregate_all_metrics("exp1") {
    Ok(stats) => {
      assert_eq(stats.length(), 2)
      let keys = stats.map(fn(s) { s.key() })
      assert_true(array_contains_string(keys, "accuracy"))
      assert_true(array_contains_string(keys, "loss"))
    }
    Err(err) => fail("aggregate_all_metrics failed: \{err.message()}")
  }
}

///|
test "best_run finds highest accuracy for HigherBetter" {
  let store = make_aggregate_store()
  match store.best_run("exp1", "accuracy") {
    Ok(run) => assert_eq(run.id(), "run2")
    Err(err) => fail("best_run failed: \{err.message()}")
  }
}

///|
test "best_run finds lowest loss for LowerBetter" {
  let store = make_aggregate_store()
  match store.best_run("exp1", "loss") {
    Ok(run) => assert_eq(run.id(), "run2")
    Err(err) => fail("best_run failed: \{err.message()}")
  }
}

///|
test "best_run returns error for unknown experiment" {
  let store = make_aggregate_store()
  let result = store.best_run("nonexistent", "accuracy")
  assert_true(result is Err(_))
}

///|
test "MetricStats::range returns max minus min" {
  let store = make_aggregate_store()
  match store.aggregate_metric("exp1", "accuracy") {
    Ok(stats) => {
      let r = stats.range()
      assert_true(r > 0.09 && r < 0.11)
    }
    Err(err) => fail("aggregate_metric failed: \{err.message()}")
  }
}
