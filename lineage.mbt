///|
/// Run lineage tracking for parent-child relationships.
///
/// This module allows tracking which runs are derived from which other runs,
/// forming a lineage tree. A run may have at most one parent. Cycles are
/// rejected.
pub struct LineageTracker {
  priv mut parent_of : Array[(String, String)]
} derive(Debug)

///|
/// Build an empty lineage tracker.
pub fn LineageTracker::new() -> LineageTracker {
  { parent_of: [] }
}

///|
/// Set the parent of a run.
///
/// Rejects:
/// - Self-parenting (child == parent)
/// - Cycles (setting a parent that would create a cycle)
/// - Overwriting an existing parent (use `reparent` instead)
pub fn LineageTracker::set_parent(
  self : LineageTracker,
  child : String,
  parent : String,
) -> Result[Unit, LineageError] {
  if child == parent {
    return Err(SelfParent(child))
  }
  if self.find_parent(child) != "" {
    return Err(ParentAlreadySet(child))
  }
  if self.would_create_cycle(child, parent) {
    return Err(LineageCycle(child, parent))
  }
  self.parent_of.push((child, parent))
  Ok(())
}

///|
/// Change the parent of a run that already has a parent.
pub fn LineageTracker::reparent(
  self : LineageTracker,
  child : String,
  new_parent : String,
) -> Result[Unit, LineageError] {
  if child == new_parent {
    return Err(SelfParent(child))
  }
  if self.would_create_cycle(child, new_parent) {
    return Err(LineageCycle(child, new_parent))
  }
  // Remove old parent
  let mut i = 0
  while i < self.parent_of.length() {
    let (c, _) = self.parent_of[i]
    if c == child {
      self.parent_of.remove(i) |> ignore
    } else {
      i += 1
    }
  }
  self.parent_of.push((child, new_parent))
  Ok(())
}

///|
/// Return the parent run id, or empty string if no parent.
pub fn LineageTracker::parent(self : LineageTracker, child : String) -> String {
  self.find_parent(child)
}

///|
/// Return the children of a run.
pub fn LineageTracker::children(
  self : LineageTracker,
  parent : String,
) -> Array[String] {
  let result : Array[String] = []
  for pair in self.parent_of {
    let (c, p) = pair
    if p == parent {
      result.push(c)
    }
  }
  result
}

///|
/// Return the full ancestor chain from the given run to the root.
pub fn LineageTracker::ancestors(
  self : LineageTracker,
  child : String,
) -> Array[String] {
  let result : Array[String] = []
  let mut current = child
  let mut guard_count = 0
  while guard_count < 1000 {
    let p = self.find_parent(current)
    if p == "" {
      break
    }
    result.push(p)
    current = p
    guard_count += 1
  }
  result
}

///|
/// Return the full descendant tree rooted at the given run.
pub fn LineageTracker::descendants(
  self : LineageTracker,
  root : String,
) -> Array[String] {
  let result : Array[String] = []
  let mut queue : Array[String] = [root]
  while !queue.is_empty() {
    let current = queue[queue.length() - 1]
    queue.remove(queue.length() - 1) |> ignore
    let kids = self.children(current)
    for kid in kids {
      result.push(kid)
      queue.push(kid)
    }
  }
  result
}

///|
/// Return the root ancestor of a run (the run with no parent in the chain).
pub fn LineageTracker::root(self : LineageTracker, child : String) -> String {
  let mut current = child
  let mut guard_count = 0
  while guard_count < 1000 {
    let p = self.find_parent(current)
    if p == "" {
      return current
    }
    current = p
    guard_count += 1
  }
  current
}

///|
/// Return the lineage depth (number of ancestors).
pub fn LineageTracker::depth(self : LineageTracker, child : String) -> Int {
  self.ancestors(child).length()
}

///|
/// Return the full lineage path from root to the given run.
pub fn LineageTracker::lineage_path(
  self : LineageTracker,
  child : String,
) -> Array[String] {
  let ancestors = self.ancestors(child)
  // Reverse to get root -> ... -> child
  let path : Array[String] = []
  for i = ancestors.length() - 1; i >= 0; i = i - 1 {
    path.push(ancestors[i])
  }
  path.push(child)
  path
}

///|
/// Return the total number of parent-child edges.
pub fn LineageTracker::edge_count(self : LineageTracker) -> Int {
  self.parent_of.length()
}

///|
/// Check if a run has a parent.
pub fn LineageTracker::has_parent(
  self : LineageTracker,
  child : String,
) -> Bool {
  self.find_parent(child) != ""
}

///|
/// Check if a run has children.
pub fn LineageTracker::has_children(
  self : LineageTracker,
  parent : String,
) -> Bool {
  self.children(parent).length() > 0
}

///|
/// Remove a parent-child relationship.
pub fn LineageTracker::remove_parent(
  self : LineageTracker,
  child : String,
) -> Result[Unit, LineageError] {
  let mut found = false
  let mut i = 0
  while i < self.parent_of.length() {
    let (c, _) = self.parent_of[i]
    if c == child {
      self.parent_of.remove(i) |> ignore
      found = true
    } else {
      i += 1
    }
  }
  if !found {
    return Err(NoParent(child))
  }
  Ok(())
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

///|
/// Find the parent of a child run id. Returns empty string if not found.
fn LineageTracker::find_parent(self : LineageTracker, child : String) -> String {
  for pair in self.parent_of {
    let (c, p) = pair
    if c == child {
      return p
    }
  }
  ""
}

///|
/// Check if setting `child`'s parent to `parent` would create a cycle.
fn LineageTracker::would_create_cycle(
  self : LineageTracker,
  child : String,
  parent : String,
) -> Bool {
  // If parent is a descendant of child, it would create a cycle
  let desc = self.descendants(child)
  for d in desc {
    if d == parent {
      return true
    }
  }
  // Also check if parent == child (already checked by caller, but be safe)
  if parent == child {
    return true
  }
  false
}

///|
/// Errors raised by lineage operations.
pub(all) enum LineageError {
  SelfParent(String)
  ParentAlreadySet(String)
  LineageCycle(String, String)
  NoParent(String)
} derive(Eq, Debug)

///|
/// Return a readable diagnostic for a lineage error.
pub fn LineageError::message(self : LineageError) -> String {
  match self {
    SelfParent(id) => "cannot set self as parent: \{id}"
    ParentAlreadySet(id) => "parent already set for: \{id}"
    LineageCycle(child, parent) =>
      "lineage cycle: setting \{parent} as parent of \{child} would create a cycle"
    NoParent(id) => "no parent found for: \{id}"
  }
}
