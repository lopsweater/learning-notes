---
name: generate-pr
description: Generate structured Pull Requests from git diffs. Use when working with Claude Code to create PRs for code changes. Supports all PR types (feat/fix/refactor/docs/test/chore/perf) and follows Conventional Commits convention. Triggers on requests like "generate PR", "create pull request", "write PR description", or when reviewing staged/unstaged changes.
---

# Generate Pull Request

Generate high-quality, structured Pull Requests from code changes for use with Claude Code.

## Workflow

```
1. Gather Context
   └─> Run git commands to understand changes

2. Analyze Changes
   └─> Identify type, scope, and impact

3. Generate PR
   └─> Create title, description, test plan

4. Refine (Optional)
   └─> Add details, link issues, screenshots
```

## Step 1: Gather Context

**Always run these commands first:**

```bash
# Get current branch and diff stats
git branch --show-current
git diff main...HEAD --stat

# Get commit history
git log main...HEAD --oneline

# Get full diff (truncate if too large)
git diff main...HEAD

# Check for related issues in commits
git log main...HEAD --grep="#[0-9]" --oneline
```

**For staged changes only:**
```bash
git diff --staged
```

## Step 2: Analyze Changes

### Type Detection

| Pattern | Type | Title Prefix |
|---------|------|--------------|
| New files, new functions | `feat` | `feat(scope): add ...` |
| Bug fixes, error handling | `fix` | `fix(scope): fix ...` |
| Code restructure, no behavior change | `refactor` | `refactor(scope): ...` |
| Comment, README changes | `docs` | `docs: ...` |
| Test files added/modified | `test` | `test(scope): ...` |
| Build, CI, dependencies | `chore` | `chore: ...` |
| Performance improvements | `perf` | `perf(scope): ...` |
| Code style, formatting | `style` | `style: ...` |

### Scope Detection

Extract from file paths:
```
src/renderer/  → scope: renderer
src/rhi/       → scope: rhi
src/ecs/       → scope: ecs
src/core/      → scope: core
tests/         → scope: (omit, use test type)
```

### Impact Assessment

Check for:
- [ ] Public API changes → Breaking Changes section required
- [ ] New dependencies → Note in description
- [ ] Database/Config changes → Migration guide needed
- [ ] Performance-critical code → Benchmark results needed

## Step 3: Generate PR

### Title Format

```
<type>(<scope>): <subject>
```

Rules:
- Type: one of feat/fix/refactor/docs/test/chore/perf/style
- Scope: module name (optional for docs/chore)
- Subject: imperative mood, lowercase, no period, <72 chars
- Example: `feat(renderer): add PBR material support`

### Description Template

```markdown
## Summary
<!-- One sentence: what does this PR do? -->

## Changes
<!-- Bullet list of key changes -->
- 
- 

## Related Issues
<!-- Use keywords to auto-close: Fixes #123, Closes #456 -->
Fixes #

## Test Plan
<!-- How to verify this works -->
- [ ] Unit tests: `<test command>`
- [ ] Manual testing: <steps>
- [ ] Performance: <benchmark if relevant>

## Screenshots
<!-- For UI changes: before/after -->

## Breaking Changes
<!-- If any, explain migration path -->

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No compiler warnings
```

### Type-Specific Sections

**For `feat`:**
```markdown
## New Feature
<!-- Explain the feature and use case -->

## Usage Example
<!-- Code snippet showing how to use -->
```

**For `fix`:**
```markdown
## Bug Description
<!-- What was broken, symptoms -->

## Root Cause
<!-- Why it happened -->

## Fix Details
<!-- How it's fixed -->
```

**For `refactor`:**
```markdown
## Motivation
<!-- Why refactor was needed -->

## Before/After
<!-- Architecture comparison if significant -->
```

**For `perf`:**
```markdown
## Performance Impact
<!-- Benchmark results: before/after -->
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| FPS    | 60     | 75    | +25%        |
```

## Step 4: Refine

### Link Issues

Extract issue numbers from:
- Commit messages: `fix: resolve crash (#123)`
- Branch name: `feature/login-#123`
- User input: "fixes issue 456"

Use closing keywords:
- `Fixes #123` - auto-closes on merge
- `Closes #456` - auto-closes on merge
- `Related to #789` - links without closing

### Add Context

For game engine projects, check:
- [ ] Rendering changes → Note GPU API impact (DX12/Vulkan/Metal)
- [ ] Memory allocations → Note allocation patterns
- [ ] Threading changes → Note thread safety
- [ ] Platform code → Note OS compatibility

## Output Format

When using with Claude Code, output the PR in this format:

````markdown
# Pull Request

## Title
<type>(<scope>): <subject>

## Description
<generated description>

---
<!-- Raw markdown for copy-paste -->
```markdown
<type>(<scope>): <subject>

## Summary
...

## Changes
...
```
````

## Quick Reference

**Command to generate PR:**
```bash
# For current branch
claude "Generate a PR for the changes in this branch targeting main"

# For staged changes
claude "Generate a PR for staged changes"

# With specific issue
claude "Generate a PR for this branch, fixes #123"
```

**Example Claude Code prompt:**
```
Generate a Pull Request for my current branch.

Target branch: main
Related issue: #456

Focus on:
- Performance impact
- API stability
```

## References

For detailed PR templates and Conventional Commits spec:
- [pr-templates.md](references/pr-templates.md) - Templates by PR type
- [conventional-commits.md](references/conventional-commits.md) - Full specification

## Assets

Standard PR template:
- [pr-template.md](assets/pr-template.md) - Copy to `.github/PULL_REQUEST_TEMPLATE.md`
