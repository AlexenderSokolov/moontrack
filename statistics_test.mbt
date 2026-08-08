///|
fn make_stats_store() -> TrackingStore {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Statistics Test"))
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
test "sort_doubles sorts in ascending order" {
  let values = [3.0, 1.0, 4.0, 1.5, 2.0]
  let sorted = sort_doubles(values)
  assert_eq(sorted[0], 1.0)
  assert_eq(sorted[1], 1.5)
  assert_eq(sorted[2], 2.0)
  assert_eq(sorted[3], 3.0)
  assert_eq(sorted[4], 4.0)
}

///|
test "median_doubles computes median for odd length" {
  let values = [1.0, 3.0, 2.0]
  let med = median_doubles(values)
  assert_eq(med, 2.0)
}

///|
test "median_doubles computes median for even length" {
  let values = [1.0, 2.0, 3.0, 4.0]
  let med = median_doubles(values)
  assert_eq(med, 2.5)
}

///|
test "percentile_doubles computes percentiles" {
  let values = [1.0, 2.0, 3.0, 4.0, 5.0]
  let p0 = percentile_doubles(values, 0.0)
  let p50 = percentile_doubles(values, 50.0)
  let p100 = percentile_doubles(values, 100.0)
  assert_eq(p0, 1.0)
  assert_eq(p50, 3.0)
  assert_eq(p100, 5.0)
}

///|
test "metric_summary computes all statistics" {
  let store = make_stats_store()
  match store.metric_summary("exp1", "accuracy") {
    Ok(s) => {
      assert_eq(s.count(), 3)
      assert_true(s.min_val() > 0.79 && s.min_val() < 0.81)
      assert_true(s.max_val() > 0.89 && s.max_val() < 0.91)
      assert_true(s.mean_val() > 0.84 && s.mean_val() < 0.86)
      assert_true(s.median_val() > 0.84 && s.median_val() < 0.86)
      assert_true(s.stddev_val() > 0.0)
    }
    Err(err) => fail("metric_summary failed: \{err.message()}")
  }
}

///|
test "metric_summary returns error for unknown experiment" {
  let store = make_stats_store()
  let result = store.metric_summary("nonexistent", "accuracy")
  assert_true(result is Err(_))
}

///|
test "all_metric_summaries collects all summaries" {
  let store = make_stats_store()
  match store.all_metric_summaries("exp1") {
    Ok(summaries) => {
      assert_eq(summaries.length(), 2)
      let keys = summaries.map(fn(s) { s.key() })
      assert_true(array_contains_string(keys, "accuracy"))
      assert_true(array_contains_string(keys, "loss"))
    }
    Err(err) => fail("all_metric_summaries failed: \{err.message()}")
  }
}

///|
test "metric_correlation computes correlation" {
  let store = make_stats_store()
  match store.metric_correlation("exp1", "accuracy", "loss") {
    Ok(corr) =>
      // accuracy and loss should be negatively correlated
      assert_true(corr < 0.0)
    Err(err) => fail("metric_correlation failed: \{err.message()}")
  }
}

///|
test "metric_correlation returns error for insufficient data" {
  let store = make_stats_store()
  let result = store.metric_correlation("exp1", "accuracy", "nonexistent")
  assert_true(result is Err(_))
}

///|
test "statistics_report generates report" {
  let store = make_stats_store()
  match store.statistics_report("exp1") {
    Ok(report) => {
      assert_true(report.contains("Statistics Report"))
      assert_true(report.contains("Metric Summaries"))
      assert_true(report.contains("accuracy"))
      assert_true(report.contains("loss"))
    }
    Err(err) => fail("statistics_report failed: \{err.message()}")
  }
}

///|
test "MetricSummary range and coefficient_of_variation" {
  let store = make_stats_store()
  match store.metric_summary("exp1", "accuracy") {
    Ok(s) => {
      let r = s.range()
      assert_true(r > 0.09 && r < 0.11)
      let cv = s.coefficient_of_variation()
      assert_true(cv > 0.0)
    }
    Err(err) => fail("metric_summary failed: \{err.message()}")
  }
}

///|
test "MetricSummary percentile and quartiles" {
  let store = make_stats_store()
  match store.metric_summary("exp1", "accuracy") {
    Ok(s) => {
      let p25 = s.percentile(25.0)
      let p75 = s.percentile(75.0)
      let q1 = s.q1()
      let q3 = s.q3()
      let iqr = s.iqr()
      assert_true(p25 > 0.0)
      assert_true(p75 > 0.0)
      assert_eq(q1, p25)
      assert_eq(q3, p75)
      assert_true(iqr > 0.0)
    }
    Err(err) => fail("metric_summary failed: \{err.message()}")
  }
}
