///|
/// A composite filter for searching runs.
///
/// All specified conditions must match (AND semantics). An empty filter
/// matches all runs.
pub struct RunFilter {
  priv statuses : Array[RunStatus]
  priv tags_any : Array[String]
  priv params_match : Array[(String, String)]
  priv metric_min : Array[(String, Double)]
  priv metric_max : Array[(String, Double)]
} derive(Debug)

///|
/// Build an empty run filter that matches everything.
pub fn RunFilter::new() -> RunFilter {
  {
    statuses: [],
    tags_any: [],
    params_match: [],
    metric_min: [],
    metric_max: [],
  }
}

///|
/// Restrict to runs with one of the given statuses.
pub fn RunFilter::with_statuses(
  self : RunFilter,
  statuses : Array[RunStatus],
) -> RunFilter {
  { ..self, statuses: statuses.copy() }
}

///|
/// Restrict to runs that have at least one of the given tags.
pub fn RunFilter::with_tags_any(
  self : RunFilter,
  tags : Array[String],
) -> RunFilter {
  { ..self, tags_any: tags.copy() }
}

///|
/// Restrict to runs that have a parameter with the given key and value.
pub fn RunFilter::with_param(
  self : RunFilter,
  key : String,
  value : String,
) -> RunFilter {
  let mut updated = self.params_match.copy()
  updated.push((key, value))
  { ..self, params_match: updated }
}

///|
/// Restrict to runs whose latest metric for `key` is at least `min`.
pub fn RunFilter::with_metric_min(
  self : RunFilter,
  key : String,
  min : Double,
) -> RunFilter {
  let mut updated = self.metric_min.copy()
  updated.push((key, min))
  { ..self, metric_min: updated }
}

///|
/// Restrict to runs whose latest metric for `key` is at most `max`.
pub fn RunFilter::with_metric_max(
  self : RunFilter,
  key : String,
  max : Double,
) -> RunFilter {
  let mut updated = self.metric_max.copy()
  updated.push((key, max))
  { ..self, metric_max: updated }
}

///|
/// Test whether a single run matches this filter.
pub fn RunFilter::matches(self : RunFilter, run : Run) -> Bool {
  // Status check
  if self.statuses.length() > 0 {
    let mut found = false
    for s in self.statuses {
      if run.status() == s {
        found = true
        break
      }
    }
    if !found {
      return false
    }
  }
  // Tags check (at least one must match)
  if self.tags_any.length() > 0 {
    let run_tags = run.tags()
    let mut found = false
    for t in self.tags_any {
      for rt in run_tags {
        if t == rt {
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
  // Params check
  if self.params_match.length() > 0 {
    for pair in self.params_match {
      let (key, expected) = pair
      match run.find_param(key) {
        Some(p) => if p.value() != expected { return false }
        None => return false
      }
    }
  }
  // Metric min check
  if self.metric_min.length() > 0 {
    for pair in self.metric_min {
      let (key, min_val) = pair
      match run.latest_metric(key) {
        Some(m) => if m.value() < min_val { return false }
        None => return false
      }
    }
  }
  // Metric max check
  if self.metric_max.length() > 0 {
    for pair in self.metric_max {
      let (key, max_val) = pair
      match run.latest_metric(key) {
        Some(m) => if m.value() > max_val { return false }
        None => return false
      }
    }
  }
  true
}

///|
/// Sort key for ordering runs by a metric or parameter value.
pub struct SortKey {
  priv key : String
  priv ascending : Bool
  priv by_metric : Bool
} derive(Debug)

///|
/// Build a sort key that sorts runs by a metric value in ascending order.
pub fn SortKey::by_metric_ascending(key : String) -> SortKey {
  { key, ascending: true, by_metric: true }
}

///|
/// Build a sort key that sorts runs by a metric value in descending order.
pub fn SortKey::by_metric_descending(key : String) -> SortKey {
  { key, ascending: false, by_metric: true }
}

///|
/// Build a sort key that sorts runs by a parameter value in ascending order.
pub fn SortKey::by_param_ascending(key : String) -> SortKey {
  { key, ascending: true, by_metric: false }
}

///|
/// Build a sort key that sorts runs by a parameter value in descending order.
pub fn SortKey::by_param_descending(key : String) -> SortKey {
  { key, ascending: false, by_metric: false }
}

///|
/// Search runs in the store that match the given filter.
/// Returns detached copies sorted by the given sort key (if any).
pub fn TrackingStore::search_runs(
  self : TrackingStore,
  filter : RunFilter,
  sort : SortKey?,
) -> Array[Run] {
  let result : Array[Run] = []
  for run in self.runs {
    if filter.matches(run) {
      result.push(run)
    }
  }
  match sort {
    None => result
    Some(sk) => sort_runs(result, sk)
  }
}

///|
/// Sort an array of runs by the given sort key.
fn sort_runs(runs : Array[Run], sk : SortKey) -> Array[Run] {
  // Simple insertion sort to avoid closure complexity.
  let arr = runs.copy()
  for i = 1; i < arr.length(); i = i + 1 {
    let mut j = i
    while j > 0 && compare_runs(arr[j - 1], arr[j], sk) > 0 {
      let temp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = temp
      j = j - 1
    }
  }
  arr
}

///|
/// Compare two runs according to a sort key. Returns -1, 0, or 1.
fn compare_runs(a : Run, b : Run, sk : SortKey) -> Int {
  if sk.by_metric {
    let va = match a.latest_metric(sk.key) {
      Some(m) => m.value()
      None => return 1 // runs without the metric go last
    }
    let vb = match b.latest_metric(sk.key) {
      Some(m) => m.value()
      None => return -1
    }
    if sk.ascending {
      if va < vb {
        return -1
      }
      if va > vb {
        return 1
      }
      return 0
    } else {
      if va > vb {
        return -1
      }
      if va < vb {
        return 1
      }
      return 0
    }
  } else {
    let va = match a.find_param(sk.key) {
      Some(p) => p.value()
      None => return 1
    }
    let vb = match b.find_param(sk.key) {
      Some(p) => p.value()
      None => return -1
    }
    if sk.ascending {
      if va < vb {
        return -1
      }
      if va > vb {
        return 1
      }
      return 0
    } else {
      if va > vb {
        return -1
      }
      if va < vb {
        return 1
      }
      return 0
    }
  }
}
