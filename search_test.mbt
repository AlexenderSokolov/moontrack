///|
fn make_search_store() -> TrackingStore {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "MNIST Classification"))
  ignore(store.create_experiment("exp2", "CIFAR-10 Classification"))
  ignore(store.create_experiment("exp3", "Sentiment Analysis"))
  store
}

///|
test "search_experiments with name_contains" {
  let store = make_search_store()
  let filter = ExperimentSearchFilter::new().with_name_contains(
    "Classification",
  )
  let results = store.search_experiments(filter)
  assert_eq(results.length(), 2)
}

///|
test "search_experiments with name_contains no match" {
  let store = make_search_store()
  let filter = ExperimentSearchFilter::new().with_name_contains("ImageNet")
  let results = store.search_experiments(filter)
  assert_eq(results.length(), 0)
}

///|
test "search_experiments with empty filter returns all" {
  let store = make_search_store()
  let filter = ExperimentSearchFilter::new()
  let results = store.search_experiments(filter)
  assert_eq(results.length(), 3)
}

///|
test "experiments_by_tag returns matching experiments" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "First")
  let _ = store.create_experiment("exp2", "Second")
  let _ = store.create_experiment("exp3", "Third")
  let _ = store.add_experiment_tag("exp1", "baseline")
  let _ = store.add_experiment_tag("exp3", "baseline")
  let results = store.experiments_by_tag("baseline")
  assert_eq(results.length(), 2)
}

///|
test "experiments_by_name returns matching experiments" {
  let store = make_search_store()
  let results = store.experiments_by_name("MNIST")
  assert_eq(results.length(), 1)
  assert_eq(results[0].id(), "exp1")
}

///|
test "run_status_summary counts runs by status" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.complete_run("run1", "t2"))
  ignore(store.start_run("run2", "exp1", "t1"))
  ignore(store.fail_run("run2", "t2", "error"))
  ignore(store.start_run("run3", "exp1", "t1"))
  let summary = store.run_status_summary()
  let completed_count = match summary.get("completed") {
    None => 0
    Some(c) => c
  }
  let failed_count = match summary.get("failed") {
    None => 0
    Some(c) => c
  }
  let running_count = match summary.get("running") {
    None => 0
    Some(c) => c
  }
  assert_eq(completed_count, 1)
  assert_eq(failed_count, 1)
  assert_eq(running_count, 1)
}

///|
test "summary generates human-readable store summary" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.complete_run("run1", "t2"))
  let summary = store.summary()
  assert_true(summary.contains("MoonTrack Store Summary"))
  assert_true(summary.contains("Experiments: 1"))
  assert_true(summary.contains("Runs: 1"))
}

///|
test "total_param_count counts all parameters across runs" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.log_param("run1", Param::new_int("a", 1)))
  ignore(store.log_param("run1", Param::new_int("b", 2)))
  ignore(store.start_run("run2", "exp1", "t1"))
  ignore(store.log_param("run2", Param::new_int("c", 3)))
  assert_eq(store.total_param_count(), 3)
}

///|
test "total_metric_count counts all metrics across runs" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.log_metric("run1", Metric::new("acc", 0.9, 1, "t")))
  ignore(store.log_metric("run1", Metric::new("loss", 0.1, 1, "t")))
  assert_eq(store.total_metric_count(), 2)
}

///|
test "total_artifact_count counts all artifacts across runs" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.log_artifact("run1", Artifact::new("model.pt", "/p", 100)))
  assert_eq(store.total_artifact_count(), 1)
}

///|
test "tag_summary counts experiments by tag" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "First"))
  ignore(store.create_experiment("exp2", "Second"))
  ignore(store.add_experiment_tag("exp1", "baseline"))
  ignore(store.add_experiment_tag("exp2", "baseline"))
  let summary = store.tag_summary()
  let baseline_count = match summary.get("baseline") {
    None => 0
    Some(c) => c
  }
  assert_eq(baseline_count, 2)
}
