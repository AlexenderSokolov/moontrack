# Changelog

## 0.1.0 - 2026-08-08

### Core

- Experiment and Run data models with lifecycle status tracking.
- Parameter model with int/float/bool/string type information.
- Metric model with step, timestamp, direction, and threshold.
- Artifact model with name, path, size, and checksum.
- Reproducibility info model: code version, command, environment, seed.
- TrackingStore: in-memory storage with state transitions and query.
- RunFilter: composite filter for status, tags, params, metric ranges.
- SortKey: sort runs by metric or parameter values.
- RunComparison: metric delta, percent change, and improvement detection.
- Markdown, JSON, and CSV export.
- Four CLI tools: demo, track, query, bench.

### Search Module

- ExperimentSearchFilter with name/description/tag matching (AND semantics).
- experiments_by_tag, experiments_by_name, search_experiments methods.
- run_status_summary, tag_summary, total_param/metric/artifact_count.
- Human-readable store summary output.
- add_experiment_tag and add_run_tag methods on TrackingStore.

### Lineage Tracking Module

- LineageTracker for parent-child relationships between runs.
- set_parent, has_parent, has_children, parent_of, children_of methods.
- ancestors, descendants, root, depth, lineage_path traversal.
- Cycle detection preventing self-parenting and circular references.
- LineageError enum with CycleDetected, SelfParent, RunNotInLineage variants.

### Enhanced Export Module

- detailed_csv: exports params+metrics columns alongside run status.
- comparison_report: multi-experiment markdown with best-run highlighting.
- lineage_tree_markdown: indented tree representation of run lineage.
- lineage_json: structured JSON export of lineage relationships.
- experiments_table_markdown: compact multi-experiment summary table.

### Statistics Module

- MetricSummary struct with count, min, max, mean, median, stddev.
- sort_doubles, median_doubles, percentile_doubles helper functions.
- metric_summary: comprehensive per-metric statistics across runs.
- all_metric_summaries: summaries for all metric keys in an experiment.
- metric_correlation: Pearson correlation between two metrics.
- statistics_report: Markdown report with summaries and correlations.
- MetricSummary methods: range, variance, coefficient_of_variation,
  percentile, q1, q3, iqr.

### Validation Module

- ValidationSeverity enum (Error, Warning) with kind/label methods.
- ValidationIssue struct with severity, code, message, run_id, experiment_id.
- ValidationResult struct with issue collection, count_by_severity, is_valid.
- Validation checks: empty experiment ids/names, unknown experiment
  references, runs with no metrics/params/reproducibility (warnings),
  negative metric steps, empty artifact paths, negative artifact sizes.
- ValidationResult::summary for human-readable report.

### Testing

- 129 tests covering core behavior, query, comparison, export, search,
  lineage, enhanced export, statistics, and validation.
- 5443 lines of effective MoonBit code.
