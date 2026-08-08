# Design

## Goal

MoonTrack is a MoonBit library for experiment tracking in reproducible machine
learning and scientific research. It records experiment parameters, metrics,
artifacts, and run status.

The project comes from a practical problem. In ML workflows, experiment
metadata is scattered across log files, spreadsheets, and chat messages.
MoonTrack extracts that small but useful layer into a standalone library.

## Core Boundary

MoonTrack owns:

- experiment and run identity;
- parameter, metric, and artifact logging;
- run lifecycle and status transitions;
- query, filter, sort, and comparison;
- Markdown/JSON/CSV export.

MoonTrack does not own:

- persistent storage (filesystem or database);
- LLM provider calls;
- command execution;
- web UI or dashboard;
- secret management.

## Data Model

- `Experiment` groups related runs sharing the same research question.
- `Run` records parameters, metrics, artifacts, tags, and reproducibility info.
- `Param` stores a key-value pair with type information (int/float/bool/string).
- `Metric` stores a key-value pair with step, timestamp, direction, and threshold.
- `Artifact` stores a name, path, size, and optional checksum.
- `ReproducibilityInfo` stores code version, command, environment, random seed, and dependencies.

## Lifecycle Model

A run transitions through these statuses:

```
Created → Running → Completed
                   → Failed → Running (retry)
                   → Killed
```

- `Created → Running`: start a run.
- `Running → Completed`: successful completion.
- `Running → Failed`: failure with error message.
- `Running → Killed`: externally killed.
- `Failed → Running`: retry a failed run.
- `Completed` and `Killed` are terminal.

## Query Model

The query system provides two complementary primitives:

- `RunFilter`: composite filter combining status, tags, params, and metric ranges.
  All conditions must match (AND semantics).
- `SortKey`: sort runs by metric value or parameter value, ascending or descending.

## Comparison Model

The comparison framework compares a baseline run against a comparison run:

- For each metric key present in both runs, a `MetricDelta` is computed.
- The delta includes absolute difference, percent change, and improvement detection.
- Improvement is determined by the metric direction:
  - `HigherBetter`: comparison > baseline is improved.
  - `LowerBetter`: comparison < baseline is improved.
  - `None`: no improvement judgment is made.

## Export Model

Three export formats are provided:

- **Markdown**: human-readable experiment report with run tables.
- **JSON**: machine-readable complete tracking data with schema_version.
- **CSV**: metric table export for pandas/Excel analysis.

## Origin In ML Workflow Experience

The project idea is informed by maintaining experiment tracking in ML
research workflows. Those systems repeatedly need:

- explicit parameter logging with type information;
- metric logging with step and direction;
- artifact tracking with checksums;
- reproducibility metadata for reruns;
- query and comparison for result analysis.

MoonTrack extracts only the tracking layer. It leaves execution, storage,
and visualization to the systems that already own those concerns.
