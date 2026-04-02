---
name: engine-testing
description: 测试与调试 - 单元测试、集成测试、性能测试、内存检测等引擎测试知识
globs:
  - "*test*.cpp"
  - "*spec*.cpp"
  - "**/tests/**"
---

# Engine Testing

> **测试是保证引擎质量的关键，此技能提供完整的引擎测试知识体系**

## 作用

提供游戏引擎测试知识，包括单元测试、集成测试、性能测试、内存检测、自动化测试等。

## 触发时机

- 编写测试代码时
- 用户提及测试、调试、性能分析等关键词时
- 需要验证功能正确性时

## 核心内容

### 一、测试金字塔

```
┌────────────────────────────────────────────────────────┐
│                  测试金字塔                            │
└────────────────────────────────────────────────────────┘

                ▲
               /  \
              / E2E \          端到端测试
             /______\         - 数量少，成本高
            /        \
           /Integration\      集成测试
          /______________\    - 模块间交互测试
         /                  \
        /    Unit Tests      \  单元测试
       /______________________\ - 数量多，成本低
```

### 二、单元测试

#### 1. 测试框架选择

```cpp
// 推荐：Google Test + Google Mock
#include <gtest/gtest.h>
#include <gmock/gmock.h>

// 示例：测试 Vector3 类
class Vector3Test : public ::testing::Test
{
protected:
    void SetUp() override
    {
        // 测试前准备
    }
    
    void TearDown() override
    {
        // 测试后清理
    }
};

TEST_F(Vector3Test, Constructor_Default_ZeroVector)
{
    Vector3 v;
    EXPECT_FLOAT_EQ(v.x, 0.0f);
    EXPECT_FLOAT_EQ(v.y, 0.0f);
    EXPECT_FLOAT_EQ(v.z, 0.0f);
}

TEST_F(Vector3Test, Constructor_Values_CorrectInitialization)
{
    Vector3 v(1.0f, 2.0f, 3.0f);
    EXPECT_FLOAT_EQ(v.x, 1.0f);
    EXPECT_FLOAT_EQ(v.y, 2.0f);
    EXPECT_FLOAT_EQ(v.z, 3.0f);
}

TEST_F(Vector3Test, Length_CalculatesCorrectly)
{
    Vector3 v(3.0f, 4.0f, 0.0f);
    EXPECT_FLOAT_EQ(v.Length(), 5.0f);
}

TEST_F(Vector3Test, Normalize_ReturnsUnitVector)
{
    Vector3 v(3.0f, 4.0f, 0.0f);
    Vector3 normalized = v.Normalized();
    
    EXPECT_FLOAT_EQ(normalized.x, 0.6f);
    EXPECT_FLOAT_EQ(normalized.y, 0.8f);
    EXPECT_FLOAT_EQ(normalized.z, 0.0f);
    EXPECT_NEAR(normalized.Length(), 1.0f, 0.0001f);
}

// 参数化测试
class Vector3ParameterizedTest : public ::testing::TestWithParam<std::tuple<float, float, float>>
{};

TEST_P(Vector3ParameterizedTest, Length_IsAlwaysPositive)
{
    auto [x, y, z] = GetParam();
    Vector3 v(x, y, z);
    EXPECT_GE(v.Length(), 0.0f);
}

INSTANTIATE_TEST_SUITE_P(
    VariousVectors,
    Vector3ParameterizedTest,
    ::testing::Combine(
        ::testing::Values(-1.0f, 0.0f, 1.0f, 10.0f),
        ::testing::Values(-1.0f, 0.0f, 1.0f, 10.0f),
        ::testing::Values(-1.0f, 0.0f, 1.0f, 10.0f)
    )
);
```

#### 2. Mock 对象

```cpp
// 接口定义
class IAudioDevice
{
public:
    virtual ~IAudioDevice() = default;
    virtual void PlaySound(SoundHandle sound) = 0;
    virtual void StopSound(SoundHandle sound) = 0;
    virtual void SetVolume(float volume) = 0;
};

// Mock 实现
class MockAudioDevice : public IAudioDevice
{
public:
    MOCK_METHOD(void, PlaySound, (SoundHandle sound), (override));
    MOCK_METHOD(void, StopSound, (SoundHandle sound), (override));
    MOCK_METHOD(void, SetVolume, (float volume), (override));
};

// 使用 Mock 测试
class AudioManagerTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        m_MockDevice = std::make_unique<MockAudioDevice>();
        m_Manager = std::make_unique<AudioManager>(m_MockDevice.get());
    }
    
    std::unique_ptr<MockAudioDevice> m_MockDevice;
    std::unique_ptr<AudioManager> m_Manager;
};

TEST_F(AudioManagerTest, PlaySound_CallsDevicePlaySound)
{
    SoundHandle sound{42};
    
    EXPECT_CALL(*m_MockDevice, PlaySound(sound))
        .Times(1);
    
    m_Manager->PlaySound(sound);
}

TEST_F(AudioManagerTest, SetVolume_ClampsValue)
{
    EXPECT_CALL(*m_MockDevice, SetVolume(::testing::FloatEq(1.0f)))
        .Times(1);
    
    m_Manager->SetVolume(2.0f);  // 应该被 clamp 到 1.0
}
```

### 三、性能测试

#### 1. Benchmark 框架

```cpp
#include <benchmark/benchmark.h>

// 基准测试：Vector3 运算
static void BM_Vector3_DotProduct(benchmark::State& state)
{
    Vector3 a(1.0f, 2.0f, 3.0f);
    Vector3 b(4.0f, 5.0f, 6.0f);
    
    for (auto _ : state)
    {
        float result = a.Dot(b);
        benchmark::DoNotOptimize(result);
    }
}
BENCHMARK(BM_Vector3_DotProduct);

// 基准测试：矩阵乘法
static void BM_Matrix4_Multiply(benchmark::State& state)
{
    Matrix4 a = Matrix4::Identity();
    Matrix4 b = Matrix4::RotationY(45.0f);
    
    for (auto _ : state)
    {
        Matrix4 result = a * b;
        benchmark::DoNotOptimize(result);
    }
}
BENCHMARK(BM_Matrix4_Multiply);

// 参数化基准测试
static void BM_ECS_IterateEntities(benchmark::State& state)
{
    World world;
    
    // 创建 N 个实体
    int entityCount = state.range(0);
    for (int i = 0; i < entityCount; ++i)
    {
        auto entity = world.CreateEntity();
        entity.AddComponent<TransformComponent>();
        entity.AddComponent<VelocityComponent>();
    }
    
    for (auto _ : state)
    {
        for (auto [entity, transform, velocity] : 
             world.View<TransformComponent, VelocityComponent>())
        {
            transform.position += velocity.velocity * 0.016f;
        }
    }
    
    state.SetItemsProcessed(state.iterations() * entityCount);
}
BENCHMARK(BM_ECS_IterateEntities)
    ->Arg(1000)
    ->Arg(10000)
    ->Arg(100000);
```

#### 2. 自定义性能测试

```cpp
class PerformanceTest
{
public:
    struct Result
    {
        std::string name;
        float avgTime;
        float minTime;
        float maxTime;
        float stdDev;
        int iterations;
    };
    
    static Result Run(const std::string& name, std::function<void()> func, int iterations = 1000)
    {
        std::vector<float> times;
        times.reserve(iterations);
        
        // 预热
        for (int i = 0; i < 10; ++i)
        {
            func();
        }
        
        // 正式测试
        for (int i = 0; i < iterations; ++i)
        {
            auto start = std::chrono::high_resolution_clock::now();
            func();
            auto end = std::chrono::high_resolution_clock::now();
            
            float time = std::chrono::duration<float, std::micro>(end - start).count();
            times.push_back(time);
        }
        
        // 计算统计信息
        float sum = std::accumulate(times.begin(), times.end(), 0.0f);
        float avg = sum / iterations;
        
        auto [min, max] = std::minmax_element(times.begin(), times.end());
        
        float variance = 0.0f;
        for (float t : times)
        {
            variance += (t - avg) * (t - avg);
        }
        float stdDev = std::sqrt(variance / iterations);
        
        return Result{
            .name = name,
            .avgTime = avg,
            .minTime = *min,
            .maxTime = *max,
            .stdDev = stdDev,
            .iterations = iterations
        };
    }
    
    static void PrintResult(const Result& result)
    {
        std::cout << "=== " << result.name << " ===\n";
        std::cout << "Avg: " << result.avgTime << " μs\n";
        std::cout << "Min: " << result.minTime << " μs\n";
        std::cout << "Max: " << result.maxTime << " μs\n";
        std::cout << "StdDev: " << result.stdDev << " μs\n";
        std::cout << "Iterations: " << result.iterations << "\n\n";
    }
};

// 使用示例
void Test_RenderPerformance()
{
    Renderer renderer;
    renderer.Initialize();
    
    auto result = PerformanceTest::Run("Render Frame", [&]() {
        renderer.BeginFrame();
        renderer.RenderScene();
        renderer.EndFrame();
    }, 100);
    
    PerformanceTest::PrintResult(result);
    
    // 断言性能要求
    EXPECT_LT(result.avgTime, 16.67f);  // 必须小于 16.67ms (60 FPS)
}
```

### 四、内存检测

#### 1. 内存泄漏检测

```cpp
// 自定义内存跟踪器
class MemoryTracker
{
public:
    struct Allocation
    {
        void* ptr;
        size_t size;
        std::string file;
        int line;
        std::string stackTrace;
    };
    
    static MemoryTracker& Get()
    {
        static MemoryTracker instance;
        return instance;
    }
    
    void* Allocate(size_t size, const char* file, int line)
    {
        void* ptr = malloc(size);
        
        std::lock_guard<std::mutex> lock(m_Mutex);
        m_Allocations[ptr] = Allocation{
            .ptr = ptr,
            .size = size,
            .file = file,
            .line = line,
            .stackTrace = CaptureStackTrace()
        };
        
        m_TotalAllocated += size;
        m_AllocationCount++;
        
        return ptr;
    }
    
    void Deallocate(void* ptr)
    {
        if (!ptr) return;
        
        std::lock_guard<std::mutex> lock(m_Mutex);
        
        auto it = m_Allocations.find(ptr);
        if (it != m_Allocations.end())
        {
            m_TotalAllocated -= it->second.size;
            m_AllocationCount--;
            m_Allocations.erase(it);
        }
        
        free(ptr);
    }
    
    void ReportLeaks()
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        
        if (m_Allocations.empty())
        {
            std::cout << "No memory leaks detected!\n";
            return;
        }
        
        std::cout << "=== Memory Leaks Detected ===\n";
        std::cout << "Total allocations: " << m_Allocations.size() << "\n";
        std::cout << "Total bytes: " << m_TotalAllocated << "\n\n";
        
        for (const auto& [ptr, alloc] : m_Allocations)
        {
            std::cout << "Leak at " << ptr << "\n";
            std::cout << "  Size: " << alloc.size << " bytes\n";
            std::cout << "  Location: " << alloc.file << ":" << alloc.line << "\n";
            std::cout << "  Stack:\n" << alloc.stackTrace << "\n\n";
        }
    }
    
private:
    std::unordered_map<void*, Allocation> m_Allocations;
    std::mutex m_Mutex;
    size_t m_TotalAllocated = 0;
    size_t m_AllocationCount = 0;
    
    std::string CaptureStackTrace()
    {
        // 使用 backtrace 捕获调用栈
        // ...
        return "";
    }
};

// 重载 new/delete
void* operator new(size_t size, const char* file, int line)
{
    return MemoryTracker::Get().Allocate(size, file, line);
}

void operator delete(void* ptr) noexcept
{
    MemoryTracker::Get().Deallocate(ptr);
}

// 便捷宏
#define new new(__FILE__, __LINE__)

// 使用示例
int main()
{
    // 测试代码...
    
    MemoryTracker::Get().ReportLeaks();
    return 0;
}
```

#### 2. Valgrind 集成

```cmake
# CMakeLists.txt
option(ENABLE_VALGRIND "Enable Valgrind memory check" OFF)

if(ENABLE_VALGRIND)
    find_program(VALGRIND_EXECUTABLE valgrind)
    if(VALGRIND_EXECUTABLE)
        add_custom_target(valgrind
            COMMAND ${VALGRIND_EXECUTABLE}
                --tool=memcheck
                --leak-check=full
                --show-leak-kinds=all
                --track-origins=yes
                --error-exitcode=1
                $<TARGET_FILE:MyEngineTests>
            DEPENDS MyEngineTests
        )
    endif()
endif()
```

### 五、自动化测试

#### 1. CI/CD 集成

```yaml
# .github/workflows/test.yml
name: Engine Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        build_type: [Debug, Release]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure CMake
      run: cmake -B build -DCMAKE_BUILD_TYPE=${{ matrix.build_type }}
    
    - name: Build
      run: cmake --build build --config ${{ matrix.build_type }}
    
    - name: Run Unit Tests
      run: ctest --test-dir build -C ${{ matrix.build_type }} --output-on-failure
    
    - name: Run Memory Tests (Linux)
      if: runner.os == 'Linux'
      run: |
        sudo apt-get install valgrind
        valgrind --tool=memcheck --leak-check=full --error-exitcode=1 ./build/bin/MyEngineTests
    
    - name: Generate Coverage Report
      if: matrix.os == 'ubuntu-latest' && matrix.build_type == 'Debug'
      run: |
        bash <(curl -s https://codecov.io/bash)
```

#### 2. 测试报告生成

```cpp
// 测试报告生成器
class TestReportGenerator
{
public:
    struct TestResult
    {
        std::string name;
        std::string suite;
        bool passed;
        float duration;
        std::string errorMessage;
    };
    
    void AddResult(const TestResult& result)
    {
        m_Results.push_back(result);
    }
    
    void GenerateHTML(const std::string& outputPath)
    {
        std::ofstream file(outputPath);
        
        file << "<!DOCTYPE html>\n";
        file << "<html>\n<head>\n";
        file << "<title>Engine Test Report</title>\n";
        file << "<style>\n";
        file << "body { font-family: Arial, sans-serif; margin: 20px; }\n";
        file << ".passed { color: green; }\n";
        file << ".failed { color: red; }\n";
        file << "table { border-collapse: collapse; width: 100%; }\n";
        file << "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n";
        file << "</style>\n";
        file << "</head>\n<body>\n";
        
        // 统计信息
        int passed = std::count_if(m_Results.begin(), m_Results.end(), 
            [](const auto& r) { return r.passed; });
        
        file << "<h1>Engine Test Report</h1>\n";
        file << "<p>Total: " << m_Results.size() << "</p>\n";
        file << "<p class='passed'>Passed: " << passed << "</p>\n";
        file << "<p class='failed'>Failed: " << (m_Results.size() - passed) << "</p>\n";
        
        // 测试结果表格
        file << "<table>\n";
        file << "<tr><th>Suite</th><th>Test</th><th>Status</th><th>Duration</th><th>Message</th></tr>\n";
        
        for (const auto& result : m_Results)
        {
            file << "<tr>";
            file << "<td>" << result.suite << "</td>";
            file << "<td>" << result.name << "</td>";
            file << "<td class='" << (result.passed ? "passed" : "failed") << "'>";
            file << (result.passed ? "PASSED" : "FAILED") << "</td>";
            file << "<td>" << result.duration << " ms</td>";
            file << "<td>" << result.errorMessage << "</td>";
            file << "</tr>\n";
        }
        
        file << "</table>\n";
        file << "</body>\n</html>\n";
    }
    
private:
    std::vector<TestResult> m_Results;
};
```

### 六、调试技巧

#### 1. 断言系统

```cpp
// 引擎断言系统
namespace Assert
{
    // 编译期断言
    #define STATIC_ASSERT(condition, message) static_assert(condition, message)
    
    // 运行时断言
    #ifdef DEBUG
        #define ASSERT(condition, message) \
            do { \
                if (!(condition)) { \
                    Assert::Fail(#condition, message, __FILE__, __LINE__); \
                } \
            } while (0)
    #else
        #define ASSERT(condition, message) ((void)0)
    #endif
    
    // 断言失败处理
    inline void Fail(const char* condition, const char* message, const char* file, int line)
    {
        std::cerr << "Assertion failed: " << condition << "\n";
        std::cerr << "Message: " << message << "\n";
        std::cerr << "File: " << file << ":" << line << "\n";
        
        // 触发调试器断点
        #ifdef _WIN32
            DebugBreak();
        #else
            raise(SIGTRAP);
        #endif
        
        std::abort();
    }
}

// 使用示例
void ProcessEntity(Entity* entity)
{
    ASSERT(entity != nullptr, "Entity cannot be null");
    ASSERT(entity->IsValid(), "Entity must be valid");
    
    // ... 处理逻辑
}
```

#### 2. 日志系统

```cpp
// 日志系统
class Logger
{
public:
    enum class Level
    {
        Trace,
        Debug,
        Info,
        Warning,
        Error,
        Fatal
    };
    
    static void SetLevel(Level level) { s_Level = level; }
    
    template<typename... Args>
    static void Log(Level level, const char* format, Args&&... args)
    {
        if (level < s_Level) return;
        
        // 获取时间戳
        auto now = std::chrono::system_clock::now();
        auto time = std::chrono::system_clock::to_time_t(now);
        
        // 格式化消息
        char buffer[4096];
        snprintf(buffer, sizeof(buffer), format, std::forward<Args>(args)...);
        
        // 输出
        std::cout << "[" << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S") << "] ";
        std::cout << LevelToString(level) << ": " << buffer << std::endl;
        
        // 写入文件
        if (s_File.is_open())
        {
            s_File << "[" << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S") << "] ";
            s_File << LevelToString(level) << ": " << buffer << std::endl;
        }
    }
    
private:
    static Level s_Level;
    static std::ofstream s_File;
    
    static const char* LevelToString(Level level)
    {
        switch (level)
        {
            case Level::Trace:   return "TRACE";
            case Level::Debug:   return "DEBUG";
            case Level::Info:    return "INFO";
            case Level::Warning: return "WARNING";
            case Level::Error:   return "ERROR";
            case Level::Fatal:   return "FATAL";
            default: return "UNKNOWN";
        }
    }
};

// 便捷宏
#define LOG_TRACE(...)   Logger::Log(Logger::Level::Trace, __VA_ARGS__)
#define LOG_DEBUG(...)   Logger::Log(Logger::Level::Debug, __VA_ARGS__)
#define LOG_INFO(...)    Logger::Log(Logger::Level::Info, __VA_ARGS__)
#define LOG_WARNING(...) Logger::Log(Logger::Level::Warning, __VA_ARGS__)
#define LOG_ERROR(...)   Logger::Log(Logger::Level::Error, __VA_ARGS__)
#define LOG_FATAL(...)   Logger::Log(Logger::Level::Fatal, __VA_ARGS__)
```

## 测试最佳实践

### 1. 测试命名规范

```cpp
// ✅ 推荐：清晰的测试命名
TEST(Vector3Test, Length_ReturnsCorrectValue_ForNormalizedVector)
TEST(Vector3Test, Normalize_ThrowsException_ForZeroVector)
TEST(ECS, CreateEntity_ReturnsValidID_WhenWorldIsInitialized)

// ❌ 不推荐：模糊的测试命名
TEST(Vector3Test, Test1)
TEST(ECS, TestCreate)
```

### 2. 测试组织

```
tests/
├── unit/                    # 单元测试
│   ├── math/               # 数学库测试
│   │   ├── vector3_test.cpp
│   │   ├── matrix4_test.cpp
│   │   └── quaternion_test.cpp
│   ├── core/               # 核心系统测试
│   │   ├── memory_test.cpp
│   │   └── string_test.cpp
│   └── ecs/                # ECS 测试
│       ├── entity_test.cpp
│       └── component_test.cpp
├── integration/            # 集成测试
│   ├── render/
│   └── physics/
├── performance/            # 性能测试
│   └── benchmark.cpp
└── fixtures/               # 测试数据
    ├── models/
    └── textures/
```

## 相关技能

- **engine-project-context** - 读取测试配置
- **engine-cpp-foundations** - 使用断言和日志
- **engine-architecture** - 测试架构设计
