///|
fn has_issue_code(issues : Array[ValidationIssue], code : String) -> Bool {
  for issue in issues {
    if issue.code() == code {
      return true
    }
  }
  false
}

///|
fn make_valid_store() -> TrackingStore {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "My Experiment"))
  ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
  ignore(store.log_param("run1", Param::new_float("lr", 0.01)))
  ignore(store.log_metric("run1", Metric::new("acc", 0.95, 1, "t1")))
  ignore(
    store.log_artifact("run1", Artifact::new("model.pt", "/out/model.pt", 100)),
  )
  ignore(
    store.set_reproducibility(
      "run1",
      ReproducibilityInfo::new("v1", "python train.py").with_random_seed(42),
    ),
  )
  store
}

///|
test "validate returns no errors for a well-formed store" {
  let store = make_valid_store()
  let result = store.validate()
  assert_eq(result.error_count(), 0)
  assert_true(result.is_valid())
}

///|
test "validate warns about runs with no metrics" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  let result = store.validate()
  assert_true(result.warning_count() > 0)
  assert_true(has_issue_code(result.issues(), "run_has_no_metrics"))
}

///|
test "validate warns about runs with no parameters" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.log_metric("run1", Metric::new("acc", 0.9, 1, "t1")))
  let result = store.validate()
  assert_true(has_issue_code(result.issues(), "run_has_no_params"))
}

///|
test "validate warns about runs with no reproducibility" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  ignore(store.log_param("run1", Param::new_int("epochs", 10)))
  ignore(store.log_metric("run1", Metric::new("acc", 0.9, 1, "t1")))
  let result = store.validate()
  assert_true(has_issue_code(result.issues(), "run_has_no_reproducibility"))
}

///|
test "validate detects empty artifact path" {
  let store = make_valid_store()
  // Add an artifact with empty path
  ignore(store.log_artifact("run1", Artifact::new("bad", "", 10)))
  let result = store.validate()
  assert_true(!result.is_valid())
  assert_true(result.error_count() > 0)
  assert_true(has_issue_code(result.issues(), "empty_artifact_path"))
}

///|
test "validate detects negative artifact size" {
  let store = make_valid_store()
  ignore(store.log_artifact("run1", Artifact::new("bad", "/path", -1)))
  let result = store.validate()
  assert_true(!result.is_valid())
  assert_true(has_issue_code(result.issues(), "negative_artifact_size"))
}

///|
test "ValidationResult summary contains status" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", "Test"))
  ignore(store.start_run("run1", "exp1", "t1"))
  let result = store.validate()
  let s = result.summary()
  assert_true(s.contains("Validation Result"))
  assert_true(s.contains("Status:"))
}

///|
test "ValidationIssue can be built and queried" {
  let issue = ValidationIssue::new(Error, "test_code", "test message")
  assert_eq(issue.code(), "test_code")
  assert_true(issue.severity() == Error)
  assert_eq(issue.message(), "test message")
  assert_true(issue.run_id() is None)
  assert_true(issue.experiment_id() is None)
  let with_run = issue.with_run_id("run1")
  match with_run.run_id() {
    Some(id) => assert_eq(id, "run1")
    None => fail("run_id should be set")
  }
}

///|
test "validate warns about empty experiment name" {
  let store = TrackingStore::new()
  ignore(store.create_experiment("exp1", ""))
  let result = store.validate()
  assert_true(has_issue_code(result.issues(), "empty_experiment_name"))
}

///|
test "count_by_severity returns correct counts" {
  let result = ValidationResult::new()
  result.add_issue(ValidationIssue::new(Error, "e1", "error 1"))
  result.add_issue(ValidationIssue::new(Error, "e2", "error 2"))
  result.add_issue(ValidationIssue::new(Warning, "w1", "warning 1"))
  assert_eq(result.count_by_severity(Error), 2)
  assert_eq(result.count_by_severity(Warning), 1)
  assert_eq(result.error_count(), 2)
  assert_eq(result.warning_count(), 1)
  assert_eq(result.issue_count(), 3)
  assert_true(!result.is_valid())
}

///|
test "ValidationResult is valid when no issues" {
  let result = ValidationResult::new()
  assert_true(result.is_valid())
  assert_eq(result.error_count(), 0)
  assert_eq(result.warning_count(), 0)
  assert_eq(result.issue_count(), 0)
}
