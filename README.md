# MoonTrack

MoonTrack is a MoonBit experiment tracking library for reproducible machine
learning and scientific research. It records experiment parameters, metrics,
artifacts, and run status, supports query/filter/sort/export, and provides
strict JSON serialization.

The project addresses a recurring need in ML workflows: experiment metadata
scattered across log files, spreadsheets, and chat messages. MoonTrack
extracts a small but useful layer into a standalone library that describes
what was run, what parameters were used, what metrics were produced, and
what artifacts were left behind.

Chinese documentation is available in [README.zh.md](README.zh.md).

## What It Does

- Defines experiments and runs with parameters, metrics, artifacts, and tags.
- Tracks run lifecycle: created → running → completed/failed/killed.
- Validates status transitions and rejects duplicate ids.
- Logs parameters (int/float/bool/string) with type information.
- Logs metrics with step, timestamp, direction, and threshold.
- Logs artifacts with name, path, size, and checksum.
- Records reproducibility info: code version, command, environment, seed.
- Queries runs by status, tags, parameters, and metric ranges.
- Sorts runs by metric or parameter values.
- Compares two runs and computes metric deltas with improvement detection.
- Exports Markdown reports, JSON snapshots, and CSV metric tables.

## What It Deliberately Leaves Out

- It does not persist to a database or filesystem.
- It does not call LLM APIs or execute shell commands.
- It does not provide a web UI or dashboard.
- It does not manage secrets or credentials.

## Installation

Add the published package to a MoonBit project:

```bash
moon add AlexenderSokolov/moontrack
```

Import it from the consuming package's `moon.pkg`:

```toml
import {
  "AlexenderSokolov/moontrack",
}
```

## Quick Start

```moonbit
let store = @moontrack.TrackingStore::new()
ignore(store.create_experiment("exp1", "My Experiment"))
ignore(store.start_run("run1", "exp1", "2026-01-01T00:00:00Z"))
ignore(store.log_param("run1", @moontrack.Param::new_float("lr", 0.01)))
ignore(store.log_metric("run1", @moontrack.Metric::new("accuracy", 0.95, 1, "t1")))
ignore(store.complete_run("run1", "2026-01-01T01:00:00Z"))

println(store.to_markdown())
println(store.to_json())
```

## CLI Tools

```bash
moon run cmd/demo     # Full demo: experiments, runs, comparison, query, CSV
moon run cmd/track    # Tracking CLI: create experiment, record runs
moon run cmd/query    # Query CLI: filter, sort, export
moon run cmd/bench    # Benchmark: 20 experiments × 50 runs
```

## Project Layout

```text
moontrack/
|-- experiment.mbt          # Experiment data model
|-- run.mbt                 # Run data model and lifecycle
|-- param.mbt               # Parameter model and type parsing
|-- metric.mbt              # Metric model, direction, threshold
|-- artifact.mbt            # Artifact model, checksum, metadata
|-- reproducibility.mbt     # Reproducibility info model
|-- tracking.mbt            # TrackingStore: core storage and state transitions
|-- query.mbt               # RunFilter and SortKey: query and sort
|-- compare.mbt             # RunComparison: metric delta and improvement
|-- export.mbt              # Markdown/JSON/CSV export
|-- tracking_test.mbt       # Core behavior tests
|-- query_test.mbt          # Query and filter tests
|-- compare_test.mbt        # Comparison framework tests
|-- export_test.mbt         # Export format tests
|-- cmd/demo/               # Full demo CLI
|-- cmd/track/              # Tracking CLI
|-- cmd/query/              # Query CLI
|-- cmd/bench/              # Benchmark CLI
|-- docs/                   # API, design, roadmap, acceptance
|-- CHANGELOG.md            # Versioned changes
|-- README.zh.md            # Chinese documentation
`-- PROJECT.md              # Project memory
```

## Repositories

- GitHub: <https://github.com/AlexenderSokolov/moontrack>
- Mooncakes: <https://mooncakes.io/docs/AlexenderSokolov/moontrack>

## License

Apache-2.0. See [LICENSE](LICENSE).
