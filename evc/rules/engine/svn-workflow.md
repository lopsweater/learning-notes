---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.hlsl"
  - "**/*.glsl"
  - "**/CMakeLists.txt"
---
# 引擎 SVN 工作流

## 提交信息格式

```
<type>(<scope>): <description>

<optional body>
```

### Types

| Type | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | feat(rhi): add Vulkan backend |
| fix | Bug 修复 | fix(render): fix resource barrier bug |
| perf | 性能优化 | perf(math): SIMD optimize Vec3 |
| refactor | 重构 | refactor(ecs): simplify component storage |
| docs | 文档 | docs(readme): update build instructions |
| test | 测试 | test(memory): add linear allocator tests |
| chore | 杂项 | chore(ci): add clang-tidy check |

### Scopes（引擎专用）

| Scope | 说明 |
|-------|------|
| rhi | 渲染硬件接口 |
| render | 渲染管线 |
| math | 数学库 |
| memory | 内存管理 |
| ecs | Entity-Component-System |
| asset | Asset 系统 |
| shader | Shader 相关 |
| editor | 编辑器 |
| ci | CI/CD |

## 提交示例

```bash
# 新功能
svn commit -m "feat(rhi): add D3D12 buffer creation"

# Bug 修复
svn commit -m "fix(render): fix texture upload alignment issue"

# 性能优化
svn commit -m "perf(math): use SSE for Vec3 dot product"

# 多文件提交
svn commit src/rhi/buffer.cpp src/rhi/buffer.hpp -m "feat(rhi): add buffer pool manager"
```

## 目录结构策略

```
svn://repo/engine/
├── trunk/                 # 主干（开发主线）
│   ├── src/
│   ├── tests/
│   └── docs/
├── branches/              # 分支
│   ├── feature/
│   │   ├── rhi-vulkan/    # Vulkan 后端开发
│   │   └── ecs-system/    # ECS 系统开发
│   └── bugfix/
│       └── resource-leak/ # 资源泄漏修复
└── tags/                  # 版本标签
    ├── v0.1.0/
    ├── v0.2.0/
    └── v1.0.0/
```

## 日常工作流

### 1. 更新工作副本

```bash
# 开始工作前更新
svn update

# 查看更新内容
svn log -r BASE:HEAD
```

### 2. 查看状态

```bash
# 查看修改状态
svn status

# 查看详细差异
svn diff

# 查看特定文件差异
svn diff src/rhi/buffer.cpp
```

### 3. 添加/删除文件

```bash
# 添加新文件
svn add src/math/vec4.cpp

# 添加目录
svn add src/utils/

# 删除文件
svn delete src/old_file.cpp

# 移动/重命名
svn move src/old_name.cpp src/new_name.cpp
```

### 4. 提交更改

```bash
# 提交所有更改
svn commit -m "feat(rhi): add descriptor heap manager"

# 提交特定文件
svn commit src/rhi/descriptor_heap.cpp src/rhi/descriptor_heap.hpp -m "feat(rhi): add descriptor heap manager"

# 提交前检查
svn status
svn diff
```

## 分支工作流

### 创建分支

```bash
# 从 trunk 创建功能分支
svn copy svn://repo/engine/trunk svn://repo/engine/branches/feature/rhi-vulkan -m "创建 Vulkan 后端功能分支"

# 切换到分支
svn switch svn://repo/engine/branches/feature/rhi-vulkan

# 查看当前分支
svn info
```

### 合并分支

```bash
# 切换到 trunk
svn switch svn://repo/engine/trunk

# 合并分支
svn merge svn://repo/engine/branches/feature/rhi-vulkan

# 解决冲突后提交
svn commit -m "merge: 合并 Vulkan 后端功能分支"
```

### 删除分支

```bash
# 删除已合并的分支
svn delete svn://repo/engine/branches/feature/rhi-vulkan -m "删除已合并的功能分支"
```

## 版本标签

### 创建标签

```bash
# 创建发布标签
svn copy svn://repo/engine/trunk svn://repo/engine/tags/v1.0.0 -m "release: v1.0.0"

# 检出特定标签
svn checkout svn://repo/engine/tags/v1.0.0 engine-v1.0.0
```

## 代码审查流程

### 提交前自查

1. **运行测试**
```bash
# 运行单元测试
ctest --test-dir build -L cpu --output-on-failure

# 运行 GPU 测试
ctest --test-dir build -L gpu --output-on-failure
```

2. **代码检查**
```bash
# 格式检查
clang-format --dry-run --Werror src/*.cpp src/*.hpp

# 静态分析
clang-tidy src/*.cpp -- -std=c++20
```

3. **查看差异**
```bash
svn diff
```

### 提交审查

```bash
# 查看即将提交的内容
svn status
svn diff

# 提交
svn commit -m "feat(rhi): add buffer pool manager

- 支持线性分配策略
- 支持延迟销毁
- 支持多线程安全"
```

## 冲突解决

### 查看冲突

```bash
# 更新时发生冲突
svn update

# 查看冲突文件
svn status

# 查看冲突详情
svn diff --summarize
```

### 解决冲突

```bash
# 查看冲突内容
cat src/rhi/buffer.cpp.mine      # 本地版本
cat src/rhi/buffer.cpp.r10       # 版本 10
cat src/rhi/buffer.cpp.r11       # 版本 11

# 手动解决冲突后标记为已解决
svn resolved src/rhi/buffer.cpp

# 提交解决后的代码
svn commit -m "fix: 解决 buffer.cpp 合并冲突"
```

## 常用命令速查

| 操作 | Git 命令 | SVN 命令 |
|------|----------|----------|
| 获取代码 | `git clone` | `svn checkout` |
| 更新代码 | `git pull` | `svn update` |
| 查看状态 | `git status` | `svn status` |
| 查看差异 | `git diff` | `svn diff` |
| 添加文件 | `git add` | `svn add` |
| 提交 | `git commit` + `git push` | `svn commit` |
| 查看日志 | `git log` | `svn log` |
| 创建分支 | `git branch` | `svn copy` |
| 切换分支 | `git checkout` | `svn switch` |
| 合并分支 | `git merge` | `svn merge` |

## Code Review 检查项

### 通用检查
- [ ] 代码符合规范
- [ ] 测试覆盖率达标
- [ ] 文档完整
- [ ] 提交信息格式正确

### CPU 侧检查
- [ ] SIMD 对齐正确
- [ ] 无内存泄漏
- [ ] 无数据竞争

### GPU 侧检查
- [ ] 无 GPU 资源泄漏
- [ ] 资源屏障正确
- [ ] 同步正确（Fence）

## 提交信息模板

```
<type>(<scope>): <简短描述>

<详细描述（可选）>

<变更点列表（可选）>
```

### 示例

```
feat(rhi): add buffer pool manager

实现 Buffer 池化管理器，支持：

- 线性分配策略
- 延迟销毁队列
- 多线程安全分配
- 性能基准：分配 <10μs

Test: engine-cpu-test 通过
```
