///|
/// Lifecycle status of a run.
pub(all) enum RunStatus {
  Created
  Running
  Completed
  Failed
  Killed
} derive(Eq, Debug)

///|
/// A single experiment run recording parameters, metrics, and artifacts.
pub struct Run {
  priv id : String
  priv experiment_id : String
  priv status : RunStatus
  priv start_time : String
  priv mut end_time : String
  priv mut parameters : Array[Param]
  priv mut metrics : Array[Metric]
  priv mut artifacts : Array[Artifact]
  priv tags : Array[String]
  priv mut reproducibility : ReproducibilityInfo?
  priv mut notes : Array[String]
  priv mut error_message : String
} derive(Debug)

///|
/// Build a new run in `Created` status.
pub fn Run::new(id : String, experiment_id : String) -> Run {
  {
    id,
    experiment_id,
    status: Created,
    start_time: "",
    end_time: "",
    parameters: [],
    metrics: [],
    artifacts: [],
    tags: [],
    reproducibility: None,
    notes: [],
    error_message: "",
  }
}

///|
/// Return the run id.
pub fn Run::id(self : Run) -> String {
  self.id
}

///|
/// Return the experiment id this run belongs to.
pub fn Run::experiment_id(self : Run) -> String {
  self.experiment_id
}

///|
/// Return the current run status.
pub fn Run::status(self : Run) -> RunStatus {
  self.status
}

///|
/// Return the start timestamp string.
pub fn Run::start_time(self : Run) -> String {
  self.start_time
}

///|
/// Return the end timestamp string.
pub fn Run::end_time(self : Run) -> String {
  self.end_time
}

///|
/// Return a detached copy of all parameters.
pub fn Run::parameters(self : Run) -> Array[Param] {
  self.parameters.copy()
}

///|
/// Return a detached copy of all metrics.
pub fn Run::metrics(self : Run) -> Array[Metric] {
  self.metrics.copy()
}

///|
/// Return a detached copy of all artifacts.
pub fn Run::artifacts(self : Run) -> Array[Artifact] {
  self.artifacts.copy()
}

///|
/// Return a detached copy of run tags.
pub fn Run::tags(self : Run) -> Array[String] {
  self.tags.copy()
}

///|
/// Return the reproducibility info if present.
pub fn Run::reproducibility(self : Run) -> ReproducibilityInfo? {
  self.reproducibility
}

///|
/// Return a detached copy of run notes.
pub fn Run::notes(self : Run) -> Array[String] {
  self.notes.copy()
}

///|
/// Return the error message attached to a failed run.
pub fn Run::error_message(self : Run) -> String {
  self.error_message
}

///|
/// Set the start timestamp.
pub fn Run::with_start_time(self : Run, start_time : String) -> Run {
  { ..self, start_time, }
}

///|
/// Add tags to a run.
pub fn Run::with_tags(self : Run, tags : Array[String]) -> Run {
  { ..self, tags: tags.copy() }
}

///|
/// Set reproducibility information.
pub fn Run::with_reproducibility(self : Run, info : ReproducibilityInfo) -> Run {
  { ..self, reproducibility: Some(info) }
}

///|
/// Set the error message for a failed run.
pub fn Run::with_error_message(self : Run, msg : String) -> Run {
  { ..self, error_message: msg }
}

///|
/// Set the status directly. Intended for importers and replay tools.
pub fn Run::set_status(self : Run, status : RunStatus) -> Run {
  { ..self, status, }
}

///|
/// Set the end time directly.
pub fn Run::set_end_time(self : Run, end_time : String) -> Run {
  { ..self, end_time, }
}

///|
/// Append a parameter to this run.
pub fn Run::add_param(self : Run, param : Param) -> Unit {
  self.parameters.push(param)
}

///|
/// Append a metric to this run.
pub fn Run::add_metric(self : Run, metric : Metric) -> Unit {
  self.metrics.push(metric)
}

///|
/// Append an artifact to this run.
pub fn Run::add_artifact(self : Run, artifact : Artifact) -> Unit {
  self.artifacts.push(artifact)
}

///|
/// Append a note to this run.
pub fn Run::add_note(self : Run, note : String) -> Unit {
  self.notes.push(note)
}

///|
/// Set reproducibility info directly on this run.
pub fn Run::set_reproducibility(
  self : Run,
  info : ReproducibilityInfo?,
) -> Unit {
  self.reproducibility = info
}

///|
/// Return the number of parameters.
pub fn Run::param_count(self : Run) -> Int {
  self.parameters.length()
}

///|
/// Return the number of metrics.
pub fn Run::metric_count(self : Run) -> Int {
  self.metrics.length()
}

///|
/// Return the number of artifacts.
pub fn Run::artifact_count(self : Run) -> Int {
  self.artifacts.length()
}

///|
/// Find a parameter by key.
pub fn Run::find_param(self : Run, key : String) -> Param? {
  for p in self.parameters {
    if p.key() == key {
      return Some(p)
    }
  }
  None
}

///|
/// Find the latest metric value for a key.
pub fn Run::latest_metric(self : Run, key : String) -> Metric? {
  let mut found : Metric? = None
  for m in self.metrics {
    if m.key() == key {
      match found {
        Some(prev) => if m.step() >= prev.step() { found = Some(m) }
        None => found = Some(m)
      }
    }
  }
  found
}

///|
/// Return all metric values for a key in step order.
pub fn Run::metrics_for(self : Run, key : String) -> Array[Metric] {
  let result : Array[Metric] = []
  for m in self.metrics {
    if m.key() == key {
      result.push(m)
    }
  }
  // Sort by step ascending using simple insertion sort.
  for i = 1; i < result.length(); i = i + 1 {
    let j = i
    while j > 0 && result[j].step() < result[j - 1].step() {
      let temp = result[j]
      result[j] = result[j - 1]
      result[j - 1] = temp
    }
  }
  result
}

///|
/// Return a stable machine-readable status kind string.
pub fn RunStatus::kind(self : RunStatus) -> String {
  match self {
    Created => "created"
    Running => "running"
    Completed => "completed"
    Failed => "failed"
    Killed => "killed"
  }
}

///|
/// Return a stable human-readable status label.
pub fn RunStatus::label(self : RunStatus) -> String {
  match self {
    Created => "created"
    Running => "running"
    Completed => "completed"
    Failed => "failed"
    Killed => "killed"
  }
}

///|
/// Parse a run status from its string kind.
pub fn RunStatus::from_string(s : String) -> RunStatus? {
  match s {
    "created" => Some(Created)
    "running" => Some(Running)
    "completed" => Some(Completed)
    "failed" => Some(Failed)
    "killed" => Some(Killed)
    _ => None
  }
}
