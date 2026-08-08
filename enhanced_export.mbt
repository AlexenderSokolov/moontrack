///|
/// Export a detailed CSV with run id, status, all parameters, and all metrics
/// for an experiment.
///
/// The CSV has the following columns:
/// - run_id
/// - status
/// - start_time
/// - end_time
/// - one column per parameter key (value as string)
/// - one column per metric key (latest value as number)
pub fn TrackingStore::detailed_csv(
  self : TrackingStore,
  experiment_id : String,
) -> Result[String, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  // Collect all unique parameter keys
  let param_keys : Array[String] = []
  for run in runs {
    for p in run.parameters() {
      if !array_contains_string(param_keys, p.key()) {
        param_keys.push(p.key())
      }
    }
  }
  // Collect all unique metric keys
  let metric_keys : Array[String] = []
  for run in runs {
    for m in run.metrics() {
      if !array_contains_string(metric_keys, m.key()) {
        metric_keys.push(m.key())
      }
    }
  }
  let out = StringBuilder()
  // Header
  out <+ "run_id,status,start_time,end_time"
  for key in param_keys {
    out <+ ",param_\{key}"
  }
  for key in metric_keys {
    out <+ ",metric_\{key}"
  }
  out <+ "\n"
  // Rows
  for run in runs {
    out <+
      "\{run.id()},\{run.status().label()},\{run.start_time()},\{run.end_time()}"
    for key in param_keys {
      match run.find_param(key) {
        Some(p) => out <+ ",\{p.value()}"
        None => out <+ ","
      }
    }
    for key in metric_keys {
      match run.latest_metric(key) {
        Some(m) => out <+ ",\{m.value()}"
        None => out <+ ","
      }
    }
    out <+ "\n"
  }
  Ok(out.to_string())
}

///|
/// Export a multi-experiment comparison report as Markdown.
///
/// For each experiment, the report shows:
/// - Experiment name and id
/// - Number of runs
/// - Best run by the specified metric (if any runs exist)
/// - Run status summary
pub fn TrackingStore::comparison_report(
  self : TrackingStore,
  metric_key : String,
) -> String {
  let out = StringBuilder()
  out <+ "# Multi-Experiment Comparison Report\n\n"
  if self.experiments.is_empty() {
    out <+ "No experiments recorded.\n"
    return out.to_string()
  }
  for exp in self.experiments {
    out <+ "## \{exp.name()}\n\n"
    out <+ "- **ID**: `\{exp.id()}`\n"
    out <+ "- **Runs**: \{exp.run_count()}\n"
    let runs = self.runs_for_experiment(exp.id())
    if runs.is_empty() {
      out <+ "- **Best run**: N/A (no runs)\n"
    } else {
      match self.best_run(exp.id(), metric_key) {
        Ok(best) => {
          let val = match best.latest_metric(metric_key) {
            Some(m) => m.value()
            None => 0.0
          }
          out <+ "- **Best run**: `\{best.id()}` (\{metric_key}=\{val})\n"
        }
        Err(_) => out <+ "- **Best run**: N/A (metric not found)\n"
      }
    }
    // Status summary
    let mut completed = 0
    let mut failed = 0
    let mut running = 0
    let mut other = 0
    for run in runs {
      match run.status() {
        Completed => completed += 1
        Failed => failed += 1
        Running => running += 1
        _ => other += 1
      }
    }
    out <+
      "- **Status**: \{completed} completed, \{failed} failed, \{running} running, \{other} other\n\n"
  }
  out.to_string()
}

///|
/// Export a run lineage tree as a Markdown nested list.
pub fn TrackingStore::lineage_tree_markdown(
  self : TrackingStore,
  lineage : LineageTracker,
  experiment_id : String,
) -> Result[String, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  let out = StringBuilder()
  out <+ "## Run Lineage Tree\n\n"
  // Find root runs (no parent)
  let roots : Array[String] = []
  for run in runs {
    if !lineage.has_parent(run.id()) {
      roots.push(run.id())
    }
  }
  if roots.is_empty() {
    out <+ "_No root runs found._\n"
    return Ok(out.to_string())
  }
  for root in roots {
    render_lineage_node(root, lineage, out, 0)
  }
  Ok(out.to_string())
}

///|
/// Recursively render a lineage node as a Markdown list item.
fn render_lineage_node(
  run_id : String,
  lineage : LineageTracker,
  out : StringBuilder,
  depth : Int,
) -> Unit {
  for i = 0; i < depth; i = i + 1 {
    out <+ "  "
  }
  out <+ "- `\{run_id}`\n"
  let kids = lineage.children(run_id)
  for kid in kids {
    render_lineage_node(kid, lineage, out, depth + 1)
  }
}

///|
/// Export a summary table of all experiments as Markdown.
pub fn TrackingStore::experiments_table_markdown(
  self : TrackingStore,
) -> String {
  let out = StringBuilder()
  out <+ "## Experiments Summary\n\n"
  out <+ "| ID | Name | Runs | Created |\n"
  out <+ "|----|------|------|---------|\n"
  for exp in self.experiments {
    out <+
      "| `\{exp.id()}` | \{exp.name()} | \{exp.run_count()} | \{exp.created_at()} |\n"
  }
  out.to_string()
}

///|
/// Export a JSON representation of the lineage tree.
pub fn TrackingStore::lineage_json(
  self : TrackingStore,
  lineage : LineageTracker,
  experiment_id : String,
) -> Result[String, TrackingError] {
  match self.get_experiment(experiment_id) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let runs = self.runs_for_experiment(experiment_id)
  let out = StringBuilder()
  out <+ "{\n"
  out <+ "  \"experiment_id\": \"\{escape_json(experiment_id)}\",\n"
  out <+ "  \"lineage\": [\n"
  let roots : Array[String] = []
  for run in runs {
    if !lineage.has_parent(run.id()) {
      roots.push(run.id())
    }
  }
  let mut first = true
  for root in roots {
    if !first {
      out <+ ",\n"
    }
    first = false
    render_lineage_json_node(root, lineage, out, 1)
  }
  out <+ "\n  ]\n"
  out <+ "}"
  Ok(out.to_string())
}

///|
/// Recursively render a lineage node as JSON.
fn render_lineage_json_node(
  run_id : String,
  lineage : LineageTracker,
  out : StringBuilder,
  indent : Int,
) -> Unit {
  let pad = "  ".repeat(indent)
  out <+ "\{pad}{\n"
  out <+ "\{pad}  \"run_id\": \"\{escape_json(run_id)}\",\n"
  let kids = lineage.children(run_id)
  if kids.is_empty() {
    out <+ "\{pad}  \"children\": []\n"
  } else {
    out <+ "\{pad}  \"children\": [\n"
    let mut first = true
    for kid in kids {
      if !first {
        out <+ ",\n"
      }
      first = false
      render_lineage_json_node(kid, lineage, out, indent + 2)
    }
    out <+ "\n\{pad}  ]\n"
  }
  out <+ "\{pad}}"
}
