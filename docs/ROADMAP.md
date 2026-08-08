# Roadmap

## v0.1.0 (Current)

- Experiment and Run data models with lifecycle status tracking.
- Parameter model with int/float/bool/string type information.
- Metric model with step, timestamp, direction, and threshold.
- Artifact model with name, path, size, and checksum.
- Reproducibility info model: code version, command, environment, seed.
- TrackingStore: in-memory storage with state transitions.
- RunFilter: composite filter for status, tags, params, metric ranges.
- SortKey: sort runs by metric or parameter values.
- RunComparison: metric delta, percent change, and improvement detection.
- Markdown, JSON, and CSV export.
- Four CLI tools: demo, track, query, bench.
- 49 tests covering core behavior, query, comparison, and export.

## v0.2.0 (Planned)

- JSON import with strict schema validation.
- Experiment metadata search (by name, description, tags).
- Metric aggregation across runs (min, max, mean, std).
- Run lineage tracking (parent-child relationships).
- Enhanced CSV export with parameter columns.

## v0.3.0 (Future)

- File-based persistence for experiments and runs.
- Experiment comparison across multiple experiments.
- Metric threshold validation and alerting.
- Bulk import/export for experiment collections.
