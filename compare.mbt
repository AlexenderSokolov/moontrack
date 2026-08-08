///|
/// The result of comparing a run against a baseline run.
///
/// For each metric key present in both runs, a `MetricDelta` is computed.
/// Metrics only in the baseline are noted as removed; metrics only in the
/// comparison run are noted as added.
pub struct RunComparison {
  priv baseline_id : String
  priv comparison_id : String
  priv deltas : Array[MetricDelta]
  priv added_keys : Array[String]
  priv removed_keys : Array[String]
} derive(Debug)

///|
/// The difference between a metric value in two runs.
pub struct MetricDelta {
  priv key : String
  priv baseline_value : Double
  priv comparison_value : Double
  priv delta : Double
  priv percent_change : Double
  priv direction : MetricDirection
  priv improved : Bool
} derive(Debug)

///|
/// Return the baseline run id.
pub fn RunComparison::baseline_id(self : RunComparison) -> String {
  self.baseline_id
}

///|
/// Return the comparison run id.
pub fn RunComparison::comparison_id(self : RunComparison) -> String {
  self.comparison_id
}

///|
/// Return a detached copy of all metric deltas.
pub fn RunComparison::deltas(self : RunComparison) -> Array[MetricDelta] {
  self.deltas.copy()
}

///|
/// Return a detached copy of metric keys only in the comparison run.
pub fn RunComparison::added_keys(self : RunComparison) -> Array[String] {
  self.added_keys.copy()
}

///|
/// Return a detached copy of metric keys only in the baseline run.
pub fn RunComparison::removed_keys(self : RunComparison) -> Array[String] {
  self.removed_keys.copy()
}

///|
/// Return the metric key.
pub fn MetricDelta::key(self : MetricDelta) -> String {
  self.key
}

///|
/// Return the baseline metric value.
pub fn MetricDelta::baseline_value(self : MetricDelta) -> Double {
  self.baseline_value
}

///|
/// Return the comparison metric value.
pub fn MetricDelta::comparison_value(self : MetricDelta) -> Double {
  self.comparison_value
}

///|
/// Return the absolute delta (comparison - baseline).
pub fn MetricDelta::delta(self : MetricDelta) -> Double {
  self.delta
}

///|
/// Return the percent change relative to baseline.
pub fn MetricDelta::percent_change(self : MetricDelta) -> Double {
  self.percent_change
}

///|
/// Return the metric direction.
pub fn MetricDelta::direction(self : MetricDelta) -> MetricDirection {
  self.direction
}

///|
/// Return whether the comparison run improved on this metric.
pub fn MetricDelta::improved(self : MetricDelta) -> Bool {
  self.improved
}

///|
/// Compare two runs from the store by metric.
///
/// Both runs must exist in the store. The comparison uses the latest metric
/// value for each key. If a metric exists in only one run, it is recorded in
/// `added_keys` or `removed_keys` rather than producing a delta.
pub fn TrackingStore::compare_runs(
  self : TrackingStore,
  baseline_id : String,
  comparison_id : String,
) -> Result[RunComparison, TrackingError] {
  let baseline = match self.get_run(baseline_id) {
    Err(err) => return Err(err)
    Ok(r) => r
  }
  let comparison = match self.get_run(comparison_id) {
    Err(err) => return Err(err)
    Ok(r) => r
  }
  let baseline_metrics = baseline.metrics()
  let comparison_metrics = comparison.metrics()
  // Collect all unique metric keys
  let all_keys : Array[String] = []
  for m in baseline_metrics {
    if !array_contains_string(all_keys, m.key()) {
      all_keys.push(m.key())
    }
  }
  for m in comparison_metrics {
    if !array_contains_string(all_keys, m.key()) {
      all_keys.push(m.key())
    }
  }
  let deltas : Array[MetricDelta] = []
  let added : Array[String] = []
  let removed : Array[String] = []
  for key in all_keys {
    let bv_opt = latest_metric_value(baseline_metrics, key)
    let cv_opt = latest_metric_value(comparison_metrics, key)
    match (bv_opt, cv_opt) {
      (Some(bv), Some(cv)) => {
        let dir = match baseline.latest_metric(key) {
          Some(m) => m.direction()
          None => None_
        }
        let d = cv - bv
        let pct = if bv != 0.0 { d / bv * 100.0 } else { 0.0 }
        let imp = match dir {
          HigherBetter => cv > bv
          LowerBetter => cv < bv
          None_ => false
        }
        deltas.push({
          key,
          baseline_value: bv,
          comparison_value: cv,
          delta: d,
          percent_change: pct,
          direction: dir,
          improved: imp,
        })
      }
      (None, Some(_)) => added.push(key)
      (Some(_), None) => removed.push(key)
      (None, None) => () // should not happen
    }
  }
  Ok({
    baseline_id,
    comparison_id,
    deltas,
    added_keys: added,
    removed_keys: removed,
  })
}

///|
/// Find the latest metric value for a key in a metric array.
fn latest_metric_value(metrics : Array[Metric], key : String) -> Double? {
  let mut found : Double? = None
  let mut max_step = -1
  for m in metrics {
    if m.key() == key && m.step() > max_step {
      found = Some(m.value())
      max_step = m.step()
    }
  }
  found
}

///|
/// Check if an array contains a string.
pub fn array_contains_string(arr : Array[String], s : String) -> Bool {
  for item in arr {
    if item == s {
      return true
    }
  }
  false
}
