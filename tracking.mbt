///|
/// Errors raised by the tracking store.
pub(all) enum TrackingError {
  DuplicateExperiment(String)
  ExperimentNotFound(String)
  DuplicateRun(String)
  RunNotFound(String)
  InvalidStatusTransition(String, RunStatus, RunStatus)
  ParamAlreadyExists(String, String)
} derive(Eq, Debug)

///|
/// Return a readable diagnostic for a tracking error.
pub fn TrackingError::message(self : TrackingError) -> String {
  match self {
    DuplicateExperiment(id) => "duplicate experiment: \{id}"
    ExperimentNotFound(id) => "experiment not found: \{id}"
    DuplicateRun(id) => "duplicate run: \{id}"
    RunNotFound(id) => "run not found: \{id}"
    InvalidStatusTransition(id, before, after) =>
      "invalid status transition for \{id}: \{before.label()} -> \{after.label()}"
    ParamAlreadyExists(exp, key) => "parameter already exists in \{exp}: \{key}"
  }
}

///|
/// The central in-memory store for experiments and runs.
///
/// All mutations go through the store so that invariants (unique ids, valid
/// transitions) are enforced uniformly. The store uses arrays internally
/// because expected experiment counts are small; this keeps traversal and
/// mutation straightforward while the public API settles.
pub struct TrackingStore {
  priv mut experiments : Array[Experiment]
  priv mut runs : Array[Run]
} derive(Debug)

///|
/// Build an empty tracking store.
pub fn TrackingStore::new() -> TrackingStore {
  { experiments: [], runs: [] }
}

///|
/// Create a new experiment. Rejects duplicate experiment ids.
pub fn TrackingStore::create_experiment(
  self : TrackingStore,
  id : String,
  name : String,
) -> Result[Experiment, TrackingError] {
  if self.find_experiment_index(id) >= 0 {
    return Err(DuplicateExperiment(id))
  }
  let exp = Experiment::new(id, name)
  self.experiments.push(exp)
  Ok(exp)
}

///|
/// Return a detached copy of an experiment by id.
pub fn TrackingStore::get_experiment(
  self : TrackingStore,
  id : String,
) -> Result[Experiment, TrackingError] {
  for exp in self.experiments {
    if exp.id() == id {
      return Ok(exp)
    }
  }
  Err(ExperimentNotFound(id))
}

///|
/// Return a detached list of all experiment ids.
pub fn TrackingStore::list_experiments(self : TrackingStore) -> Array[String] {
  let ids : Array[String] = []
  for exp in self.experiments {
    ids.push(exp.id())
  }
  ids
}

///|
/// Return the number of experiments.
pub fn TrackingStore::experiment_count(self : TrackingStore) -> Int {
  self.experiments.length()
}

///|
/// Start a new run in `Running` status.
/// Rejects duplicate run ids and unknown experiment ids.
pub fn TrackingStore::start_run(
  self : TrackingStore,
  run_id : String,
  experiment_id : String,
  start_time : String,
) -> Result[Run, TrackingError] {
  if self.find_run_index(run_id) >= 0 {
    return Err(DuplicateRun(run_id))
  }
  if self.find_experiment_index(experiment_id) < 0 {
    return Err(ExperimentNotFound(experiment_id))
  }
  let run = Run::new(run_id, experiment_id)
    .with_start_time(start_time)
    .set_status(Running)
  self.runs.push(run)
  Ok(run)
}

///|
/// Return a detached copy of a run by id.
pub fn TrackingStore::get_run(
  self : TrackingStore,
  run_id : String,
) -> Result[Run, TrackingError] {
  match self.find_run(run_id) {
    Some(run) => Ok(run)
    None => Err(RunNotFound(run_id))
  }
}

///|
/// Return all run ids in the store.
pub fn TrackingStore::list_runs(self : TrackingStore) -> Array[String] {
  let ids : Array[String] = []
  for run in self.runs {
    ids.push(run.id())
  }
  ids
}

///|
/// Return the number of runs.
pub fn TrackingStore::run_count(self : TrackingStore) -> Int {
  self.runs.length()
}

///|
/// Transition a run to `Completed`.
pub fn TrackingStore::complete_run(
  self : TrackingStore,
  run_id : String,
  end_time : String,
) -> Result[Run, TrackingError] {
  self.transition_run(run_id, Completed, end_time, "")
}

///|
/// Transition a run to `Failed`.
pub fn TrackingStore::fail_run(
  self : TrackingStore,
  run_id : String,
  end_time : String,
  error_message : String,
) -> Result[Run, TrackingError] {
  self.transition_run(run_id, Failed, end_time, error_message)
}

///|
/// Transition a run to `Killed`.
pub fn TrackingStore::kill_run(
  self : TrackingStore,
  run_id : String,
  end_time : String,
) -> Result[Run, TrackingError] {
  self.transition_run(run_id, Killed, end_time, "")
}

///|
/// Log a parameter on a run.
/// If a parameter with the same key already exists, it is replaced.
pub fn TrackingStore::log_param(
  self : TrackingStore,
  run_id : String,
  param : Param,
) -> Result[Unit, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx =>
      match self.runs[idx].find_param(param.key()) {
        Some(_) => Err(ParamAlreadyExists(run_id, param.key()))
        None => {
          self.runs[idx].add_param(param)
          Ok(())
        }
      }
  }
}

///|
/// Log a metric on a run.
pub fn TrackingStore::log_metric(
  self : TrackingStore,
  run_id : String,
  metric : Metric,
) -> Result[Unit, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx => {
      self.runs[idx].add_metric(metric)
      Ok(())
    }
  }
}

///|
/// Log an artifact on a run.
pub fn TrackingStore::log_artifact(
  self : TrackingStore,
  run_id : String,
  artifact : Artifact,
) -> Result[Unit, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx => {
      self.runs[idx].add_artifact(artifact)
      Ok(())
    }
  }
}

///|
/// Set reproducibility info on a run.
pub fn TrackingStore::set_reproducibility(
  self : TrackingStore,
  run_id : String,
  info : ReproducibilityInfo,
) -> Result[Unit, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx => {
      self.runs[idx].set_reproducibility(Some(info))
      Ok(())
    }
  }
}

///|
/// Add a note to a run.
pub fn TrackingStore::add_note(
  self : TrackingStore,
  run_id : String,
  note : String,
) -> Result[Unit, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx => {
      self.runs[idx].add_note(note)
      Ok(())
    }
  }
}

///|
/// Return all runs belonging to an experiment.
pub fn TrackingStore::runs_for_experiment(
  self : TrackingStore,
  experiment_id : String,
) -> Array[Run] {
  let result : Array[Run] = []
  for run in self.runs {
    if run.experiment_id() == experiment_id {
      result.push(run)
    }
  }
  result
}

///|
/// Return all runs in the store as detached copies.
pub fn TrackingStore::all_runs(self : TrackingStore) -> Array[Run] {
  self.runs.copy()
}

///|
/// Import a pre-constructed run directly into the store.
///
/// This bypasses the normal start_run lifecycle and is intended for
/// JSON import tools that reconstruct historical state. Duplicate run ids
/// are rejected.
pub fn TrackingStore::import_run(
  self : TrackingStore,
  run : Run,
) -> Result[Unit, TrackingError] {
  if self.find_run_index(run.id()) >= 0 {
    return Err(DuplicateRun(run.id()))
  }
  self.runs.push(run)
  Ok(())
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

///|
/// Find the array index of an experiment by id. Returns -1 if not found.
fn TrackingStore::find_experiment_index(
  self : TrackingStore,
  id : String,
) -> Int {
  for i = 0; i < self.experiments.length(); i = i + 1 {
    if self.experiments[i].id() == id {
      return i
    }
  }
  -1
}

///|
/// Find the array index of a run by id. Returns -1 if not found.
fn TrackingStore::find_run_index(self : TrackingStore, id : String) -> Int {
  for i = 0; i < self.runs.length(); i = i + 1 {
    if self.runs[i].id() == id {
      return i
    }
  }
  -1
}

///|
/// Find a run by id.
fn TrackingStore::find_run(self : TrackingStore, id : String) -> Run? {
  for run in self.runs {
    if run.id() == id {
      return Some(run)
    }
  }
  None
}

///|
/// Internal helper: validate and apply a status transition.
fn TrackingStore::transition_run(
  self : TrackingStore,
  run_id : String,
  new_status : RunStatus,
  end_time : String,
  error_message : String,
) -> Result[Run, TrackingError] {
  match self.find_run_index(run_id) {
    -1 => Err(RunNotFound(run_id))
    idx => {
      let run = self.runs[idx]
      let current = run.status()
      if !is_valid_transition(current, new_status) {
        return Err(InvalidStatusTransition(run_id, current, new_status))
      }
      let updated = run
        .set_status(new_status)
        .set_end_time(end_time)
        .with_error_message(error_message)
      self.runs[idx] = updated
      Ok(updated)
    }
  }
}

///|
/// Check whether a status transition is valid.
///
/// Valid transitions:
/// - Created -> Running | Killed
/// - Running -> Completed | Failed | Killed
/// - Failed -> Running (retry)
/// - Completed, Killed are terminal
fn is_valid_transition(from : RunStatus, to : RunStatus) -> Bool {
  match (from, to) {
    (Created, Running) => true
    (Created, Killed) => true
    (Running, Completed) => true
    (Running, Failed) => true
    (Running, Killed) => true
    (Failed, Running) => true
    _ => false
  }
}
