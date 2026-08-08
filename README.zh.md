# MoonTrack

MoonTrack 是一个用 MoonBit 实现的实验追踪库，面向可复现的机器学习和科研工作流。它记录实验参数、指标、产物和运行状态，支持查询/过滤/排序/导出，并提供严格的 JSON 序列化。

本项目解决的是机器学习工作流中反复出现的问题：实验元数据散落在日志文件、电子表格和聊天记录中。MoonTrack 把这一小但关键的层抽成独立库，记录"跑了什么实验、用了什么参数、产生了什么指标、留下了什么产物"。

## 核心功能

- 定义实验和运行，携带参数、指标、产物和标签
- 追踪运行生命周期：created → running → completed/failed/killed
- 校验状态转换，拒绝重复 id
- 记录参数（int/float/bool/string）及类型信息
- 记录指标（step、timestamp、direction、threshold）
- 记录产物（name、path、size、checksum）
- 记录可复现性信息（code version、command、environment、seed）
- 按状态/标签/参数/指标范围查询运行
- 按指标或参数值排序运行
- 比较两个运行，计算指标差值和改善/恶化判断
- 导出 Markdown 报告、JSON 快照和 CSV 指标表

## 安装

```bash
moon add AlexenderSokolov/moontrack
```

在消费包的 `moon.pkg` 中导入：

```toml
import {
  "AlexenderSokolov/moontrack",
}
```

## 快速开始

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

## CLI 工具

```bash
moon run cmd/demo     # 完整示例：实验、运行、比较、查询、CSV
moon run cmd/track    # 追踪 CLI：创建实验、记录运行
moon run cmd/query    # 查询 CLI：过滤、排序、导出
moon run cmd/bench    # 基准测试：20 实验 × 50 运行
```

## 许可证

Apache-2.0。详见 [LICENSE](LICENSE)。
