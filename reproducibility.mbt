///|
/// Reproducibility information for a run.
///
/// This captures enough context for another session to reproduce the run:
/// the code version, the exact command, the environment, and the random seed.
pub struct ReproducibilityInfo {
  priv code_version : String
  priv command : String
  priv environment : Map[String, String]
  priv random_seed : Int?
  priv dependencies : Array[String]
} derive(Eq, Debug)

///|
/// Build reproducibility info with empty environment and no seed.
pub fn ReproducibilityInfo::new(
  code_version : String,
  command : String,
) -> ReproducibilityInfo {
  {
    code_version,
    command,
    environment: {},
    random_seed: None,
    dependencies: [],
  }
}

///|
/// Return the code version string (e.g. git commit hash).
pub fn ReproducibilityInfo::code_version(self : ReproducibilityInfo) -> String {
  self.code_version
}

///|
/// Return the exact command used to run the experiment.
pub fn ReproducibilityInfo::command(self : ReproducibilityInfo) -> String {
  self.command
}

///|
/// Return a detached copy of the environment map.
pub fn ReproducibilityInfo::environment(
  self : ReproducibilityInfo,
) -> Map[String, String] {
  self.environment.copy()
}

///|
/// Return the random seed if set.
pub fn ReproducibilityInfo::random_seed(self : ReproducibilityInfo) -> Int? {
  self.random_seed
}

///|
/// Return a detached copy of dependency list.
pub fn ReproducibilityInfo::dependencies(
  self : ReproducibilityInfo,
) -> Array[String] {
  self.dependencies.copy()
}

///|
/// Set the environment map.
pub fn ReproducibilityInfo::with_environment(
  self : ReproducibilityInfo,
  env : Map[String, String],
) -> ReproducibilityInfo {
  { ..self, environment: env.copy() }
}

///|
/// Set the random seed.
pub fn ReproducibilityInfo::with_random_seed(
  self : ReproducibilityInfo,
  seed : Int,
) -> ReproducibilityInfo {
  { ..self, random_seed: Some(seed) }
}

///|
/// Set the dependency list.
pub fn ReproducibilityInfo::with_dependencies(
  self : ReproducibilityInfo,
  deps : Array[String],
) -> ReproducibilityInfo {
  { ..self, dependencies: deps.copy() }
}
