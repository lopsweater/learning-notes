---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.hlsl"
  - "**/*.glsl"
  - "**/CMakeLists.txt"
---
# 引擎开发工作流

> 此文件扩展了 [engine/git-workflow.md](./git-workflow.md)，包含 Git 操作之前的完整功能开发流程。

功能实现工作流描述了开发管道：研究、规划、TDD、代码审查，然后提交到 Git。

## 功能实现工作流

### 0. 研究与复用（任何新实现前的必选项）

- **GitHub 代码搜索优先：** 运行 `gh search repos` 和 `gh search code` 查找现有实现、模板和模式。
- **引擎文档其次：** 查看 Godot、Unreal、Piccolo 等开源引擎的实现方式。
- **GPU Open / DirectX Specs：** 确认 D3D12/Vulkan API 行为和最佳实践。
- **检查包注册表：** 搜索 vcpkg、conan 等包管理器，优先使用成熟库。
- **寻找可适配的实现：** 查找能解决 80%+ 问题的开源项目。

### 1. 规划优先

- 使用 **planner** agent 创建实现计划
- 生成规划文档：PRD、架构设计、系统设计、技术文档、任务列表
- 识别依赖和风险
- 分解为阶段

#### 引擎特有规划内容

| 规划项 | 说明 |
|--------|------|
| 目标平台 | Windows (D3D12), Linux (Vulkan), 跨平台需求 |
| 性能目标 | 帧时间预算、内存占用、Draw Call 数量 |
| CPU/GPU 划分 | 明确哪些在 CPU 处理，哪些在 GPU 处理 |
| RHI 抽象层 | 需要支持的图形 API |

### 2. CPU/GPU 分离开发

根据功能类型选择开发流程：

| 功能类型 | 使用流程 | 文档 |
|----------|----------|------|
| 数学库、内存分配器、工具类 | CPU 开发流程 | [cpu-development.md](./cpu-development.md) |
| Buffer/Texture、渲染管线 | GPU 开发流程 | [gpu-development.md](./gpu-development.md) |

### 3. TDD 方法

- 使用 **engine-cpu-tdd-guide** 或 **engine-gpu-tdd-guide** agent
- 先写测试（红）
- 实现以通过测试（绿）
- 重构（改进）
- 验证 80%+ 覆盖率
- 验证性能基准

### 4. 代码审查

- 编写代码后立即使用 **code-reviewer** agent
- 处理 CRITICAL 和 HIGH 问题
- 尽可能修复 MEDIUM 问题

#### 引擎特有审查项

- GPU 资源泄漏（Buffer、Texture、Descriptor）
- 线程安全（多线程渲染）
- 内存对齐（SIMD、GPU 缓冲区）
- 性能回归（帧时间、内存占用）

### 5. 提交与推送

- 详细的提交信息
- 遵循约定式提交格式
- 参见 [git-workflow.md](./git-workflow.md)
