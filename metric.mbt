///|
/// Direction indicating whether a higher or lower metric value is better.
pub(all) enum MetricDirection {
  HigherBetter
  LowerBetter
  None_
} derive(Eq, Debug)

///|
/// A metric value recorded at a specific step.
pub struct Metric {
  priv key : String
  priv value : Double
  priv step : Int
  priv timestamp : String
  priv direction : MetricDirection
  priv threshold : Double?
} derive(Eq, Debug)

///|
/// Build a metric with default direction `None` and no threshold.
pub fn Metric::new(
  key : String,
  value : Double,
  step : Int,
  timestamp : String,
) -> Metric {
  { key, value, step, timestamp, direction: None_, threshold: None }
}

///|
/// Return the metric key.
pub fn Metric::key(self : Metric) -> String {
  self.key
}

///|
/// Return the metric value.
pub fn Metric::value(self : Metric) -> Double {
  self.value
}

///|
/// Return the step number.
pub fn Metric::step(self : Metric) -> Int {
  self.step
}

///|
/// Return the timestamp string.
pub fn Metric::timestamp(self : Metric) -> String {
  self.timestamp
}

///|
/// Return the metric direction.
pub fn Metric::direction(self : Metric) -> MetricDirection {
  self.direction
}

///|
/// Return the threshold if set.
pub fn Metric::threshold(self : Metric) -> Double? {
  self.threshold
}

///|
/// Set the metric direction.
pub fn Metric::with_direction(
  self : Metric,
  direction : MetricDirection,
) -> Metric {
  { ..self, direction, }
}

///|
/// Set the metric threshold.
pub fn Metric::with_threshold(self : Metric, threshold : Double) -> Metric {
  { ..self, threshold: Some(threshold) }
}

///|
/// Return a stable machine-readable direction kind string.
pub fn MetricDirection::kind(self : MetricDirection) -> String {
  match self {
    HigherBetter => "higher_better"
    LowerBetter => "lower_better"
    None_ => "none"
  }
}

///|
/// Return a stable human-readable direction label.
pub fn MetricDirection::label(self : MetricDirection) -> String {
  self.kind()
}

///|
/// Parse a metric direction from its string kind.
pub fn MetricDirection::from_string(s : String) -> MetricDirection? {
  match s {
    "higher_better" => Some(HigherBetter)
    "lower_better" => Some(LowerBetter)
    "none" => Some(None_)
    _ => None
  }
}
