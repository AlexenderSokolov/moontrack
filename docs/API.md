# Public API

MoonTrack keeps its public surface small. A caller creates a store, logs
experiments and runs, queries and compares, and exports results.

## TrackingStore

- `TrackingStore::new()` creates an empty store.
- `create_experiment(id, name)` rejects duplicate experiment ids.
- `get_experiment(id)` returns a detached experiment copy.
- `list_experiments()` returns all experiment ids.
- `experiment_count()` returns the number of experiments.
- `start_run(run_id, experiment_id, start_time)` creates a run in `Running` status.
- `get_run(run_id)` returns a detached run copy.
- `list_runs()` returns all run ids.
- `run_count()` returns the number of runs.
- `complete_run(run_id, end_time)` transitions to `Completed`.
- `fail_run(run_id, end_time, error_message)` transitions to `Failed`.
- `kill_run(run_id, end_time)` transitions to `Killed`.
- `log_param(run_id, param)` logs a parameter on a run.
- `log_metric(run_id, metric)` logs a metric on a run.
- `log_artifact(run_id, artifact)` logs an artifact on a run.
- `set_reproducibility(run_id, info)` sets reproducibility info on a run.
- `add_note(run_id, note)` adds a note to a run.
- `runs_for_experiment(experiment_id)` returns all runs for an experiment.
- `all_runs()` returns all runs in the store.
- `search_runs(filter, sort)` returns runs matching the filter, sorted by the sort key.
- `compare_runs(baseline_id, comparison_id)` compares two runs by metric.
- `to_markdown()` renders a Markdown report.
- `to_json()` renders a JSON string.
- `run_markdown(run_id)` renders a detailed Markdown report for a single run.
- `metrics_csv(experiment_id)` exports metrics for all runs in an experiment as CSV.

## Experiment

- `Experiment::new(id, name)` creates an experiment.
- `Experiment::with_description(desc)` adds a description.
- `Experiment::with_tags(tags)` adds tags.
- `Experiment::with_created_at(ts)` sets the creation timestamp.
- `Experiment::with_metadata(meta)` sets metadata entries.
- `id()`, `name()`, `description()`, `tags()`, `created_at()`, `metadata()`.
- `run_count()`, `run_ids()`, `find_run(run_id)`.

## Run

- `Run::new(id, experiment_id)` creates a run in `Created` status.
- `Run::with_start_time(ts)` sets the start timestamp.
- `Run::with_tags(tags)` adds tags.
- `Run::with_reproducibility(info)` sets reproducibility info.
- `Run::with_error_message(msg)` sets the error message.
- `Run::set_status(status)` sets the status directly (for importers).
- `Run::set_end_time(ts)` sets the end time directly.
- `id()`, `experiment_id()`, `status()`, `start_time()`, `end_time()`.
- `parameters()`, `metrics()`, `artifacts()`, `tags()`, `notes()`.
- `reproducibility()`, `error_message()`.
- `param_count()`, `metric_count()`, `artifact_count()`.
- `find_param(key)`, `latest_metric(key)`, `metrics_for(key)`.

## Param

- `Param::new_int(key, value)`, `new_float(key, value)`, `new_bool(key, value)`, `new_string(key, value)`.
- `Param::with_description(desc)` adds a description.
- `key()`, `value()`, `type_()`, `description()`.

## Metric

- `Metric::new(key, value, step, timestamp)` creates a metric.
- `Metric::with_direction(dir)` sets the metric direction.
- `Metric::with_threshold(t)` sets the metric threshold.
- `key()`, `value()`, `step()`, `timestamp()`, `direction()`, `threshold()`.

## Artifact

- `Artifact::new(name, path, size)` creates an artifact.
- `Artifact::with_checksum(cs)` sets the checksum.
- `Artifact::with_metadata(meta)` sets metadata entries.
- `name()`, `path()`, `size()`, `checksum()`, `metadata()`.

## ReproducibilityInfo

- `ReproducibilityInfo::new(code_version, command)` creates reproducibility info.
- `ReproducibilityInfo::with_environment(env)` sets the environment map.
- `ReproducibilityInfo::with_random_seed(seed)` sets the random seed.
- `ReproducibilityInfo::with_dependencies(deps)` sets the dependency list.
- `code_version()`, `command()`, `environment()`, `random_seed()`, `dependencies()`.

## RunFilter

- `RunFilter::new()` creates an empty filter that matches everything.
- `with_statuses(statuses)` restricts to runs with one of the given statuses.
- `with_tags_any(tags)` restricts to runs that have at least one of the given tags.
- `with_param(key, value)` restricts to runs that have a parameter with the given key and value.
- `with_metric_min(key, min)` restricts to runs whose latest metric for `key` is at least `min`.
- `with_metric_max(key, max)` restricts to runs whose latest metric for `key` is at most `max`.
- `matches(run)` tests whether a single run matches this filter.

## SortKey

- `SortKey::by_metric_ascending(key)` sorts runs by a metric value in ascending order.
- `SortKey::by_metric_descending(key)` sorts runs by a metric value in descending order.
- `SortKey::by_param_ascending(key)` sorts runs by a parameter value in ascending order.
- `SortKey::by_param_descending(key)` sorts runs by a parameter value in descending order.

## RunComparison

- `TrackingStore::compare_runs(baseline_id, comparison_id)` compares two runs.
- `baseline_id()`, `comparison_id()`.
- `deltas()` returns all metric deltas.
- `added_keys()` returns metric keys only in the comparison run.
- `removed_keys()` returns metric keys only in the baseline run.

## MetricDelta

- `key()`, `baseline_value()`, `comparison_value()`.
- `delta()` returns the absolute delta (comparison - baseline).
- `percent_change()` returns the percent change relative to baseline.
- `direction()` returns the metric direction.
- `improved()` returns whether the comparison run improved on this metric.

## Errors

- `TrackingError` covers duplicate experiments/runs, missing experiments/runs, invalid status transitions, and duplicate parameters.
- `TrackingError::message()` returns a readable diagnostic string.
