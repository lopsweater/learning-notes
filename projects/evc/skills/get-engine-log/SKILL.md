---
name: get-engine-log
description: 使用此技能收集、过滤和分析引擎执行日志，用于调试和验证目的。
origin: EVC
---

# 获取引擎日志

此技能收集和分析引擎执行日志，用于调试和验证。

## 激活时机

- 运行引擎可执行文件后
- 调试引擎问题时
- 验证功能时
- 收集日志进行分析时

## 日志收集模式

### 1. 文件模式
从文件收集日志：

```bash
# 从默认日志文件收集
get-engine-log --file ./logs/engine.log

# 从自定义路径收集
get-engine-log --file /var/log/engine/output.log
```

### 2. 实时模式
实时日志监控：

```bash
# 实时跟踪日志输出
get-engine-log --follow

# 带过滤器的实时跟踪
get-engine-log --follow --filter "ERROR|WARN"
```

### 3. 进程模式
附加到运行中的进程：

```bash
# 按进程名附加
get-engine-log --process engine

# 按 PID 附加
get-engine-log --pid 12345
```

## 日志过滤

### 按级别
```bash
# 仅错误
get-engine-log --level ERROR

# 警告及以上
get-engine-log --level WARN

# 所有日志
get-engine-log --level DEBUG
```

### 按时间范围
```bash
# 最近 5 分钟
get-engine-log --since "5m ago"

# 特定时间范围
get-engine-log --from "2024-01-01 10:00" --to "2024-01-01 11:00"
```

### 按关键字
```bash
# 按关键字过滤
get-engine-log --filter "RHI|Buffer"

# 排除模式
get-engine-log --exclude "Trace|Debug"
```

## 输出格式

### 文本格式（默认）
```
[2024-01-01 10:00:00] [INFO] 引擎初始化完成
[2024-01-01 10:00:01] [INFO] RHI 设备创建成功
[2024-01-01 10:00:02] [WARN] Buffer 池接近容量上限
```

### JSON 格式
```bash
get-engine-log --format json
```
```json
{
  "timestamp": "2024-01-01T10:00:00Z",
  "level": "INFO",
  "message": "引擎初始化完成",
  "source": "Engine.cpp:42"
}
```

### 摘要格式
```bash
get-engine-log --format summary
```
```
=== 日志摘要 ===
总条目: 1000
INFO: 950
WARN: 45
ERROR: 5
FATAL: 0

发现的错误:
- [10:00:15] 创建 Buffer 失败 (Buffer.cpp:100)
- [10:00:30] Texture 上传失败 (Texture.cpp:200)
```

## 日志分析

### 错误检测
```bash
# 检查错误
get-engine-log --check-errors

# 输出:
# 发现错误: 2
# 1. [ERROR] 创建 Buffer 失败
# 2. [ERROR] Texture 上传失败
```

### 内存泄漏检测
```bash
# 检查内存泄漏
get-engine-log --check-memory

# 输出:
# 内存摘要:
# 总分配次数: 1000
# 总释放次数: 998
# 潜在泄漏: 2
```

### 性能分析
```bash
# 分析性能日志
get-engine-log --check-performance

# 输出:
# 性能摘要:
# 帧时间: 16.2ms 平均, 25.3ms 最大
# GPU 时间: 12.5ms 平均
# CPU 时间: 3.7ms 平均
```

## 配置

### 日志文件路径
```bash
# 设置自定义日志路径
export ENGINE_LOG_PATH=/var/log/engine
get-engine-log
```

### 日志保留
```bash
# 收集最近 N 个日志文件
get-engine-log --retention 10
```

## 与开发工作流集成

### 构建后
```bash
# 运行引擎并收集日志
./build/bin/engine --test-mode &
get-engine-log --follow --output ./logs/test.log
```

### 用于验证
```bash
# 收集日志用于验证
get-engine-log --output ./logs/session.log

# 检查问题
grep -E "ERROR|FATAL" ./logs/session.log
```

## 配置模板（待补充）

以下是用户需要根据实际引擎配置的部分：

```yaml
# engine-log-config.yaml
# 用户根据实际引擎配置

log_source:
  type: file | stdout | network    # 日志源类型
  path: ./logs/engine.log          # 日志路径
  format: text | json | binary     # 日志格式

log_levels:
  - TRACE
  - DEBUG
  - INFO
  - WARN
  - ERROR
  - FATAL

filters:
  include:
    - pattern: ".*"
  exclude:
    - pattern: "Trace.*"

output:
  format: text | json | summary    # 输出格式
  file: ./logs/collected.log       # 输出文件
  console: true                    # 控制台输出

analysis:
  check_errors: true               # 检查错误
  check_memory: true               # 检查内存
  check_performance: true          # 检查性能
```

## 使用示例

### 基本收集
```bash
# 收集所有日志
get-engine-log --output ./logs/session.log
```

### 调试会话
```bash
# 运行引擎并收集日志
./build/bin/engine --debug 2>&1 | get-engine-log --follow --filter ERROR
```

### 验证报告
```bash
# 生成验证报告
get-engine-log --format summary --report ./reports/verification.md
```

## 检查清单

使用此技能时，请验证：

- [ ] 日志源可访问
- [ ] 日志格式正确
- [ ] 无 ERROR 级别日志
- [ ] 无 FATAL 级别日志
- [ ] 内存分配/释放平衡
- [ ] 初始化序列完整
- [ ] 关闭序列完整
- [ ] 无意外异常

---

**注意**: 这是一个模板技能。用户应根据其特定引擎日志系统自定义实现。
