///|
/// Render a human-readable Markdown report for the entire tracking store.
pub fn TrackingStore::to_markdown(self : TrackingStore) -> String {
  let out = StringBuilder()
  out <+ "# MoonTrack Experiment Report\n\n"
  if self.experiments.is_empty() {
    out <+ "No experiments recorded.\n"
    return out.to_string()
  }
  for exp in self.experiments {
    out <+ "## Experiment: \{exp.name()}\n\n"
    out <+ "- **ID**: `\{exp.id()}`\n"
    if exp.description() != "" {
      out <+ "- **Description**: \{exp.description()}\n"
    }
    out <+ "- **Runs**: \{exp.run_count()}\n"
    let tags = exp.tags()
    if tags.length() > 0 {
      out <+ "- **Tags**: "
      for i = 0; i < tags.length(); i = i + 1 {
        if i > 0 {
          out <+ ", "
        }
        out <+ "`\{tags[i]}`"
      }
      out <+ "\n"
    }
    out <+ "\n"
    // List runs for this experiment
    let runs = self.runs_for_experiment(exp.id())
    if runs.is_empty() {
      out <+ "_No runs yet._\n\n"
    } else {
      out <+ "### Runs\n\n"
      out <+
        "| Run ID | Status | Start | End | Params | Metrics | Artifacts |\n"
      out <+ "|--------|--------|-------|-----|--------|---------|----------|\n"
      for run in runs {
        let id = run.id()
        let status = run.status().label()
        let start = run.start_time()
        let end = if run.end_time() == "" { "-" } else { run.end_time() }
        let params = run.param_count()
        let metrics = run.metric_count()
        let artifacts = run.artifact_count()
        out <+
          "| `\{id}` | \{status} | \{start} | \{end} | \{params} | \{metrics} | \{artifacts} |\n"
      }
      out <+ "\n"
    }
  }
  out.to_string()
}

///|
/// Render a detailed Markdown report for a single run.
pub fn TrackingStore::run_markdown(
  self : TrackingStore,
  run_id : String,
) -> Result[String, TrackingError] {
  let run = match self.get_run(run_id) {
    Err(err) => return Err(err)
    Ok(r) => r
  }
  let out = StringBuilder()
  out <+ "## Run: `\{run.id()}`\n\n"
  out <+ "- **Experiment**: `\{run.experiment_id()}`\n"
  out <+ "- **Status**: \{run.status().label()}\n"
  out <+ "- **Start**: \{run.start_time()}\n"
  if run.end_time() != "" {
    out <+ "- **End**: \{run.end_time()}\n"
  }
  if run.error_message() != "" {
    out <+ "- **Error**: \{run.error_message()}\n"
  }
  let tags = run.tags()
  if tags.length() > 0 {
    out <+ "- **Tags**: "
    for i = 0; i < tags.length(); i = i + 1 {
      if i > 0 {
        out <+ ", "
      }
      out <+ "`\{tags[i]}`"
    }
    out <+ "\n"
  }
  // Parameters
  let params = run.parameters()
  if params.length() > 0 {
    out <+ "\n### Parameters\n\n"
    out <+ "| Key | Value | Type |\n"
    out <+ "|-----|-------|------|\n"
    for p in params {
      out <+ "| `\{p.key()}` | \{p.value()} | \{p.type_().label()} |\n"
    }
  }
  // Metrics
  let metrics = run.metrics()
  if metrics.length() > 0 {
    out <+ "\n### Metrics\n\n"
    out <+ "| Key | Value | Step | Direction |\n"
    out <+ "|-----|-------|------|----------|\n"
    for m in metrics {
      out <+
        "| `\{m.key()}` | \{m.value()} | \{m.step()} | \{m.direction().label()} |\n"
    }
  }
  // Artifacts
  let artifacts = run.artifacts()
  if artifacts.length() > 0 {
    out <+ "\n### Artifacts\n\n"
    out <+ "| Name | Path | Size |\n"
    out <+ "|------|------|------|\n"
    for a in artifacts {
      out <+ "| `\{a.name()}` | \{a.path()} | \{a.size()} |\n"
    }
  }
  // Reproducibility
  match run.reproducibility() {
    Some(info) => {
      out <+ "\n### Reproducibility\n\n"
      out <+ "- **Code version**: `\{info.code_version()}`\n"
      out <+ "- **Command**: `\{info.command()}`\n"
      match info.random_seed() {
        Some(seed) => out <+ "- **Random seed**: \{seed}\n"
        None => ()
      }
    }
    None => ()
  }
  Ok(out.to_string())
}

///|
/// Render the entire tracking store as a JSON string.
pub fn TrackingStore::to_json(self : TrackingStore) -> String {
  let out = StringBuilder()
  out <+ "{\n"
  out <+ "  \"schema_version\": 1,\n"
  out <+ "  \"experiments\": ["
  if self.experiments.is_empty() {
    out <+ "],\n"
  } else {
    out <+ "\n"
    for i = 0; i < self.experiments.length(); i = i + 1 {
      if i > 0 {
        out <+ ",\n"
      }
      self.experiments[i].render_json(out)
    }
    out <+ "\n  ],\n"
  }
  out <+ "  \"runs\": ["
  if self.runs.is_empty() {
    out <+ "]\n"
  } else {
    out <+ "\n"
    for i = 0; i < self.runs.length(); i = i + 1 {
      if i > 0 {
        out <+ ",\n"
      }
      self.runs[i].render_json(out)
    }
    out <+ "\n  ]\n"
  }
  out <+ "}"
  out.to_string()
}

///|
/// Render an experiment as JSON.
fn Experiment::render_json(self : Experiment, out : StringBuilder) -> Unit {
  out <+ "  {\n"
  out <+ "    \"id\": \"\{escape_json(self.id())}\",\n"
  out <+ "    \"name\": \"\{escape_json(self.name())}\",\n"
  out <+ "    \"description\": \"\{escape_json(self.description())}\",\n"
  // Tags
  let tags = self.tags()
  out <+ "    \"tags\": ["
  for i = 0; i < tags.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    out <+ "\"\{escape_json(tags[i])}\""
  }
  out <+ "],\n"
  out <+ "    \"created_at\": \"\{escape_json(self.created_at())}\",\n"
  // Metadata
  let meta = self.metadata()
  let meta_keys : Array[String] = []
  meta.each(fn(k, _v) { meta_keys.push(k) })
  out <+ "    \"metadata\": {"
  for i = 0; i < meta_keys.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let k = meta_keys[i]
    let v = match meta.get(k) {
      Some(v) => v
      None => ""
    }
    out <+ "\"\{escape_json(k)}\": \"\{escape_json(v)}\""
  }
  out <+ "},\n"
  // Run IDs
  let run_ids = self.run_ids()
  out <+ "    \"run_ids\": ["
  for i = 0; i < run_ids.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    out <+ "\"\{escape_json(run_ids[i])}\""
  }
  out <+ "]\n"
  out <+ "  }"
}

///|
/// Render a run as JSON.
fn Run::render_json(self : Run, out : StringBuilder) -> Unit {
  out <+ "  {\n"
  out <+ "    \"id\": \"\{escape_json(self.id())}\",\n"
  out <+ "    \"experiment_id\": \"\{escape_json(self.experiment_id())}\",\n"
  out <+ "    \"status\": \"\{self.status().label()}\",\n"
  out <+ "    \"start_time\": \"\{escape_json(self.start_time())}\",\n"
  out <+ "    \"end_time\": \"\{escape_json(self.end_time())}\",\n"
  out <+ "    \"error_message\": \"\{escape_json(self.error_message())}\",\n"
  // Tags
  let tags = self.tags()
  out <+ "    \"tags\": ["
  for i = 0; i < tags.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    out <+ "\"\{escape_json(tags[i])}\""
  }
  out <+ "],\n"
  // Parameters
  let params = self.parameters()
  out <+ "    \"parameters\": ["
  if params.length() == 0 {
    out <+ "],\n"
  } else {
    out <+ "\n"
    for i = 0; i < params.length(); i = i + 1 {
      if i > 0 {
        out <+ ",\n"
      }
      out <+ "      {"
      out <+ "\"key\": \"\{escape_json(params[i].key())}\", "
      out <+ "\"value\": \"\{escape_json(params[i].value())}\", "
      out <+ "\"type\": \"\{params[i].type_().kind()}\""
      out <+ "}"
    }
    out <+ "\n    ],\n"
  }
  // Metrics
  let metrics = self.metrics()
  out <+ "    \"metrics\": ["
  if metrics.length() == 0 {
    out <+ "],\n"
  } else {
    out <+ "\n"
    for i = 0; i < metrics.length(); i = i + 1 {
      if i > 0 {
        out <+ ",\n"
      }
      out <+ "      {"
      out <+ "\"key\": \"\{escape_json(metrics[i].key())}\", "
      out <+ "\"value\": \{metrics[i].value()}, "
      out <+ "\"step\": \{metrics[i].step()}, "
      out <+ "\"timestamp\": \"\{escape_json(metrics[i].timestamp())}\", "
      out <+ "\"direction\": \"\{metrics[i].direction().kind()}\""
      out <+ "}"
    }
    out <+ "\n    ],\n"
  }
  // Artifacts
  let artifacts = self.artifacts()
  out <+ "    \"artifacts\": ["
  if artifacts.length() == 0 {
    out <+ "],\n"
  } else {
    out <+ "\n"
    for i = 0; i < artifacts.length(); i = i + 1 {
      if i > 0 {
        out <+ ",\n"
      }
      out <+ "      {"
      out <+ "\"name\": \"\{escape_json(artifacts[i].name())}\", "
      out <+ "\"path\": \"\{escape_json(artifacts[i].path())}\", "
      out <+ "\"size\": \{artifacts[i].size()}"
      match artifacts[i].checksum() {
        Some(cs) => out <+ ", \"checksum\": \"\{escape_json(cs)}\""
        None => ()
      }
      out <+ "}"
    }
    out <+ "\n    ],\n"
  }
  // Reproducibility
  match self.reproducibility() {
    Some(info) => {
      out <+ "    \"reproducibility\": {\n"
      out <+
        "      \"code_version\": \"\{escape_json(info.code_version())}\",\n"
      out <+ "      \"command\": \"\{escape_json(info.command())}\",\n"
      out <+ "      \"random_seed\": "
      match info.random_seed() {
        Some(seed) => out <+ "\{seed},\n"
        None => out <+ "null,\n"
      }
      out <+ "      \"environment\": {"
      let env = info.environment()
      let env_keys : Array[String] = []
      env.each(fn(k, _v) { env_keys.push(k) })
      for i = 0; i < env_keys.length(); i = i + 1 {
        if i > 0 {
          out <+ ", "
        }
        let k = env_keys[i]
        let v = match env.get(k) {
          Some(v) => v
          None => ""
        }
        out <+ "\"\{escape_json(k)}\": \"\{escape_json(v)}\""
      }
      out <+ "},\n"
      let deps = info.dependencies()
      out <+ "      \"dependencies\": ["
      for i = 0; i < deps.length(); i = i + 1 {
        if i > 0 {
          out <+ ", "
        }
        out <+ "\"\{escape_json(deps[i])}\""
      }
      out <+ "]\n"
      out <+ "    }\n"
    }
    None => out <+ "    \"reproducibility\": null\n"
  }
  out <+ "  }"
}

///|
/// Export metrics for all runs in an experiment as CSV.
pub fn TrackingStore::metrics_csv(
  self : TrackingStore,
  experiment_id : String,
) -> Result[String, TrackingError] {
  // Verify experiment exists
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  // Collect all unique metric keys across all runs
  let all_keys : Array[String] = []
  for run in runs {
    for m in run.metrics() {
      if !array_contains_string(all_keys, m.key()) {
        all_keys.push(m.key())
      }
    }
  }
  let out = StringBuilder()
  // Header
  out <+ "run_id,status"
  for key in all_keys {
    out <+ ",\{key}"
  }
  out <+ "\n"
  // Rows
  for run in runs {
    out <+ "\{run.id()},\{run.status().label()}"
    for key in all_keys {
      match run.latest_metric(key) {
        Some(m) => out <+ ",\{m.value()}"
        None => out <+ ","
      }
    }
    out <+ "\n"
  }
  Ok(out.to_string())
}

// ---------------------------------------------------------------------------
// JSON helpers
// ---------------------------------------------------------------------------

///|
/// Escape a string for safe JSON output.
fn escape_json(s : String) -> String {
  let out = StringBuilder()
  for ch in s {
    match ch {
      '"' => out <+ "\\\""
      '\\' => out <+ "\\\\"
      '\n' => out <+ "\\n"
      '\r' => out <+ "\\r"
      '\t' => out <+ "\\t"
      _ => {
        let code = ch.to_int()
        if code < 0x20 {
          out <+ "\\u00"
          out.write_string(hex_digit(code / 16))
          out.write_string(hex_digit(code % 16))
        } else {
          out <+ "\{ch}"
        }
      }
    }
  }
  out.to_string()
}

///|
/// Return a single hex digit for values 0..15.
fn hex_digit(value : Int) -> String {
  match value {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}
