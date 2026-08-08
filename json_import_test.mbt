///|
test "from_json imports experiments and runs" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [
    #|    {
    #|      "id": "exp1",
    #|      "name": "Test Experiment",
    #|      "description": "A test",
    #|      "tags": ["ml", "test"]
    #|    }
    #|  ],
    #|  "runs": [
    #|    {
    #|      "id": "run1",
    #|      "experiment_id": "exp1",
    #|      "status": "completed",
    #|      "start_time": "2026-01-01T00:00:00Z",
    #|      "end_time": "2026-01-01T01:00:00Z",
    #|      "error_message": "",
    #|      "tags": ["baseline"],
    #|      "parameters": [
    #|        {"key": "lr", "value": "0.01", "type": "float"},
    #|        {"key": "epochs", "value": "10", "type": "int"}
    #|      ],
    #|      "metrics": [
    #|        {"key": "accuracy", "value": 0.95, "step": 1, "timestamp": "t1", "direction": "higher_better"}
    #|      ],
    #|      "artifacts": [
    #|        {"name": "model.pt", "path": "/path/to/model.pt", "size": 1024}
    #|      ]
    #|    }
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Err(err) => fail("from_json failed: \{err.message()}")
    Ok(store) => {
      assert_eq(store.experiment_count(), 1)
      assert_eq(store.run_count(), 1)
      let run = store.get_run("run1").unwrap()
      assert_eq(run.param_count(), 2)
      assert_eq(run.metric_count(), 1)
      assert_eq(run.artifact_count(), 1)
    }
  }
}

///|
test "from_json rejects invalid JSON syntax" {
  let json = "not valid json"
  match TrackingStore::from_json(json) {
    Err(InvalidJsonSyntax(_)) => ()
    _ => fail("expected InvalidJsonSyntax error")
  }
}

///|
test "from_json rejects unsupported schema version" {
  let json =
    #|{
    #|  "schema_version": 2,
    #|  "experiments": [],
    #|  "runs": []
    #|}
  match TrackingStore::from_json(json) {
    Err(UnsupportedSchemaVersion(_)) => ()
    _ => fail("expected UnsupportedSchemaVersion error")
  }
}

///|
test "from_json rejects missing experiments field" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "runs": []
    #|}
  match TrackingStore::from_json(json) {
    Err(MissingRequiredField(path)) => assert_true(path.contains("experiments"))
    _ => fail("expected MissingRequiredField error")
  }
}

///|
test "from_json rejects missing runs field" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": []
    #|}
  match TrackingStore::from_json(json) {
    Err(MissingRequiredField(path)) => assert_true(path.contains("runs"))
    _ => fail("expected MissingRequiredField error")
  }
}

///|
test "from_json rejects duplicate experiment id" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [
    #|    {"id": "exp1", "name": "First"},
    #|    {"id": "exp1", "name": "Second"}
    #|  ],
    #|  "runs": []
    #|}
  match TrackingStore::from_json(json) {
    Err(DuplicateExperimentId(id)) => assert_eq(id, "exp1")
    _ => fail("expected DuplicateExperimentId error")
  }
}

///|
test "from_json rejects duplicate run id" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [
    #|    {"id": "exp1", "name": "Test"}
    #|  ],
    #|  "runs": [
    #|    {"id": "run1", "experiment_id": "exp1", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []},
    #|    {"id": "run1", "experiment_id": "exp1", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Err(DuplicateRunId(id)) => assert_eq(id, "run1")
    _ => fail("expected DuplicateRunId error")
  }
}

///|
test "from_json rejects run with unknown experiment" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [
    #|    {"id": "exp1", "name": "Test"}
    #|  ],
    #|  "runs": [
    #|    {"id": "run1", "experiment_id": "nonexistent", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Err(UnknownExperimentForRun(id)) => assert_eq(id, "run1")
    _ => fail("expected UnknownExperimentForRun error")
  }
}

///|
test "from_json rejects invalid run status" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [{"id": "exp1", "name": "Test"}],
    #|  "runs": [
    #|    {"id": "run1", "experiment_id": "exp1", "status": "unknown", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Err(InvalidRunStatus(s)) => assert_eq(s, "unknown")
    _ => fail("expected InvalidRunStatus error")
  }
}

///|
test "from_json rejects invalid param type" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [{"id": "exp1", "name": "Test"}],
    #|  "runs": [
    #|    {"id": "run1", "experiment_id": "exp1", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [{"key": "x", "value": "1", "type": "invalid"}], "metrics": [], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Err(InvalidParamType(s)) => assert_eq(s, "invalid")
    _ => fail("expected InvalidParamType error")
  }
}

///|
test "from_json handles empty experiments and runs" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [],
    #|  "runs": []
    #|}
  match TrackingStore::from_json(json) {
    Ok(store) => {
      assert_eq(store.experiment_count(), 0)
      assert_eq(store.run_count(), 0)
    }
    Err(err) => fail("from_json failed: \{err.message()}")
  }
}

///|
test "from_json imports multiple experiments with multiple runs each" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [
    #|    {"id": "exp1", "name": "First"},
    #|    {"id": "exp2", "name": "Second"}
    #|  ],
    #|  "runs": [
    #|    {"id": "r1a", "experiment_id": "exp1", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []},
    #|    {"id": "r1b", "experiment_id": "exp1", "status": "failed", "start_time": "t2", "end_time": "", "error_message": "err", "tags": [], "parameters": [], "metrics": [], "artifacts": []},
    #|    {"id": "r2a", "experiment_id": "exp2", "status": "running", "start_time": "t3", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Ok(store) => {
      assert_eq(store.experiment_count(), 2)
      assert_eq(store.run_count(), 3)
      assert_eq(store.runs_for_experiment("exp1").length(), 2)
      assert_eq(store.runs_for_experiment("exp2").length(), 1)
    }
    Err(err) => fail("from_json failed: \{err.message()}")
  }
}

///|
test "from_json imports metric direction correctly" {
  let json =
    #|{
    #|  "schema_version": 1,
    #|  "experiments": [{"id": "exp1", "name": "Test"}],
    #|  "runs": [
    #|    {"id": "run1", "experiment_id": "exp1", "status": "completed", "start_time": "t1", "end_time": "", "error_message": "", "tags": [], "parameters": [], "metrics": [{"key": "acc", "value": 0.9, "step": 1, "timestamp": "t1", "direction": "higher_better"}], "artifacts": []}
    #|  ]
    #|}
  match TrackingStore::from_json(json) {
    Ok(store) => {
      let run = store.get_run("run1").unwrap()
      match run.latest_metric("acc") {
        Some(m) => assert_true(m.direction() == HigherBetter)
        None => fail("metric not found")
      }
    }
    Err(err) => fail("from_json failed: \{err.message()}")
  }
}

///|
test "JsonImportError::message returns readable diagnostics" {
  let err = JsonImportError::InvalidJsonSyntax("bad json")
  let msg = JsonImportError::message(err)
  assert_true(msg.contains("invalid JSON syntax"))
}
