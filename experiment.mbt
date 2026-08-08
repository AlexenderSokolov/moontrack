///|
/// A container for a group of related experiment runs.
///
/// An experiment groups runs that share the same research question or
/// hypothesis. Each run records its own parameters, metrics, and artifacts.
pub struct Experiment {
  priv id : String
  priv name : String
  priv description : String
  priv tags : Array[String]
  priv created_at : String
  priv mut runs : Array[Run]
  priv metadata : Map[String, String]
} derive(Debug)

///|
/// Build an empty experiment.
pub fn Experiment::new(id : String, name : String) -> Experiment {
  {
    id,
    name,
    description: "",
    tags: [],
    created_at: "",
    runs: [],
    metadata: {},
  }
}

///|
/// Return the experiment id.
pub fn Experiment::id(self : Experiment) -> String {
  self.id
}

///|
/// Return the experiment name.
pub fn Experiment::name(self : Experiment) -> String {
  self.name
}

///|
/// Return the experiment description.
pub fn Experiment::description(self : Experiment) -> String {
  self.description
}

///|
/// Return a detached copy of experiment tags.
pub fn Experiment::tags(self : Experiment) -> Array[String] {
  self.tags.copy()
}

///|
/// Return the creation timestamp string.
pub fn Experiment::created_at(self : Experiment) -> String {
  self.created_at
}

///|
/// Return a detached copy of all runs in this experiment.
pub fn Experiment::runs(self : Experiment) -> Array[Run] {
  self.runs.copy()
}

///|
/// Return a detached copy of experiment metadata.
pub fn Experiment::metadata(self : Experiment) -> Map[String, String] {
  self.metadata.copy()
}

///|
/// Add a short description to an experiment.
pub fn Experiment::with_description(
  self : Experiment,
  description : String,
) -> Experiment {
  { ..self, description, }
}

///|
/// Add tags to an experiment.
pub fn Experiment::with_tags(
  self : Experiment,
  tags : Array[String],
) -> Experiment {
  { ..self, tags: tags.copy() }
}

///|
/// Set the creation timestamp.
pub fn Experiment::with_created_at(
  self : Experiment,
  created_at : String,
) -> Experiment {
  { ..self, created_at, }
}

///|
/// Set metadata entries.
pub fn Experiment::with_metadata(
  self : Experiment,
  metadata : Map[String, String],
) -> Experiment {
  { ..self, metadata: metadata.copy() }
}

///|
/// Return the number of runs in this experiment.
pub fn Experiment::run_count(self : Experiment) -> Int {
  self.runs.length()
}

///|
/// Return a run by id when it exists in this experiment.
pub fn Experiment::find_run(self : Experiment, run_id : String) -> Run? {
  for run in self.runs {
    if run.id() == run_id {
      return Some(run)
    }
  }
  None
}

///|
/// Return all run ids in this experiment.
pub fn Experiment::run_ids(self : Experiment) -> Array[String] {
  let ids : Array[String] = []
  for run in self.runs {
    ids.push(run.id())
  }
  ids
}
