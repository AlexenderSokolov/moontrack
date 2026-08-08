///|
fn main {
  let store = @moontrack.TrackingStore::new()

  ignore(store.create_experiment("exp1", "Sample Experiment"))

  // Run 1: baseline
  ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
  ignore(store.log_param("run1", @moontrack.Param::new_float("lr", 0.01)))
  ignore(store.log_param("run1", @moontrack.Param::new_int("epochs", 10)))
  ignore(
    store.log_metric("run1", @moontrack.Metric::new("accuracy", 0.85, 1, "t1")),
  )
  ignore(store.complete_run("run1", "2026-01-01T01:00:00Z"))

  // Run 2: improved
  ignore(store.start_run("run2", "exp1", "2026-01-02T00:00:00Z"))
  ignore(store.log_param("run2", @moontrack.Param::new_float("lr", 0.001)))
  ignore(store.log_param("run2", @moontrack.Param::new_int("epochs", 50)))
  ignore(
    store.log_metric("run2", @moontrack.Metric::new("accuracy", 0.92, 1, "t1")),
  )
  ignore(store.complete_run("run2", "2026-01-02T02:00:00Z"))

  // Run 3: failed
  ignore(store.start_run("run3", "exp1", "2026-01-03T00:00:00Z"))
  ignore(store.log_param("run3", @moontrack.Param::new_float("lr", 0.5)))
  ignore(
    store.log_metric("run3", @moontrack.Metric::new("accuracy", 0.10, 1, "t1")),
  )
  ignore(store.fail_run("run3", "2026-01-03T00:15:00Z", "Diverged"))

  // Print experiment summary
  println("=== Experiment Summary ===")
  println(store.to_markdown())

  // Print JSON
  println("=== JSON Export ===")
  println(store.to_json())

  // Compare runs
  println("=== Run Comparison: run1 vs run2 ===")
  match store.compare_runs("run1", "run2") {
    Ok(cmp) =>
      for delta in cmp.deltas() {
        let status = if delta.improved() { "IMPROVED" } else { "REGRESSED" }
        println(
          "  \{delta.key()}: \{delta.baseline_value()} -> \{delta.comparison_value()} [\{status}]",
        )
      }
    Err(err) => println("Error: \{err.message()}")
  }
}
