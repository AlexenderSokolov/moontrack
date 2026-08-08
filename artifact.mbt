///|
/// An artifact produced by a run, such as a model file or a plot.
pub struct Artifact {
  priv name : String
  priv path : String
  priv size : Int
  priv checksum : String?
  priv metadata : Map[String, String]
} derive(Eq, Debug)

///|
/// Build a new artifact with empty metadata and no checksum.
pub fn Artifact::new(name : String, path : String, size : Int) -> Artifact {
  { name, path, size, checksum: None, metadata: {} }
}

///|
/// Return the artifact name.
pub fn Artifact::name(self : Artifact) -> String {
  self.name
}

///|
/// Return the artifact path.
pub fn Artifact::path(self : Artifact) -> String {
  self.path
}

///|
/// Return the artifact size in bytes.
pub fn Artifact::size(self : Artifact) -> Int {
  self.size
}

///|
/// Return the checksum if set.
pub fn Artifact::checksum(self : Artifact) -> String? {
  self.checksum
}

///|
/// Return a detached copy of artifact metadata.
pub fn Artifact::metadata(self : Artifact) -> Map[String, String] {
  self.metadata.copy()
}

///|
/// Set the checksum.
pub fn Artifact::with_checksum(self : Artifact, checksum : String) -> Artifact {
  { ..self, checksum: Some(checksum) }
}

///|
/// Set metadata entries.
pub fn Artifact::with_metadata(
  self : Artifact,
  metadata : Map[String, String],
) -> Artifact {
  { ..self, metadata: metadata.copy() }
}
