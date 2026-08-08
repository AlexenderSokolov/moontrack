///|
/// Sort a copy of the input array in ascending order using selection sort.
pub fn sort_doubles(values : Array[Double]) -> Array[Double] {
  let sorted = values.copy()
  let n = sorted.length()
  for i = 0; i < n; i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < n; j = j + 1 {
      if sorted[j] < sorted[min_idx] {
        min_idx = j
      }
    }
    if min_idx != i {
      let temp = sorted[i]
      sorted[i] = sorted[min_idx]
      sorted[min_idx] = temp
    }
  }
  sorted
}

///|
/// Compute the median of a non-empty array of doubles.
pub fn median_doubles(values : Array[Double]) -> Double {
  let sorted = sort_doubles(values)
  let n = sorted.length()
  if n == 0 {
    return 0.0
  }
  if n % 2 == 1 {
    sorted[n / 2]
  } else {
    (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  }
}

///|
/// Compute the p-th percentile (0-100) using linear interpolation.
pub fn percentile_doubles(values : Array[Double], p : Double) -> Double {
  let sorted = sort_doubles(values)
  let n = sorted.length()
  if n == 0 {
    return 0.0
  }
  if p <= 0.0 {
    return sorted[0]
  }
  if p >= 100.0 {
    return sorted[n - 1]
  }
  let rank = p / 100.0 * (n - 1).to_double()
  let lower = rank.to_int()
  let upper = lower + 1
  if upper >= n {
    return sorted[lower]
  }
  let frac = rank - lower.to_double()
  sorted[lower] + frac * (sorted[upper] - sorted[lower])
}

///|
/// A comprehensive summary of metric values across multiple runs.
///
/// This extends `MetricStats` with median, standard deviation, and
/// percentile support for richer statistical analysis.
pub struct MetricSummary {
  priv key : String
  priv count : Int
  priv min_val : Double
  priv max_val : Double
  priv mean_val : Double
  priv median_val : Double
  priv stddev_val : Double
  priv values : Array[Double]
} derive(Debug)

///|
/// Return the metric key.
pub fn MetricSummary::key(self : MetricSummary) -> String {
  self.key
}

///|
/// Return the number of data points.
pub fn MetricSummary::count(self : MetricSummary) -> Int {
  self.count
}

///|
/// Return the minimum value.
pub fn MetricSummary::min_val(self : MetricSummary) -> Double {
  self.min_val
}

///|
/// Return the maximum value.
pub fn MetricSummary::max_val(self : MetricSummary) -> Double {
  self.max_val
}

///|
/// Return the mean value.
pub fn MetricSummary::mean_val(self : MetricSummary) -> Double {
  self.mean_val
}

///|
/// Return the median value.
pub fn MetricSummary::median_val(self : MetricSummary) -> Double {
  self.median_val
}

///|
/// Return the standard deviation.
pub fn MetricSummary::stddev_val(self : MetricSummary) -> Double {
  self.stddev_val
}

///|
/// Return a detached copy of all values.
pub fn MetricSummary::values(self : MetricSummary) -> Array[Double] {
  self.values.copy()
}

///|
/// Return the range (max - min).
pub fn MetricSummary::range(self : MetricSummary) -> Double {
  self.max_val - self.min_val
}

///|
/// Return the variance (stddev^2).
pub fn MetricSummary::variance(self : MetricSummary) -> Double {
  self.stddev_val * self.stddev_val
}

///|
/// Return the coefficient of variation (stddev / mean).
/// Returns 0.0 if mean is zero.
pub fn MetricSummary::coefficient_of_variation(self : MetricSummary) -> Double {
  if self.mean_val == 0.0 {
    return 0.0
  }
  self.stddev_val / self.mean_val
}

///|
/// Return the p-th percentile (0-100) of the values.
pub fn MetricSummary::percentile(self : MetricSummary, p : Double) -> Double {
  percentile_doubles(self.values, p)
}

///|
/// Return the first quartile (25th percentile).
pub fn MetricSummary::q1(self : MetricSummary) -> Double {
  percentile_doubles(self.values, 25.0)
}

///|
/// Return the third quartile (75th percentile).
pub fn MetricSummary::q3(self : MetricSummary) -> Double {
  percentile_doubles(self.values, 75.0)
}

///|
/// Return the interquartile range (Q3 - Q1).
pub fn MetricSummary::iqr(self : MetricSummary) -> Double {
  self.q3() - self.q1()
}

///|
/// Compute a comprehensive metric summary for a specific metric key
/// across all runs in an experiment.
///
/// Only the latest metric value for each run is considered. Runs without
/// the specified metric are skipped.
pub fn TrackingStore::metric_summary(
  self : TrackingStore,
  experiment_id : String,
  metric_key : String,
) -> Result[MetricSummary, TrackingError] {
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
  let sorted = sort_doubles(values)
  let count = sorted.length()
  let min_v = sorted[0]
  let max_v = sorted[count - 1]
  let mut sum = 0.0
  for v in sorted {
    sum += v
  }
  let mean = sum / count.to_double()
  let median = median_doubles(sorted)
  let mut sum_sq = 0.0
  for v in sorted {
    let diff = v - mean
    sum_sq += diff * diff
  }
  let variance = if count < 2 { 0.0 } else { sum_sq / (count - 1).to_double() }
  let stddev = variance.sqrt()
  Ok({
    key: metric_key,
    count,
    min_val: min_v,
    max_val: max_v,
    mean_val: mean,
    median_val: median,
    stddev_val: stddev,
    values,
  })
}

///|
/// Compute metric summaries for all metric keys in an experiment.
pub fn TrackingStore::all_metric_summaries(
  self : TrackingStore,
  experiment_id : String,
) -> Result[Array[MetricSummary], TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  let all_keys : Array[String] = []
  for run in runs {
    for m in run.metrics() {
      if !array_contains_string(all_keys, m.key()) {
        all_keys.push(m.key())
      }
    }
  }
  let summaries : Array[MetricSummary] = []
  for key in all_keys {
    match self.metric_summary(experiment_id, key) {
      Ok(s) => summaries.push(s)
      Err(_) => ()
    }
  }
  Ok(summaries)
}

///|
/// Compute the Pearson correlation coefficient between two metrics
/// across all runs in an experiment.
///
/// Only runs that have both metrics are considered. At least 2 data
/// points are required.
pub fn TrackingStore::metric_correlation(
  self : TrackingStore,
  experiment_id : String,
  key_a : String,
  key_b : String,
) -> Result[Double, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  let xs : Array[Double] = []
  let ys : Array[Double] = []
  for run in runs {
    match run.latest_metric(key_a) {
      Some(ma) =>
        match run.latest_metric(key_b) {
          Some(mb) => {
            xs.push(ma.value())
            ys.push(mb.value())
          }
          None => ()
        }
      None => ()
    }
  }
  let n = xs.length()
  if n < 2 {
    return Err(RunNotFound(key_a))
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for i = 0; i < n; i = i + 1 {
    sum_x += xs[i]
    sum_y += ys[i]
  }
  let mean_x = sum_x / n.to_double()
  let mean_y = sum_y / n.to_double()
  let mut numerator = 0.0
  let mut sum_sq_x = 0.0
  let mut sum_sq_y = 0.0
  for i = 0; i < n; i = i + 1 {
    let dx = xs[i] - mean_x
    let dy = ys[i] - mean_y
    numerator += dx * dy
    sum_sq_x += dx * dx
    sum_sq_y += dy * dy
  }
  let denominator = (sum_sq_x * sum_sq_y).sqrt()
  if denominator == 0.0 {
    return Err(RunNotFound("zero variance"))
  }
  Ok(numerator / denominator)
}

///|
/// Generate a comprehensive statistics report in Markdown format.
///
/// Includes metric summaries (count, min, max, mean, median, std dev)
/// and pairwise metric correlations.
pub fn TrackingStore::statistics_report(
  self : TrackingStore,
  experiment_id : String,
) -> Result[String, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(exp) => {
      let out = StringBuilder()
      out <+ "# Statistics Report\n\n"
      out <+ "## Experiment: \{exp.name()}\n\n"
      out <+ "- **ID**: `\{exp.id()}`\n"
      out <+ "- **Runs**: \{exp.run_count()}\n\n"
      match self.all_metric_summaries(experiment_id) {
        Ok(summaries) => {
          if summaries.is_empty() {
            out <+ "_No metrics recorded._\n\n"
          } else {
            out <+ "### Metric Summaries\n\n"
            out <+ "| Metric | Count | Min | Max | Mean | Median | Std Dev |\n"
            out <+ "|--------|-------|-----|-----|------|--------|---------|\n"
            for s in summaries {
              out <+ "| \{s.key()} | \{s.count()} | "
              out <+ "\{s.min_val()} | \{s.max_val()} | "
              out <+ "\{s.mean_val()} | \{s.median_val()} | "
              out <+ "\{s.stddev_val()} |\n"
            }
            out <+ "\n"
            if summaries.length() >= 2 {
              out <+ "### Metric Correlations\n\n"
              out <+ "| Metric A | Metric B | Correlation |\n"
              out <+ "|----------|----------|-------------|\n"
              for i = 0; i < summaries.length(); i = i + 1 {
                for j = i + 1; j < summaries.length(); j = j + 1 {
                  let key_a = summaries[i].key()
                  let key_b = summaries[j].key()
                  match self.metric_correlation(experiment_id, key_a, key_b) {
                    Ok(corr) => out <+ "| \{key_a} | \{key_b} | \{corr} |\n"
                    Err(_) => ()
                  }
                }
              }
              out <+ "\n"
            }
          }
          Ok(out.to_string())
        }
        Err(err) => Err(err)
      }
    }
  }
}
