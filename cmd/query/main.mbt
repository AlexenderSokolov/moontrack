///|
fn main {
  let store = @moontrack.TrackingStore::new()
  ignore(store.create_experiment("exp1", "Query Demo"))

  // Run 1
  ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
  ignore(store.log_param("run1", @moontrack.Param::new_float("lr", 0.01)))
  ignore(store.log_param("run1", @moontrack.Param::new_int("epochs", 10)))
  ignore(
    store.log_metric(
      "run1",
      @moontrack.Metric::new("accuracy", 0.80, 1, "t1").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.complete_run("run1", "2026-01-01T01:00:00Z"))

  // Run 2
  ignore(store.start_run("run2", "exp1", "2026-01-02T00:00:00Z"))
  ignore(store.log_param("run2", @moontrack.Param::new_float("lr", 0.001)))
  ignore(store.log_param("run2", @moontrack.Param::new_int("epochs", 50)))
  ignore(
    store.log_metric(
      "run2",
      @moontrack.Metric::new("accuracy", 0.92, 1, "t1").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.complete_run("run2", "2026-01-02T02:00:00Z"))

  // Run 3
  ignore(store.start_run("run3", "exp1", "2026-01-03T00:00:00Z"))
  ignore(store.log_param("run3", @moontrack.Param::new_float("lr", 0.0005)))
  ignore(store.log_param("run3", @moontrack.Param::new_int("epochs", 100)))
  ignore(
    store.log_metric(
      "run3",
      @moontrack.Metric::new("accuracy", 0.95, 1, "t1").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.complete_run("run3", "2026-01-03T03:00:00Z"))

  // Run 4 (failed)
  ignore(store.start_run("run4", "exp1", "2026-01-04T00:00:00Z"))
  ignore(store.log_param("run4", @moontrack.Param::new_float("lr", 0.1)))
  ignore(
    store.log_metric(
      "run4",
      @moontrack.Metric::new("accuracy", 0.10, 1, "t1").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.fail_run("run4", "2026-01-04T00:15:00Z", "Diverged"))

  // Run 5
  ignore(store.start_run("run5", "exp1", "2026-01-05T00:00:00Z"))
  ignore(store.log_param("run5", @moontrack.Param::new_float("lr", 0.005)))
  ignore(store.log_param("run5", @moontrack.Param::new_int("epochs", 30)))
  ignore(
    store.log_metric(
      "run5",
      @moontrack.Metric::new("accuracy", 0.88, 1, "t1").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.complete_run("run5", "2026-01-05T01:30:00Z"))

  // Query 1: All completed runs sorted by accuracy descending
  println("=== Top Completed Runs by Accuracy ===")
  let filter1 = @moontrack.RunFilter::new().with_statuses([@moontrack.Completed])
  let sort1 = @moontrack.SortKey::by_metric_descending("accuracy")
  let results1 = store.search_runs(filter1, Some(sort1))
  for run in results1 {
    let acc = match run.latest_metric("accuracy") {
      Some(m) => m.value()
      None => 0.0
    }
    println("  \{run.id()}: accuracy=\{acc}")
  }

  // Query 2: Runs with accuracy >= 0.90
  println("=== Runs with accuracy >= 0.90 ===")
  let filter2 = @moontrack.RunFilter::new().with_metric_min("accuracy", 0.90)
  let results2 = store.search_runs(filter2, None)
  for run in results2 {
    let acc = match run.latest_metric("accuracy") {
      Some(m) => m.value()
      None => 0.0
    }
    println("  \{run.id()}: accuracy=\{acc}")
  }

  // Query 3: Failed runs
  println("=== Failed Runs ===")
  let filter3 = @moontrack.RunFilter::new().with_statuses([@moontrack.Failed])
  let results3 = store.search_runs(filter3, None)
  for run in results3 {
    println("  \{run.id()}: error=\{run.error_message()}")
  }

  // Export CSV
  println("=== Metrics CSV ===")
  match store.metrics_csv("exp1") {
    Ok(csv) => println(csv)
    Err(err) => println("Error: \{err.message()}")
  }
}
