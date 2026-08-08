///|
/// Search filter for experiments.
///
/// All specified conditions must match (AND semantics). An empty filter
/// matches all experiments.
pub struct ExperimentSearchFilter {
  priv name_contains : String
  priv description_contains : String
  priv tags_any : Array[String]
} derive(Debug)

///|
/// Build an empty experiment search filter.
pub fn ExperimentSearchFilter::new() -> ExperimentSearchFilter {
  { name_contains: "", description_contains: "", tags_any: [] }
}

///|
/// Restrict to experiments whose name contains the given substring.
pub fn ExperimentSearchFilter::with_name_contains(
  self : ExperimentSearchFilter,
  substring : String,
) -> ExperimentSearchFilter {
  { ..self, name_contains: substring }
}

///|
/// Restrict to experiments whose description contains the given substring.
pub fn ExperimentSearchFilter::with_description_contains(
  self : ExperimentSearchFilter,
  substring : String,
) -> ExperimentSearchFilter {
  { ..self, description_contains: substring }
}

///|
/// Restrict to experiments that have at least one of the given tags.
pub fn ExperimentSearchFilter::with_tags_any(
  self : ExperimentSearchFilter,
  tags : Array[String],
) -> ExperimentSearchFilter {
  { ..self, tags_any: tags.copy() }
}

///|
/// Test whether a single experiment matches this filter.
pub fn ExperimentSearchFilter::matches(
  self : ExperimentSearchFilter,
  exp : Experiment,
) -> Bool {
  if self.name_contains != "" {
    if !exp.name().contains(self.name_contains) {
      return false
    }
  }
  if self.description_contains != "" {
    if !exp.description().contains(self.description_contains) {
      return false
    }
  }
  if self.tags_any.length() > 0 {
    let exp_tags = exp.tags()
    let mut found = false
    for t in self.tags_any {
      for et in exp_tags {
        if t == et {
          found = true
          break
        }
      }
      if found {
        break
      }
    }
    if !found {
      return false
    }
  }
  true
}

///|
/// Search experiments in the store that match the given filter.
pub fn TrackingStore::search_experiments(
  self : TrackingStore,
  filter : ExperimentSearchFilter,
) -> Array[Experiment] {
  let result : Array[Experiment] = []
  for exp in self.experiments {
    if filter.matches(exp) {
      result.push(exp)
    }
  }
  result
}

///|
/// Find experiments by tag.
pub fn TrackingStore::experiments_by_tag(
  self : TrackingStore,
  tag : String,
) -> Array[Experiment] {
  let result : Array[Experiment] = []
  for exp in self.experiments {
    for t in exp.tags() {
      if t == tag {
        result.push(exp)
        break
      }
    }
  }
  result
}

///|
/// Find experiments by name substring (case-sensitive).
pub fn TrackingStore::experiments_by_name(
  self : TrackingStore,
  substring : String,
) -> Array[Experiment] {
  let result : Array[Experiment] = []
  for exp in self.experiments {
    if exp.name().contains(substring) {
      result.push(exp)
    }
  }
  result
}

///|
/// Count experiments by status of their runs.
///
/// Returns a map from run status label string to the count of runs with
/// that status across all experiments.
pub fn TrackingStore::run_status_summary(
  self : TrackingStore,
) -> Map[String, Int] {
  let summary : Map[String, Int] = Map([])
  for run in self.runs {
    let status_label = run.status().label()
    match summary.get(status_label) {
      None => summary[status_label] = 1
      Some(count) => summary[status_label] = count + 1
    }
  }
  summary
}

///|
/// Count experiments by tag.
///
/// Returns a map from tag to the count of experiments with that tag.
pub fn TrackingStore::tag_summary(self : TrackingStore) -> Map[String, Int] {
  let summary : Map[String, Int] = Map([])
  for exp in self.experiments {
    for tag in exp.tags() {
      match summary.get(tag) {
        None => summary[tag] = 1
        Some(count) => summary[tag] = count + 1
      }
    }
  }
  summary
}

///|
/// Return the total number of parameters across all runs.
pub fn TrackingStore::total_param_count(self : TrackingStore) -> Int {
  let mut total = 0
  for run in self.runs {
    total += run.param_count()
  }
  total
}

///|
/// Return the total number of metrics across all runs.
pub fn TrackingStore::total_metric_count(self : TrackingStore) -> Int {
  let mut total = 0
  for run in self.runs {
    total += run.metric_count()
  }
  total
}

///|
/// Return the total number of artifacts across all runs.
pub fn TrackingStore::total_artifact_count(self : TrackingStore) -> Int {
  let mut total = 0
  for run in self.runs {
    total += run.artifact_count()
  }
  total
}

///|
/// Return a summary of the store's contents as a human-readable string.
pub fn TrackingStore::summary(self : TrackingStore) -> String {
  let out = StringBuilder()
  out <+ "MoonTrack Store Summary\n"
  out <+ "=======================\n\n"
  out <+ "Experiments: \{self.experiment_count()}\n"
  out <+ "Runs: \{self.run_count()}\n"
  out <+ "Total parameters: \{self.total_param_count()}\n"
  out <+ "Total metrics: \{self.total_metric_count()}\n"
  out <+ "Total artifacts: \{self.total_artifact_count()}\n\n"
  out <+ "Run Status Summary:\n"
  let status_summary = self.run_status_summary()
  let statuses : Array[RunStatus] = [
    Created,
    Running,
    Completed,
    Failed,
    Killed,
  ]
  for status in statuses {
    let count = match status_summary.get(status.label()) {
      None => 0
      Some(c) => c
    }
    out <+ "  \{status.label()}: \{count}\n"
  }
  out <+ "\nTag Summary:\n"
  let tag_summary = self.tag_summary()
  let tag_keys : Array[String] = []
  tag_summary.each(fn(k, _v) { tag_keys.push(k) })
  for tag in tag_keys {
    let count = match tag_summary.get(tag) {
      None => 0
      Some(c) => c
    }
    out <+ "  \{tag}: \{count} experiments\n"
  }
  out.to_string()
}
