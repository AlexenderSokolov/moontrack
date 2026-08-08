///|
test "create_experiment creates and stores experiment" {
  let store = TrackingStore::new()
  let result = store.create_experiment("exp1", "My Experiment")
  assert_true(result is Ok(_))
  assert_eq(store.experiment_count(), 1)
}

///|
test "create_experiment rejects duplicate id" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "First")
  let result = store.create_experiment("exp1", "Second")
  assert_true(result is Err(_))
}

///|
test "get_experiment returns experiment by id" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "My Experiment")
  match store.get_experiment("exp1") {
    Ok(exp) => assert_eq(exp.name(), "My Experiment")
    Err(_) => fail("experiment not found")
  }
}

///|
test "get_experiment returns error for unknown id" {
  let store = TrackingStore::new()
  let result = store.get_experiment("nonexistent")
  assert_true(result is Err(_))
}

///|
test "start_run creates a running run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let result = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  assert_true(result is Ok(_))
  match result {
    Ok(run) => assert_true(run.status() == Running)
    Err(_) => fail("start_run failed")
  }
}

///|
test "start_run rejects duplicate run id" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let result = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  assert_true(result is Err(_))
}

///|
test "start_run rejects unknown experiment" {
  let store = TrackingStore::new()
  let result = store.start_run("run1", "nonexistent", "2026-01-01T00:00:00Z")
  assert_true(result is Err(_))
}

///|
test "complete_run transitions running to completed" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let result = store.complete_run("run1", "2026-01-01T01:00:00Z")
  assert_true(result is Ok(_))
  match result {
    Ok(run) => assert_true(run.status() == Completed)
    Err(_) => fail("complete_run failed")
  }
}

///|
test "fail_run transitions running to failed" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let result = store.fail_run("run1", "2026-01-01T01:00:00Z", "OOM")
  assert_true(result is Ok(_))
  match result {
    Ok(run) => {
      assert_true(run.status() == Failed)
      assert_eq(run.error_message(), "OOM")
    }
    Err(_) => fail("fail_run failed")
  }
}

///|
test "kill_run transitions running to killed" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let result = store.kill_run("run1", "2026-01-01T01:00:00Z")
  assert_true(result is Ok(_))
  match result {
    Ok(run) => assert_true(run.status() == Killed)
    Err(_) => fail("kill_run failed")
  }
}

///|
test "complete_run rejects already completed run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.complete_run("run1", "2026-01-01T01:00:00Z")
  let result = store.complete_run("run1", "2026-01-01T02:00:00Z")
  assert_true(result is Err(_))
}

///|
test "fail_run can retry from failed to running" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.fail_run("run1", "2026-01-01T01:00:00Z", "crash")
  let result = store.start_run("run1", "exp1", "2026-01-01T02:00:00Z")
  assert_true(result is Err(_)) // duplicate run id
}

///|
test "log_param adds parameter to run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_param("run1", Param::new_int("epochs", 100))
  let run = store.get_run("run1").unwrap()
  assert_eq(run.param_count(), 1)
  match run.find_param("epochs") {
    Some(p) => assert_eq(p.value(), "100")
    None => fail("param not found")
  }
}

///|
test "log_metric adds metric to run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric(
    "run1",
    Metric::new("accuracy", 0.95, 1, "2026-01-01T01:00:00Z"),
  )
  let run = store.get_run("run1").unwrap()
  assert_eq(run.metric_count(), 1)
  match run.latest_metric("accuracy") {
    Some(m) => assert_eq(m.value(), 0.95)
    None => fail("metric not found")
  }
}

///|
test "log_artifact adds artifact to run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_artifact(
    "run1",
    Artifact::new("model.pt", "/path/to/model.pt", 1024),
  )
  let run = store.get_run("run1").unwrap()
  assert_eq(run.artifact_count(), 1)
}

///|
test "set_reproducibility sets reproducibility info on run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let info = ReproducibilityInfo::new("abc123", "python train.py").with_random_seed(
    42,
  )
  let _ = store.set_reproducibility("run1", info)
  let run = store.get_run("run1").unwrap()
  match run.reproducibility() {
    Some(r) => assert_eq(r.code_version(), "abc123")
    None => fail("reproducibility not set")
  }
}

///|
test "add_note adds note to run" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.add_note("run1", "First run with new config")
  let run = store.get_run("run1").unwrap()
  assert_eq(run.notes().length(), 1)
}

///|
test "runs_for_experiment returns only matching runs" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test 1")
  let _ = store.create_experiment("exp2", "Test 2")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.start_run("run2", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.start_run("run3", "exp2", "2026-01-01T00:00:00Z")
  assert_eq(store.runs_for_experiment("exp1").length(), 2)
  assert_eq(store.runs_for_experiment("exp2").length(), 1)
}

///|
test "list_experiments returns all experiment ids" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test 1")
  let _ = store.create_experiment("exp2", "Test 2")
  assert_eq(store.list_experiments().length(), 2)
}

///|
test "list_runs returns all run ids" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.start_run("run2", "exp1", "2026-01-01T00:00:00Z")
  assert_eq(store.list_runs().length(), 2)
}

///|
test "Run::latest_metric returns highest step value" {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "Test")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_metric("run1", Metric::new("loss", 1.0, 1, "t1"))
  let _ = store.log_metric("run1", Metric::new("loss", 0.5, 2, "t2"))
  let _ = store.log_metric("run1", Metric::new("loss", 0.3, 3, "t3"))
  let run = store.get_run("run1").unwrap()
  match run.latest_metric("loss") {
    Some(m) => assert_eq(m.value(), 0.3)
    None => fail("metric not found")
  }
}

///|
test "TrackingError::message returns readable diagnostics" {
  let err = @moontrack.DuplicateExperiment("exp1")
  let msg = TrackingError::message(err)
  assert_true(msg.contains("duplicate experiment"))
}

///|
test "RunStatus::from_string parses valid statuses" {
  assert_true(RunStatus::from_string("created") == Some(Created))
  assert_true(RunStatus::from_string("running") == Some(Running))
  assert_true(RunStatus::from_string("completed") == Some(Completed))
  assert_true(RunStatus::from_string("failed") == Some(Failed))
  assert_true(RunStatus::from_string("killed") == Some(Killed))
}

///|
test "RunStatus::from_string returns None for invalid" {
  assert_true(RunStatus::from_string("unknown") == None)
}

///|
test "ParamType::from_string parses valid types" {
  assert_true(ParamType::from_string("int") == Some(IntParam))
  assert_true(ParamType::from_string("float") == Some(FloatParam))
  assert_true(ParamType::from_string("bool") == Some(BoolParam))
  assert_true(ParamType::from_string("string") == Some(StringParam))
}
