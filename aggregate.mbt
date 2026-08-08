///|
/// Aggregated metric statistics across multiple runs.
pub struct MetricStats {
  priv key : String
  priv count : Int
  priv min_val : Double
  priv max_val : Double
  priv mean_val : Double
  priv values : Array[Double]
} derive(Debug)

///|
/// Return the metric key.
pub fn MetricStats::key(self : MetricStats) -> String {
  self.key
}

///|
/// Return the number of runs that have this metric.
pub fn MetricStats::count(self : MetricStats) -> Int {
  self.count
}

///|
/// Return the minimum metric value.
pub fn MetricStats::min_val(self : MetricStats) -> Double {
  self.min_val
}

///|
/// Return the maximum metric value.
pub fn MetricStats::max_val(self : MetricStats) -> Double {
  self.max_val
}

///|
/// Return the mean metric value.
pub fn MetricStats::mean_val(self : MetricStats) -> Double {
  self.mean_val
}

///|
/// Return a detached copy of all metric values.
pub fn MetricStats::values(self : MetricStats) -> Array[Double] {
  self.values.copy()
}

///|
/// Return the range (max - min) of metric values.
pub fn MetricStats::range(self : MetricStats) -> Double {
  self.max_val - self.min_val
}

///|
/// Return the variance of metric values.
pub fn MetricStats::variance(self : MetricStats) -> Double {
  if self.count < 2 {
    return 0.0
  }
  let mut sum_sq = 0.0
  for v in self.values {
    let diff = v - self.mean_val
    sum_sq += diff * diff
  }
  sum_sq / (self.count - 1).to_double()
}

///|
/// Return the standard deviation of metric values.
pub fn MetricStats::std_dev(self : MetricStats) -> Double {
  self.variance().sqrt()
}

///|
/// Aggregate metric statistics for a specific metric key across all runs
/// in an experiment.
///
/// Only the latest metric value for each run is considered. Runs without
/// the specified metric are skipped.
pub fn TrackingStore::aggregate_metric(
  self : TrackingStore,
  experiment_id : String,
  metric_key : String,
) -> Result[MetricStats, TrackingError] {
  // Verify experiment exists
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  let values : Array[Double] = []
  for run in runs {
    match run.latest_metric(metric_key) {
      Some(m) => values.push(m.value())
      None => ()
    }
  }
  if values.is_empty() {
    return Err(RunNotFound(metric_key))
  }
  let mut min_v = values[0]
  let mut max_v = values[0]
  let mut sum = 0.0
  for v in values {
    if v < min_v {
      min_v = v
    }
    if v > max_v {
      max_v = v
    }
    sum += v
  }
  let count = values.length()
  let mean = sum / count.to_double()
  Ok({
    key: metric_key,
    count,
    min_val: min_v,
    max_val: max_v,
    mean_val: mean,
    values,
  })
}

///|
/// Aggregate metric statistics for all metric keys across all runs in an
/// experiment.
///
/// Returns a map from metric key to `MetricStats`. Only the latest metric
/// value for each run is considered.
pub fn TrackingStore::aggregate_all_metrics(
  self : TrackingStore,
  experiment_id : String,
) -> Result[Array[MetricStats], TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  // Collect all unique metric keys
  let all_keys : Array[String] = []
  for run in runs {
    for m in run.metrics() {
      if !array_contains_string(all_keys, m.key()) {
        all_keys.push(m.key())
      }
    }
  }
  // Aggregate each key
  let stats : Array[MetricStats] = []
  for key in all_keys {
    match self.aggregate_metric(experiment_id, key) {
      Ok(s) => stats.push(s)
      Err(_) => ()
    }
  }
  Ok(stats)
}

///|
/// Find the best run in an experiment by a specific metric.
///
/// "Best" is determined by the metric direction: for `HigherBetter`, the
/// run with the highest metric value; for `LowerBetter`, the run with the
/// lowest metric value. If direction is `None`, the run with the highest
/// value is returned.
pub fn TrackingStore::best_run(
  self : TrackingStore,
  experiment_id : String,
  metric_key : String,
) -> Result[Run, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  if runs.is_empty() {
    return Err(RunNotFound(experiment_id))
  }
  // Determine direction from the first run that has this metric
  let mut direction : MetricDirection = None_
  for run in runs {
    match run.latest_metric(metric_key) {
      Some(m) => {
        direction = m.direction()
        break
      }
      None => ()
    }
  }
  // Find the best run
  let mut best : Run? = None
  let mut best_val = 0.0
  for run in runs {
    match run.latest_metric(metric_key) {
      Some(m) =>
        match best {
          None => {
            best = Some(run)
            best_val = m.value()
          }
          Some(_) =>
            match direction {
              LowerBetter =>
                if m.value() < best_val {
                  best = Some(run)
                  best_val = m.value()
                }
              _ =>
                if m.value() > best_val {
                  best = Some(run)
                  best_val = m.value()
                }
            }
        }
      None => ()
    }
  }
  match best {
    Some(r) => Ok(r)
    None => Err(RunNotFound(metric_key))
  }
}
