///|
/// Severity level for a validation issue.
pub(all) enum ValidationSeverity {
  Error
  Warning
} derive(Eq, Debug)

///|
/// Return a stable machine-readable severity kind string.
pub fn ValidationSeverity::kind(self : ValidationSeverity) -> String {
  match self {
    Error => "error"
    Warning => "warning"
  }
}

///|
/// Return a stable human-readable severity label.
pub fn ValidationSeverity::label(self : ValidationSeverity) -> String {
  self.kind()
}

///|
/// A single validation issue found during store validation.
pub struct ValidationIssue {
  priv severity : ValidationSeverity
  priv code : String
  priv message : String
  priv run_id : String?
  priv experiment_id : String?
} derive(Debug)

///|
/// Build a validation issue with the given severity, code, and message.
pub fn ValidationIssue::new(
  severity : ValidationSeverity,
  code : String,
  message : String,
) -> ValidationIssue {
  { severity, code, message, run_id: None, experiment_id: None }
}

///|
/// Return the severity level.
pub fn ValidationIssue::severity(self : ValidationIssue) -> ValidationSeverity {
  self.severity
}

///|
/// Return the issue code (e.g. "empty_experiment_name").
pub fn ValidationIssue::code(self : ValidationIssue) -> String {
  self.code
}

///|
/// Return the human-readable issue message.
pub fn ValidationIssue::message(self : ValidationIssue) -> String {
  self.message
}

///|
/// Return the run id associated with this issue, if any.
pub fn ValidationIssue::run_id(self : ValidationIssue) -> String? {
  self.run_id
}

///|
/// Return the experiment id associated with this issue, if any.
pub fn ValidationIssue::experiment_id(self : ValidationIssue) -> String? {
  self.experiment_id
}

///|
/// Attach an experiment id to this issue.
pub fn ValidationIssue::with_experiment_id(
  self : ValidationIssue,
  experiment_id : String,
) -> ValidationIssue {
  { ..self, experiment_id: Some(experiment_id) }
}

///|
/// Attach a run id to this issue.
pub fn ValidationIssue::with_run_id(
  self : ValidationIssue,
  run_id : String,
) -> ValidationIssue {
  { ..self, run_id: Some(run_id) }
}

///|
/// The result of validating a tracking store.
pub struct ValidationResult {
  priv issues : Array[ValidationIssue]
} derive(Debug)

///|
/// Build an empty validation result.
pub fn ValidationResult::new() -> ValidationResult {
  { issues: [] }
}

///|
/// Return a detached copy of all validation issues.
pub fn ValidationResult::issues(
  self : ValidationResult,
) -> Array[ValidationIssue] {
  self.issues.copy()
}

///|
/// Return the total number of issues.
pub fn ValidationResult::issue_count(self : ValidationResult) -> Int {
  self.issues.length()
}

///|
/// Return the number of issues with the given severity.
pub fn ValidationResult::count_by_severity(
  self : ValidationResult,
  severity : ValidationSeverity,
) -> Int {
  let mut count = 0
  for issue in self.issues {
    if issue.severity() == severity {
      count += 1
    }
  }
  count
}

///|
/// Return the number of error-severity issues.
pub fn ValidationResult::error_count(self : ValidationResult) -> Int {
  self.count_by_severity(Error)
}

///|
/// Return the number of warning-severity issues.
pub fn ValidationResult::warning_count(self : ValidationResult) -> Int {
  self.count_by_severity(Warning)
}

///|
/// Return true if there are no error-severity issues.
pub fn ValidationResult::is_valid(self : ValidationResult) -> Bool {
  self.error_count() == 0
}

///|
/// Add an issue to the result.
pub fn ValidationResult::add_issue(
  self : ValidationResult,
  issue : ValidationIssue,
) -> Unit {
  self.issues.push(issue)
}

///|
/// Generate a human-readable summary of the validation result.
pub fn ValidationResult::summary(self : ValidationResult) -> String {
  let out = StringBuilder()
  out <+ "Validation Result\n"
  out <+ "=================\n"
  out <+ "Total issues: \{self.issue_count()}\n"
  out <+ "Errors: \{self.error_count()}\n"
  out <+ "Warnings: \{self.warning_count()}\n"
  if self.is_valid() {
    out <+ "Status: VALID\n"
  } else {
    out <+ "Status: INVALID\n"
  }
  if self.issues.length() > 0 {
    out <+ "\nIssues:\n"
    for issue in self.issues {
      out <+
        "  [\{issue.severity().label()}] \{issue.code()}: \{issue.message()}\n"
    }
  }
  out.to_string()
}

///|
/// Validate the entire tracking store for data integrity.
///
/// Checks performed:
/// - Experiments have non-empty names
/// - Experiments have non-empty ids
/// - Runs have non-empty ids
/// - Runs reference existing experiments
/// - Runs have at least one metric (warning)
/// - Runs have at least one parameter (warning)
/// - Runs have reproducibility info (warning)
/// - Metric steps are non-negative
/// - Artifacts have non-empty paths
pub fn TrackingStore::validate(self : TrackingStore) -> ValidationResult {
  let result = ValidationResult::new()
  // Validate experiments
  for exp in self.experiments {
    let exp_id = exp.id()
    if exp_id == "" {
      result.add_issue(
        ValidationIssue::new(
          Error,
          "empty_experiment_id",
          "Experiment has an empty id",
        ),
      )
    }
    if exp.name() == "" {
      result.add_issue(
        ValidationIssue::new(
          Warning,
          "empty_experiment_name",
          "Experiment '\{exp_id}' has an empty name",
        ).with_experiment_id(exp_id),
      )
    }
  }
  // Validate runs
  for run in self.runs {
    let run_id = run.id()
    let exp_id = run.experiment_id()
    if run_id == "" {
      result.add_issue(
        ValidationIssue::new(Error, "empty_run_id", "Run has an empty id"),
      )
    }
    // Check experiment reference
    if self.find_experiment_index(exp_id) < 0 {
      result.add_issue(
        ValidationIssue::new(
          Error,
          "run_references_unknown_experiment",
          "Run '\{run_id}' references unknown experiment '\{exp_id}'",
        )
        .with_run_id(run_id)
        .with_experiment_id(exp_id),
      )
    }
    // Check for metrics
    if run.metric_count() == 0 {
      result.add_issue(
        ValidationIssue::new(
          Warning,
          "run_has_no_metrics",
          "Run '\{run_id}' has no recorded metrics",
        ).with_run_id(run_id),
      )
    }
    // Check for parameters
    if run.param_count() == 0 {
      result.add_issue(
        ValidationIssue::new(
          Warning,
          "run_has_no_params",
          "Run '\{run_id}' has no recorded parameters",
        ).with_run_id(run_id),
      )
    }
    // Check for reproducibility info
    match run.reproducibility() {
      None =>
        result.add_issue(
          ValidationIssue::new(
            Warning,
            "run_has_no_reproducibility",
            "Run '\{run_id}' has no reproducibility info",
          ).with_run_id(run_id),
        )
      Some(_) => ()
    }
    // Validate metric steps
    for m in run.metrics() {
      if m.step() < 0 {
        result.add_issue(
          ValidationIssue::new(
            Error,
            "negative_metric_step",
            "Run '\{run_id}' has metric '\{m.key()}' with negative step \{m.step()}",
          ).with_run_id(run_id),
        )
      }
    }
    // Validate artifacts
    for art in run.artifacts() {
      if art.path() == "" {
        result.add_issue(
          ValidationIssue::new(
            Error,
            "empty_artifact_path",
            "Run '\{run_id}' has artifact '\{art.name()}' with empty path",
          ).with_run_id(run_id),
        )
      }
      if art.size() < 0 {
        result.add_issue(
          ValidationIssue::new(
            Error,
            "negative_artifact_size",
            "Run '\{run_id}' has artifact '\{art.name()}' with negative size \{art.size()}",
          ).with_run_id(run_id),
        )
      }
    }
  }
  result
}
