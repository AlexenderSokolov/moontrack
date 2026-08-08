///|
fn make_enhanced_store() -> TrackingStore {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test Experiment"))
  // run1
  ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
  ignore(store.log_param("run1", Param::new_float("lr", 0.01)))
  ignore(store.log_param("run1", Param::new_int("epochs", 10)))
  ignore(store.log_metric("run1", Metric::new("accuracy", 0.85, 1, "t1")))
  ignore(store.complete_run("run1", "2026-01-01T01:00:00Z"))
  // run2
  ignore(store.start_run("run2", "exp1", "2026-01-02T00:00:00Z"))
  ignore(store.log_param("run2", Param::new_float("lr", 0.001)))
  ignore(store.log_param("run2", Param::new_int("epochs", 50)))
  ignore(store.log_metric("run2", Metric::new("accuracy", 0.92, 1, "t1")))
  ignore(store.complete_run("run2", "2026-01-02T02:00:00Z"))
  store
}

///|
test "detailed_csv includes parameters and metrics columns" {
  let store = make_enhanced_store()
  match store.detailed_csv("exp1") {
    Ok(csv) => {
      assert_true(csv.contains("run_id,status,start_time,end_time"))
      assert_true(csv.contains("param_lr"))
      assert_true(csv.contains("param_epochs"))
      assert_true(csv.contains("metric_accuracy"))
      assert_true(csv.contains("run1,completed"))
      assert_true(csv.contains("run2,completed"))
    }
    Err(err) => fail("detailed_csv failed: \{err.message()}")
  }
}

///|
test "detailed_csv returns error for unknown experiment" {
  let store = make_enhanced_store()
  let result = store.detailed_csv("nonexistent")
  assert_true(result is Err(_))
}

///|
test "comparison_report generates multi-experiment markdown" {
  let store = make_enhanced_store()
  let report = store.comparison_report("accuracy")
  assert_true(report.contains("Multi-Experiment Comparison Report"))
  assert_true(report.contains("Test Experiment"))
  assert_true(report.contains("Best run"))
}

///|
test "comparison_report handles empty store" {
  let store = TrackingStore::new()
  let report = store.comparison_report("accuracy")
  assert_true(report.contains("No experiments recorded"))
}

///|
test "experiments_table_markdown generates summary table" {
  let store = make_enhanced_store()
  let md = store.experiments_table_markdown()
  assert_true(md.contains("Experiments Summary"))
  assert_true(md.contains("exp1"))
  assert_true(md.contains("Test Experiment"))
}

///|
test "lineage_tree_markdown generates nested list" {
  let store = make_enhanced_store()
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("run2", "run1"))
  match store.lineage_tree_markdown(lineage, "exp1") {
    Ok(md) => {
      assert_true(md.contains("Run Lineage Tree"))
      assert_true(md.contains("run1"))
      assert_true(md.contains("run2"))
    }
    Err(err) => fail("lineage_tree_markdown failed: \{err.message()}")
  }
}

///|
test "lineage_json generates JSON tree representation" {
  let store = make_enhanced_store()
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("run2", "run1"))
  match store.lineage_json(lineage, "exp1") {
    Ok(json) => {
      assert_true(json.contains("experiment_id"))
      assert_true(json.contains("lineage"))
      assert_true(json.contains("run_id"))
      assert_true(json.contains("children"))
    }
    Err(err) => fail("lineage_json failed: \{err.message()}")
  }
}

///|
test "detailed_csv handles experiment with no runs" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("empty_exp", "Empty"))
  match store.detailed_csv("empty_exp") {
    Ok(csv) => assert_true(csv.contains("run_id,status"))
    Err(err) => fail("detailed_csv failed: \{err.message()}")
  }
}
