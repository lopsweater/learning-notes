---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.hlsl"
  - "**/*.glsl"
  - "**/CMakeLists.txt"
---
# 引擎 Git 工作流

## 提交信息格式

```
<type>(<scope>): <description>

<optional body>

<optional footer>
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
git commit -m "feat(rhi): add D3D12 buffer creation"

# Bug 修复
git commit -m "fix(render): fix texture upload alignment issue"

# 性能优化
git commit -m "perf(math): use SSE for Vec3 dot product"

# 破坏性变更
git commit -m "feat(rhi)!: change RHIBuffer interface

BREAKING CHANGE: RHIDevice::CreateBuffer now takes BufferDesc struct
instead of individual parameters"
```

## 分支策略

```
main           # 稳定分支
├── develop    # 开发分支
│   ├── feat/rhi-vulkan    # Vulkan 后端开发
│   ├── feat/ecs-system    # ECS 系统开发
│   └── fix/resource-leak  # 资源泄漏修复
```

## Pull Request 工作流

创建 PR 时：

1. 分析完整提交历史（不只是最新提交）
2. 使用 `git diff [base-branch]...HEAD` 查看所有更改
3. 编写详细的 PR 描述
4. 包含测试计划和 TODO
5. 新分支使用 `-u` 标志推送

## PR 描述模板

```markdown
## 变更说明
<!-- 描述此 PR 的变更内容 -->

## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 性能优化
- [ ] 重构
- [ ] 文档更新

## 测试计划
- [ ] 单元测试通过
- [ ] 覆盖率达标（80%+）
- [ ] 性能基准无回归
- [ ] 手动测试

## 检查清单
- [ ] 代码符合规范
- [ ] 无内存泄漏
- [ ] 无 GPU 资源泄漏
- [ ] 文档已更新

## 相关 Issue
<!-- 关联的 Issue 编号 -->
```

## Code Review 检查项

### 通用检查
- [ ] 代码符合规范
- [ ] 测试覆盖率达标
- [ ] 文档完整

### CPU 侧检查
- [ ] SIMD 对齐正确
- [ ] 无内存泄漏
- [ ] 无数据竞争

### GPU 侧检查
- [ ] 无 GPU 资源泄漏
- [ ] 资源屏障正确
- [ ] 同步正确（Fence）
