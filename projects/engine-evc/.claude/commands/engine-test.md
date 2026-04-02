# Engine Test Command

生成和运行测试代码

## 用法

```
/engine-test <目标> [选项]
```

参数：
- `目标` - 要测试的模块、类或文件路径
- `选项` - 测试选项（可选）

选项：
- `--unit` - 生成单元测试
- `--integration` - 生成集成测试
- `--performance` - 生成性能测试
- `--coverage` - 生成覆盖率报告
- `--run` - 运行测试

## 功能

1. **测试生成**
   - 自动生成测试用例
   - 生成 Mock 对象
   - 生成测试固件

2. **测试运行**
   - 运行指定测试
   - 生成测试报告
   - 生成覆盖率报告

3. **测试分析**
   - 代码覆盖率分析
   - 测试质量评估
   - 测试建议

## 示例

### 为类生成单元测试

```
/engine-test Vector3 --unit
```

### 为模块生成完整测试

```
/engine-test Source/Runtime/Core --all
```

### 运行测试并生成覆盖率

```
/engine-test --run --coverage
```

### 测试输出示例

```
=== Test Generation: Vector3 ===

## Generated Test File: Tests/Unit/Math/Vector3Test.cpp

```cpp
#include <gtest/gtest.h>
#include "Math/Vector3.h"

class Vector3Test : public ::testing::Test
{
protected:
    void SetUp() override
    {
        v1 = Vector3(1.0f, 2.0f, 3.0f);
        v2 = Vector3(4.0f, 5.0f, 6.0f);
    }
    
    Vector3 v1, v2;
};

// Constructor Tests
TEST_F(Vector3Test, Constructor_Default_ZeroVector)
{
    Vector3 v;
    EXPECT_FLOAT_EQ(v.x, 0.0f);
    EXPECT_FLOAT_EQ(v.y, 0.0f);
    EXPECT_FLOAT_EQ(v.z, 0.0f);
}

TEST_F(Vector3Test, Constructor_Values_CorrectInitialization)
{
    EXPECT_FLOAT_EQ(v1.x, 1.0f);
    EXPECT_FLOAT_EQ(v1.y, 2.0f);
    EXPECT_FLOAT_EQ(v1.z, 3.0f);
}

// Arithmetic Tests
TEST_F(Vector3Test, Addition_ReturnsCorrectResult)
{
    Vector3 result = v1 + v2;
    EXPECT_FLOAT_EQ(result.x, 5.0f);
    EXPECT_FLOAT_EQ(result.y, 7.0f);
    EXPECT_FLOAT_EQ(result.z, 9.0f);
}

TEST_F(Vector3Test, DotProduct_ReturnsCorrectValue)
{
    float dot = v1.Dot(v2);
    EXPECT_FLOAT_EQ(dot, 32.0f);  // 1*4 + 2*5 + 3*6
}

TEST_F(Vector3Test, CrossProduct_ReturnsCorrectResult)
{
    Vector3 cross = v1.Cross(v2);
    // Expected: (2*6-3*5, 3*4-1*6, 1*5-2*4) = (-3, 6, -3)
    EXPECT_FLOAT_EQ(cross.x, -3.0f);
    EXPECT_FLOAT_EQ(cross.y, 6.0f);
    EXPECT_FLOAT_EQ(cross.z, -3.0f);
}

TEST_F(Vector3Test, Length_ReturnsCorrectValue)
{
    float len = v1.Length();
    EXPECT_NEAR(len, 3.741657f, 0.0001f);  // sqrt(1+4+9)
}

TEST_F(Vector3Test, Normalize_ReturnsUnitVector)
{
    Vector3 normalized = v1.Normalized();
    EXPECT_NEAR(normalized.Length(), 1.0f, 0.0001f);
}

// Edge Cases
TEST_F(Vector3Test, Normalize_ZeroVector_ReturnsZeroVector)
{
    Vector3 zero;
    Vector3 normalized = zero.Normalized();
    EXPECT_FLOAT_EQ(normalized.x, 0.0f);
    EXPECT_FLOAT_EQ(normalized.y, 0.0f);
    EXPECT_FLOAT_EQ(normalized.z, 0.0f);
}
```

## Test Statistics

- Test Cases Generated: 8
- Edge Cases Covered: 1
- Assertions: 22
- Expected Coverage: 95%

## Files Created

✓ Tests/Unit/Math/Vector3Test.cpp (created)

## Run Tests?

Would you like to:
1. Run tests now
2. Add more test cases
3. Generate Mock objects
4. Exit

Select option (1-4):
```

## 测试策略

### 1. 单元测试
- 测试单个类或函数
- 隔离测试，无外部依赖
- 快速执行

### 2. 集成测试
- 测试模块间交互
- 使用真实依赖
- 中等速度

### 3. 性能测试
- 测试执行时间
- 测试内存使用
- 基准对比

### 4. 边缘情况
- 空值、零值
- 边界值
- 错误输入

## 测试报告

```
=== Test Execution Report ===

## Summary
- Total Tests: 245
- Passed: 243
- Failed: 2
- Skipped: 0
- Duration: 1.23s

## Coverage Report
- Line Coverage: 87%
- Branch Coverage: 72%
- Function Coverage: 95%

## Failed Tests
1. Vector3Test.Normalize_ZeroVector_ReturnsZeroVector
   Expected: (0, 0, 0)
   Actual: (nan, nan, nan)
   
2. EntityManagerTest.CreateEntity_UniqueIDs
   Expected: unique IDs
   Actual: duplicate ID found

## Recommendations
⚠ Fix failing tests before commit
⚠ Add edge case tests for error handling
✓ Consider adding performance tests

## Coverage Gaps
- Exception handling: 45%
- Error paths: 60%
- Edge cases: 75%
```

## 最佳实践

### 1. 测试命名
```
TEST(ClassName, MethodName_Scenario_ExpectedResult)
```

### 2. 测试结构
```cpp
TEST_F(TestFixture, TestName)
{
    // Arrange (准备)
    int expected = 42;
    
    // Act (执行)
    int actual = Calculate();
    
    // Assert (断言)
    EXPECT_EQ(actual, expected);
}
```

### 3. 测试覆盖
- 正常情况
- 边缘情况
- 错误情况
- 性能情况
