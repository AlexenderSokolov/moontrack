///|
fn make_export_store() -> TrackingStore {
  let store = TrackingStore::new()
  let _ = store.create_experiment("exp1", "MNIST Classification")
  let _ = store.start_run("run1", "exp1", "2026-01-01T00:00:00Z")
  let _ = store.log_param("run1", Param::new_float("lr", 0.01))
  let _ = store.log_param("run1", Param::new_int("epochs", 10))
  let _ = store.log_metric(
    "run1",
    Metric::new("accuracy", 0.95, 1, "2026-01-01T01:00:00Z"),
  )
  let _ = store.log_artifact(
    "run1",
    Artifact::new("model.pt", "/path/to/model.pt", 1024),
  )
  let _ = store.complete_run("run1", "2026-01-01T01:00:00Z")
  store
}

///|
test "to_markdown generates report with experiment name" {
  let store = make_export_store()
  let md = store.to_markdown()
  assert_true(md.contains("MNIST Classification"))
  assert_true(md.contains("run1"))
}

///|
test "to_markdown handles empty store" {
  let store = TrackingStore::new()
  let md = store.to_markdown()
  assert_true(md.contains("No experiments"))
}

///|
test "run_markdown generates detailed run report" {
  let store = make_export_store()
  match store.run_markdown("run1") {
    Ok(md) => {
      assert_true(md.contains("run1"))
      assert_true(md.contains("lr"))
      assert_true(md.contains("accuracy"))
      assert_true(md.contains("model.pt"))
    }
    Err(_) => fail("run_markdown failed")
  }
}

///|
test "run_markdown returns error for unknown run" {
  let store = make_export_store()
  let result = store.run_markdown("nonexistent")
  assert_true(result is Err(_))
}

///|
test "to_json generates valid JSON with schema_version" {
  let store = make_export_store()
  let json = store.to_json()
  assert_true(json.contains("schema_version"))
  assert_true(json.contains("exp1"))
  assert_true(json.contains("run1"))
}

///|
test "metrics_csv generates CSV with header and data" {
  let store = make_export_store()
  match store.metrics_csv("exp1") {
    Ok(csv) => {
      assert_true(csv.contains("run_id,status"))
      assert_true(csv.contains("accuracy"))
      assert_true(csv.contains("run1"))
      assert_true(csv.contains("completed"))
    }
    Err(_) => fail("metrics_csv failed")
  }
}

///|
test "metrics_csv returns error for unknown experiment" {
  let store = make_export_store()
  let result = store.metrics_csv("nonexistent")
  assert_true(result is Err(_))
}

///|
test "to_markdown includes run table with params and metrics counts" {
  let store = make_export_store()
  let md = store.to_markdown()
  assert_true(md.contains("Params"))
  assert_true(md.contains("Metrics"))
  assert_true(md.contains("Artifacts"))
}
