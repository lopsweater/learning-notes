---
name: get-engine-log
description: Use this skill to collect, filter, and analyze engine execution logs for debugging and verification purposes.
origin: EVC
---

# Get Engine Log

This skill collects and analyzes engine execution logs for debugging and verification.

## When to Activate

- After running engine executable
- When debugging engine issues
- When verifying functionality
- When collecting logs for analysis

## Log Collection Modes

### 1. File Mode
Collect logs from file:

```bash
# Collect from default log file
get-engine-log --file ./logs/engine.log

# Collect from custom path
get-engine-log --file /var/log/engine/output.log
```

### 2. Follow Mode
Real-time log monitoring:

```bash
# Follow log output
get-engine-log --follow

# Follow with filter
get-engine-log --follow --filter "ERROR|WARN"
```

### 3. Process Mode
Attach to running process:

```bash
# Attach to process by name
get-engine-log --process engine

# Attach by PID
get-engine-log --pid 12345
```

## Log Filtering

### By Level
```bash
# Only errors
get-engine-log --level ERROR

# Warnings and above
get-engine-log --level WARN

# All logs
get-engine-log --level DEBUG
```

### By Time Range
```bash
# Last 5 minutes
get-engine-log --since "5m ago"

# Specific time range
get-engine-log --from "2024-01-01 10:00" --to "2024-01-01 11:00"
```

### By Keyword
```bash
# Filter by keyword
get-engine-log --filter "RHI|Buffer"

# Exclude pattern
get-engine-log --exclude "Trace|Debug"
```

## Output Formats

### Text Format (Default)
```
[2024-01-01 10:00:00] [INFO] Engine initialized
[2024-01-01 10:00:01] [INFO] RHI device created
[2024-01-01 10:00:02] [WARN] Buffer pool near capacity
```

### JSON Format
```bash
get-engine-log --format json
```
```json
{
  "timestamp": "2024-01-01T10:00:00Z",
  "level": "INFO",
  "message": "Engine initialized",
  "source": "Engine.cpp:42"
}
```

### Summary Format
```bash
get-engine-log --format summary
```
```
=== Log Summary ===
Total entries: 1000
INFO: 950
WARN: 45
ERROR: 5
FATAL: 0

Errors found:
- [10:00:15] Failed to create buffer (Buffer.cpp:100)
- [10:00:30] Texture upload failed (Texture.cpp:200)
```

## Log Analysis

### Error Detection
```bash
# Check for errors
get-engine-log --check-errors

# Output:
# Errors found: 2
# 1. [ERROR] Failed to create buffer
# 2. [ERROR] Texture upload failed
```

### Memory Leak Detection
```bash
# Check for memory leaks
get-engine-log --check-memory

# Output:
# Memory Summary:
# Total allocations: 1000
# Total deallocations: 998
# Potential leaks: 2
```

### Performance Analysis
```bash
# Analyze performance logs
get-engine-log --check-performance

# Output:
# Performance Summary:
# Frame time: 16.2ms avg, 25.3ms max
# GPU time: 12.5ms avg
# CPU time: 3.7ms avg
```

## Configuration

### Log File Path
```bash
# Set custom log path
export ENGINE_LOG_PATH=/var/log/engine
get-engine-log
```

### Log Retention
```bash
# Collect last N log files
get-engine-log --retention 10
```

## Integration with Development Workflow

### After Build
```bash
# Run engine and collect logs
./build/bin/engine --test-mode &
get-engine-log --follow --output ./logs/test.log
```

### For Verification
```bash
# Collect logs for verification
get-engine-log --output ./logs/session.log

# Check for issues
grep -E "ERROR|FATAL" ./logs/session.log
```

## Skill Template (待补充)

以下是用户需要补充的部分：

```yaml
# engine-log-config.yaml
# 用户根据实际引擎配置

log_source:
  type: file | stdout | network
  path: ./logs/engine.log
  format: text | json | binary

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
  format: text | json | summary
  file: ./logs/collected.log
  console: true

analysis:
  check_errors: true
  check_memory: true
  check_performance: true
```

## Example Usage

### Basic Collection
```bash
# Collect all logs
get-engine-log --output ./logs/session.log
```

### Debug Session
```bash
# Run engine with log collection
./build/bin/engine --debug 2>&1 | get-engine-log --follow --filter ERROR
```

### Verification Report
```bash
# Generate verification report
get-engine-log --format summary --report ./reports/verification.md
```

## Checklist

When using this skill, verify:

- [ ] Log source is accessible
- [ ] Log format is correct
- [ ] No ERROR level logs found
- [ ] No FATAL level logs found
- [ ] Memory allocation/deallocation balanced
- [ ] Initialization sequence complete
- [ ] Shutdown sequence complete
- [ ] No unexpected exceptions

---

**Note**: This is a template skill. Users should customize the implementation based on their specific engine logging system.
