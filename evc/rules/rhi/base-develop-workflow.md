---
paths:
  - "src/**/*.cpp"
  - "src/**/*.hpp"
  - "src/**/*.c"
  - "src/**/*.h"
  - "include/**/*.hpp"
  - "include/**/*.h"
---
# Base Development Workflow

> 此文件定义代码修改的完整工作流程，所有代码改动（注释改动除外）都必须遵循此流程。

## 强制执行的工作流程

### 1. 代码审查 (Code Review)

**触发条件：** 任何代码修改（注释修改除外）

**检查项：**
- [ ] 代码符合编码规范
- [ ] 无明显的逻辑错误
- [ ] 无内存安全问题（泄漏、悬垂指针）
- [ ] 无线程安全问题（数据竞争、死锁）
- [ ] 命名清晰、注释适当

**审查命令：**
```bash
# 静态分析
clang-tidy src/**/*.cpp -- -std=c++20

# 代码格式检查
clang-format --dry-run --Werror src/**/*.cpp src/**/*.hpp
```

### 2. 单元测试 (Unit Testing)

**触发条件：** 代码修改涉及可测试的单元

**测试类型判断：**
| 修改内容 | 测试类型 | 测试命令 |
|----------|----------|----------|
| 数学库、工具类 | CPU 单元测试 | `ctest --test-dir build -L cpu` |
| RHI 接口 | GPU Mock 测试 | `ctest --test-dir build -L gpu` |
| Shader | Shader 编译测试 | `ctest --test-dir build -L shader` |

**覆盖率要求：**
- 新增代码覆盖率 ≥ 80%
- 修改的函数覆盖率 ≥ 80%
- 核心路径覆盖率 100%

**测试命令：**
```bash
# 运行相关测试
ctest --test-dir build --output-on-failure

# 检查覆盖率
cmake -DCMAKE_CXX_FLAGS="--coverage" -B build
cmake --build build
ctest --test-dir build
lcov --capture --directory build --output-file coverage.info
```

### 3. 编译测试 (Build Test)

**触发条件：** 所有代码修改后必须执行

**编译要求：**
- 零警告（`-Wall -Wextra -Werror`）
- 零错误
- Debug 和 Release 配置都通过

**编译命令：**
```bash
# Debug 构建
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -- -j

# Release 构建
cmake -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release -- -j
```

**问题解决：**
1. 编译错误：必须立即修复，不可跳过
2. 编译警告：必须处理或明确记录原因
3. 链接错误：检查依赖关系

### 4. 程序运行测试 (Runtime Test)

**触发条件：** 编译通过后

**运行命令：**
```bash
# 使用指定的命令行参数执行程序
./build/bin/engine <CMD_ARGUMENTS>

# 检查进程状态
ps aux | grep engine

# 等待稳定运行
sleep 5
```

**稳定性检查：**
- [ ] 程序正常启动
- [ ] 无崩溃（Segmentation Fault、Assertion Failed）
- [ ] 无异常退出
- [ ] 内存占用正常
- [ ] CPU 占用正常

**超时处理：**
```bash
# 设置超时（例如 30 秒）
timeout 30 ./build/bin/engine <CMD_ARGUMENTS>
EXIT_CODE=$?

if [ $EXIT_CODE -eq 124 ]; then
    echo "程序超时"
elif [ $EXIT_CODE -ne 0 ]; then
    echo "程序异常退出: $EXIT_CODE"
fi
```

### 5. 日志收集与分析 (Log Collection)

**触发条件：** 程序运行期间

**使用 skill 收集日志：**
```
Use skill: get-engine-log
```

**日志收集命令：**
```bash
# 收集程序日志
skill:get-engine-log --output ./logs/session.log

# 实时监控日志
skill:get-engine-log --follow
```

**日志内容要求：**
- [ ] 初始化日志完整
- [ ] 关键操作日志存在
- [ ] 无错误日志（ERROR 级别）
- [ ] 无警告日志（WARN 级别）或已分析
- [ ] 程序退出日志正常

### 6. 功能验证 (Functional Verification)

**触发条件：** 日志收集完成后

**验证内容：**
| 验证项 | 检查方法 | 预期结果 |
|--------|----------|----------|
| 初始化成功 | 日志包含 "Initialized" | ✓ |
| 功能执行 | 日志包含功能执行记录 | ✓ |
| 资源释放 | 日志包含 "Shutdown" | ✓ |
| 无内存泄漏 | 日志无 "Memory leak" | ✓ |
| 无异常 | 日志无 "Exception" | ✓ |

**验证命令：**
```bash
# 检查错误日志
grep -E "ERROR|FATAL|Exception|Crash" ./logs/session.log

# 检查警告日志
grep -E "WARN|Warning" ./logs/session.log

# 检查内存泄漏
grep -i "memory leak" ./logs/session.log
```

## 工作流程图

```
┌─────────────────┐
│  代码修改        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  1. Code Review  │ ← 静态分析 + 人工审查
└────────┬────────┘
         │ 通过
         ▼
┌─────────────────┐
│  2. Unit Test    │ ← 运行相关测试
└────────┬────────┘
         │ 通过
         ▼
┌─────────────────┐
│  3. Build Test   │ ← Debug + Release
└────────┬────────┘
         │ 通过
         ▼
┌─────────────────┐
│  4. Run Exe      │ ← 指定参数执行
└────────┬────────┘
         │ 稳定运行
         ▼
┌─────────────────┐
│  5. Collect Log  │ ← get-engine-log skill
└────────┬────────┘
         │ 日志收集完成
         ▼
┌─────────────────┐
│  6. Verify       │ ← 分析日志验证功能
└────────┬────────┘
         │ 验证通过
         ▼
┌─────────────────┐
│  ✅ 完成         │
└─────────────────┘
```

## 失败处理

| 阶段 | 失败处理 |
|------|----------|
| Code Review | 修复问题后重新审查 |
| Unit Test | 修复代码或补充测试 |
| Build Test | 解决编译/链接问题 |
| Runtime Test | 调试崩溃或异常 |
| Log Collection | 检查日志系统配置 |
| Verification | 分析日志修复问题 |

## 强制要求

**必须完成所有步骤才能提交代码：**
1. ✅ Code Review 通过
2. ✅ Unit Test 通过
3. ✅ Build Test 通过（Debug + Release）
4. ✅ 程序稳定运行
5. ✅ 日志收集完成
6. ✅ 功能验证通过

**禁止：**
- ❌ 跳过任何步骤
- ❌ 忽略编译警告
- ❌ 忽略测试失败
- ❌ 忽略运行时错误
- ❌ 提交未验证的代码

## 相关文件

- [engine/cpu-testing.md](./engine/cpu-testing.md) - CPU 测试规则
- [engine/gpu-testing.md](./engine/gpu-testing.md) - GPU 测试规则
- [engine/hooks.md](./engine/hooks.md) - 提交前检查
