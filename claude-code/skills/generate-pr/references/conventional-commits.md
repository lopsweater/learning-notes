# Conventional Commits Specification

A specification for adding human and machine readable meaning to commit messages.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(render): correct shadow acne` |
| `docs` | Documentation | `docs: update README` |
| `style` | Formatting | `style: fix indentation` |
| `refactor` | Code refactor | `refactor(ecs): extract system scheduler` |
| `perf` | Performance | `perf(rhi): reduce draw calls` |
| `test` | Tests | `test(rhi): add Vulkan backend tests` |
| `build` | Build system | `build: update CMake config` |
| `ci` | CI config | `ci: add GitHub Actions workflow` |
| `chore` | Maintenance | `chore: update dependencies` |
| `revert` | Revert commit | `revert: revert "feat: add login"` |

## Scope

Optional, in parentheses after type:
- Module name: `feat(renderer): add PBR`
- Component: `fix(ui): correct button alignment`
- Empty for global: `docs: update contributing guide`

## Description

Rules:
- Imperative mood (add, not added/adding)
- Lowercase first letter
- No period at end
- Maximum 72 characters
- Explain **what**, not why (why goes in body)

## Body

Optional, separated by blank line from description:
- Explain **why** the change was made
- Use bullet lists for multiple points
- Wrap at 72 characters

Example:
```
feat(rhi): add swapchain recreation

Required for handling window resize and minimizing.
The previous implementation would crash when the
window was resized during rendering.

- Detect VK_ERROR_OUT_OF_DATE_KHR
- Recreate swapchain with new dimensions
- Re-create framebuffers
```

## Footer

Optional, for:
- Breaking changes: `BREAKING CHANGE: <description>`
- Issue references: `Fixes #123`, `Closes #456`

Example:
```
feat(api): change render function signature

BREAKING CHANGE: The `render` function now takes a
`RenderContext` struct instead of individual parameters.

Fixes #123
```

## Examples

### New Feature
```
feat(ecs): add parallel system execution

Systems can now run in parallel when they have
non-overlapping component access.

- Add `ParallelSystem` wrapper
- Implement thread-safe command buffer
- Add system dependency graph

Fixes #456
```

### Bug Fix
```
fix(render): correct shadow map filtering

Shadow acne was visible on shallow angles due to
incorrect bias calculation.

- Use slope-scaled bias
- Add constant bias offset
- Fix normal offset direction
```

### Breaking Change
```
refactor(rhi): unify buffer creation API

BREAKING CHANGE: `createVertexBuffer` and
`createIndexBuffer` are removed. Use `createBuffer`
with `BufferUsage` flags instead.

Migration:
```cpp
// Before
auto vb = device->createVertexBuffer(size, data);

// After
auto vb = device->createBuffer({
    .size = size,
    .usage = BufferUsage::Vertex,
    .data = data
});
```

Fixes #789
```

### Simple Commit
```
docs: add troubleshooting section
```

## Best Practices

### Do ✅
- Use imperative mood: "add feature" not "added feature"
- Keep description under 72 chars
- Use scope for large projects
- Reference issues in footer
- Explain breaking changes clearly

### Don't ❌
- Use past tense: ~~"fixed bug"~~
- End description with period: ~~"add feature."~~
- Use generic messages: ~~"update code"~~
- Mix unrelated changes in one commit

## PR Title Convention

When creating PRs, use the same format for the title:

```
<type>(<scope>): <subject>
```

Example:
```
feat(renderer): add PBR material support
fix(rhi): resolve Vulkan validation errors
refactor(ecs): extract system scheduler
```

## Auto-Generated Changelog

Tools like `standard-version` can generate changelogs:

```markdown
# Changelog

## [1.2.0] - 2024-01-15

### Features
- Add PBR material support

### Bug Fixes
- Resolve Vulkan validation errors

### Breaking Changes
- Change render function signature

### Refactor
- Extract system scheduler
```
