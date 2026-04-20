# PR Templates by Type

## feat (New Feature)

````markdown
<type>(<scope>): <subject>

## Summary
<One sentence description>

## New Feature
<Explain the feature and its use case>

## Changes
- <change 1>
- <change 2>

## Usage Example
```cpp
// Show how to use the new feature
```

## Related Issues
Fixes #

## Test Plan
- [ ] Unit tests: `<command>`
- [ ] Integration tests: `<command>`
- [ ] Manual testing:
  1. <step 1>
  2. <step 2>

## Screenshots
<!-- For UI features -->

## Breaking Changes
<!-- If public API changed, explain migration -->

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No compiler warnings
````

---

## fix (Bug Fix)

````markdown
fix(<scope>): <subject>

## Summary
<One sentence description>

## Bug Description
<What was broken, symptoms observed>

## Root Cause
<Why the bug occurred>

## Fix Details
<How the fix works>

## Changes
- <change 1>
- <change 2>

## Related Issues
Fixes #

## Test Plan
- [ ] Unit tests: `<command>`
- [ ] Regression test: <verify bug is fixed>
  1. <reproduction step 1>
  2. <reproduction step 2>
  3. Verify fix works

## Risk Assessment
<!-- Could this fix introduce new issues? -->

## Checklist
- [ ] Code follows project style
- [ ] Regression test added
- [ ] No side effects
````

---

## refactor (Code Refactor)

````markdown
refactor(<scope>): <subject>

## Summary
<One sentence description>

## Motivation
<Why this refactor was needed>

## Changes
- <change 1>
- <change 2>

## Before/After
<!-- Architecture or API comparison if significant -->

### Before
```cpp
// Old pattern
```

### After
```cpp
// New pattern
```

## Related Issues
Related to #

## Test Plan
- [ ] Existing tests pass: `<command>`
- [ ] No behavioral change (same output)
- [ ] Performance: <benchmark if relevant>

## Migration Guide
<!-- If API changed, provide migration steps -->

## Checklist
- [ ] No behavioral change
- [ ] Tests pass
- [ ] No new warnings
````

---

## perf (Performance Improvement)

````markdown
perf(<scope>): <subject>

## Summary
<One sentence description>

## Performance Impact
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| <metric> | <value> | <value> | <delta> |

## Approach
<How performance was improved>

## Changes
- <change 1>
- <change 2>

## Related Issues
Fixes #

## Test Plan
- [ ] Unit tests: `<command>`
- [ ] Benchmark: `<command>`
- [ ] Profile: <tool/method>

## Trade-offs
<!-- Any sacrifices made for performance -->

## Checklist
- [ ] Benchmark results included
- [ ] No accuracy regression
- [ ] Memory impact assessed
````

---

## docs (Documentation)

```markdown
docs(<scope>): <subject>

## Summary
<One sentence description>

## Changes
- <change 1>
- <change 2>

## Checklist
- [ ] Spelling/grammar checked
- [ ] Code examples tested
- [ ] Links valid
```

---

## test (Tests)

```markdown
test(<scope>): <subject>

## Summary
<One sentence description>

## Changes
- <change 1>
- <change 2>

## Coverage
| Module | Before | After |
|--------|--------|-------|
| <module> | <old>% | <new>% |

## Checklist
- [ ] Tests pass locally
- [ ] Edge cases covered
- [ ] No flaky tests
```

---

## chore (Maintenance)

```markdown
chore(<scope>): <subject>

## Summary
<One sentence description>

## Changes
- <change 1>
- <change 2>

## Checklist
- [ ] Build passes
- [ ] No runtime impact
```
