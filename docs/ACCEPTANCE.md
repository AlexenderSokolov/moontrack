# Acceptance Evidence

This page maps the OSC 2026 8月黑客松 acceptance requirements to reproducible
MoonTrack evidence.

| Requirement | Repository evidence | Reproduction or public evidence |
|---|---|---|
| MoonBit is the main language | Library, tests, demo, track, query, and bench CLI are `.mbt` sources | `moon check --deny-warn` |
| GitHub is public with clear history | Meaningful feature commits are retained | GitHub `main` must resolve to a public SHA |
| Source structure and core behavior are complete | Experiment, Run, Param, Metric, Artifact, ReproducibilityInfo, TrackingStore, query, compare, and export modules | `moon test --deny-warn` |
| README explains goal, installation, use, and examples | `README.md` and `README.zh.md` include `moon add`, `moon.pkg`, API, and CLI examples | Follow the repository quick start |
| CI covers check, build, and test | `.github/workflows/ci.yml` has Format, Typecheck, Build, Test, and Demo steps | Latest GitHub Actions `ci` run must succeed |
| At least one runnable example | Demo CLI, track CLI, query CLI, and bench CLI | `moon run cmd/demo`; `moon run cmd/track`; `moon run cmd/query`; `moon run cmd/bench` |
| Tests cover core paths | Experiment, run, param, metric, artifact, query, compare, and export tests | `moon test --deny-warn` reports 49 passing tests |
| Published to mooncakes.io | Module name is `AlexenderSokolov/moontrack` | Manifest must report `latest_version: 0.1.0`, `build_status: success`, and `has_package: true` |
| OSI-approved license and compliant sources | Root `LICENSE` is Apache-2.0; implementation and fixtures are original | Review `LICENSE` and the source statement in README |

## Local Acceptance Gate

```bash
moon fmt --check
moon info
git diff --exit-code -- '*.mbti'
moon check --deny-warn
moon build --deny-warn
moon test --deny-warn
moon run cmd/demo
moon run cmd/track
moon run cmd/query
moon run cmd/bench
```
