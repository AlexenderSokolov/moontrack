///|
fn main {
  let store = @moontrack.TrackingStore::new()

  ignore(
    store.create_experiment("mnist_baseline", "MNIST Classification Baseline"),
  )

  // Run 1: baseline
  ignore(store.start_run("run_001", "mnist_baseline", "2026-01-15T09:00:00Z"))
  ignore(
    store.log_param(
      "run_001",
      @moontrack.Param::new_float("learning_rate", 0.001),
    ),
  )
  ignore(
    store.log_param("run_001", @moontrack.Param::new_int("batch_size", 32)),
  )
  ignore(store.log_param("run_001", @moontrack.Param::new_int("epochs", 10)))
  ignore(
    store.log_metric(
      "run_001",
      @moontrack.Metric::new("accuracy", 0.92, 1, "2026-01-15T09:30:00Z").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(
    store.log_metric(
      "run_001",
      @moontrack.Metric::new("loss", 0.28, 1, "2026-01-15T09:30:00Z").with_direction(
        @moontrack.LowerBetter,
      ),
    ),
  )
  ignore(
    store.log_artifact(
      "run_001",
      @moontrack.Artifact::new("model.pt", "outputs/run_001/model.pt", 4567890),
    ),
  )
  ignore(
    store.set_reproducibility(
      "run_001",
      @moontrack.ReproducibilityInfo::new(
        "a1b2c3d", "python train.py --lr 0.001",
      ).with_random_seed(42),
    ),
  )
  ignore(store.complete_run("run_001", "2026-01-15T09:30:00Z"))

  // Run 2: improved
  ignore(store.start_run("run_002", "mnist_baseline", "2026-01-15T10:00:00Z"))
  ignore(
    store.log_param(
      "run_002",
      @moontrack.Param::new_float("learning_rate", 0.0005),
    ),
  )
  ignore(
    store.log_param("run_002", @moontrack.Param::new_int("batch_size", 64)),
  )
  ignore(store.log_param("run_002", @moontrack.Param::new_int("epochs", 20)))
  ignore(
    store.log_metric(
      "run_002",
      @moontrack.Metric::new("accuracy", 0.95, 1, "2026-01-15T10:45:00Z").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(
    store.log_metric(
      "run_002",
      @moontrack.Metric::new("loss", 0.15, 1, "2026-01-15T10:45:00Z").with_direction(
        @moontrack.LowerBetter,
      ),
    ),
  )
  ignore(
    store.log_artifact(
      "run_002",
      @moontrack.Artifact::new("model.pt", "outputs/run_002/model.pt", 4567890),
    ),
  )
  ignore(
    store.set_reproducibility(
      "run_002",
      @moontrack.ReproducibilityInfo::new(
        "a1b2c3d", "python train.py --lr 0.0005",
      ).with_random_seed(42),
    ),
  )
  ignore(store.complete_run("run_002", "2026-01-15T10:45:00Z"))

  // Run 3: failed
  ignore(store.start_run("run_003", "mnist_baseline", "2026-01-15T11:00:00Z"))
  ignore(
    store.log_param(
      "run_003",
      @moontrack.Param::new_float("learning_rate", 0.1),
    ),
  )
  ignore(
    store.log_param("run_003", @moontrack.Param::new_int("batch_size", 128)),
  )
  ignore(
    store.log_metric(
      "run_003",
      @moontrack.Metric::new("accuracy", 0.10, 1, "2026-01-15T11:15:00Z").with_direction(
        @moontrack.HigherBetter,
      ),
    ),
  )
  ignore(store.fail_run("run_003", "2026-01-15T11:15:00Z", "Training diverged"))

  // Print Markdown report
  println(store.to_markdown())

  // Print JSON export
  println("=== JSON Export ===")
  println(store.to_json())

  // Compare runs
  println("=== Run Comparison: run_001 vs run_002 ===")
  match store.compare_runs("run_001", "run_002") {
    Ok(cmp) => {
      println("Baseline: \{cmp.baseline_id()}")
      println("Comparison: \{cmp.comparison_id()}")
      for delta in cmp.deltas() {
        let status = if delta.improved() { "IMPROVED" } else { "REGRESSED" }
        println(
          "  \{delta.key()}: \{delta.baseline_value()} -> \{delta.comparison_value()} [\{status}]",
        )
      }
    }
    Err(err) => println("Error: \{err.message()}")
  }

  // Query: top runs by accuracy
  println("=== Top Runs by Accuracy ===")
  let filter = @moontrack.RunFilter::new().with_statuses([@moontrack.Completed])
  let sort = @moontrack.SortKey::by_metric_descending("accuracy")
  let results = store.search_runs(filter, Some(sort))
  for run in results {
    let acc = match run.latest_metric("accuracy") {
      Some(m) => m.value()
      None => 0.0
    }
    println("  \{run.id()}: accuracy=\{acc}")
  }

  // Export metrics CSV
  println("=== Metrics CSV ===")
  match store.metrics_csv("mnist_baseline") {
    Ok(csv) => println(csv)
    Err(err) => println("Error: \{err.message()}")
  }
}
