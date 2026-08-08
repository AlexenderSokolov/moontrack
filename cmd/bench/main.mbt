///|
fn main {
  let store = @moontrack.TrackingStore::new()

  let exp_count = 20
  let runs_per_exp = 50
  let mut total_runs = 0

  for e = 0; e < exp_count; e = e + 1 {
    let exp_id = "exp_\{e}"
    ignore(store.create_experiment(exp_id, "Benchmark Experiment \{e}"))
    for r = 0; r < runs_per_exp; r = r + 1 {
      let run_id = "run_\{e}_\{r}"
      ignore(store.start_run(run_id, exp_id, "2026-01-01T00:00:00Z"))
      ignore(
        store.log_param(
          run_id,
          @moontrack.Param::new_float("lr", 0.001 * (r + 1).to_double()),
        ),
      )
      ignore(
        store.log_param(
          run_id,
          @moontrack.Param::new_int("epochs", r * 10 + 10),
        ),
      )
      ignore(
        store.log_metric(
          run_id,
          @moontrack.Metric::new(
            "accuracy",
            0.5 + 0.001 * r.to_double(),
            r,
            "t",
          ),
        ),
      )
      ignore(
        store.log_metric(
          run_id,
          @moontrack.Metric::new("loss", 1.0 - 0.001 * r.to_double(), r, "t"),
        ),
      )
      if r % 3 == 0 {
        ignore(store.fail_run(run_id, "2026-01-01T01:00:00Z", "random failure"))
      } else {
        ignore(store.complete_run(run_id, "2026-01-01T01:00:00Z"))
      }
      total_runs = total_runs + 1
    }
  }

  println("Created \{exp_count} experiments with \{total_runs} total runs")

  let filter = @moontrack.RunFilter::new().with_statuses([@moontrack.Completed])
  let sort = @moontrack.SortKey::by_metric_descending("accuracy")
  let results = store.search_runs(filter, Some(sort))
  println("Query returned \{results.length()} completed runs")

  let json = store.to_json()
  println("JSON export length: \{json.length()} chars")

  match store.compare_runs("run_0_0", "run_0_1") {
    Ok(cmp) =>
      println(
        "Compared \{cmp.baseline_id()} vs \{cmp.comparison_id()}: \{cmp.deltas().length()} deltas",
      )
    Err(err) => println("Compare error: \{err.message()}")
  }

  match store.metrics_csv("exp_0") {
    Ok(csv) => println("CSV export length: \{csv.length()} chars")
    Err(err) => println("CSV error: \{err.message()}")
  }
}
