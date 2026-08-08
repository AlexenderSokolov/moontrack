# Changelog

## 0.1.0 - 2026-08-08

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
- 49 tests covering core behavior, query, comparison, and export.
