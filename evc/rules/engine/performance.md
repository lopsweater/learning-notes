---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
---
# 引擎性能优化策略

## 性能目标

### 帧时间预算

| 目标 FPS | 帧时间预算 | 适用场景 |
|----------|-----------|----------|
| 60 FPS | 16.6ms | 标准 |
| 120 FPS | 8.3ms | 高刷新率 |
| 30 FPS | 33.3ms | 移动端省电 |

### 帧时间分解

| 阶段 | 目标占比 | 说明 |
|------|----------|------|
| Game Logic | 20% | 游戏逻辑更新 |
| Animation | 10% | 动画计算 |
| Culling | 10% | 视锥剔除 |
| Render Submission | 20% | 渲染提交 |
| GPU Render | 40% | GPU 渲染 |

## CPU 优化

### SIMD 优化

#### 适用场景

- 向量运算（Vec3, Vec4）
- 矩阵运算（Mat4）
- 批量数据处理

#### 性能提升预期

| 操作 | 标量 | SIMD (SSE) | 提升 |
|------|------|------------|------|
| Vec3 加法 | 40ns | 10ns | 4x |
| Vec3 点积 | 30ns | 8ns | 3.75x |
| Mat4 乘法 | 400ns | 100ns | 4x |

#### 对齐要求

```cpp
// 正确：对齐到 16 字节
struct alignas(16) Vec4 {
    float x, y, z, w;
};

// 错误：未对齐
struct Vec4 {
    float x, y, z, w;
};
```

### 内存分配优化

#### 分配器选择

| 场景 | 推荐分配器 | 说明 |
|------|-----------|------|
| 每帧临时数据 | 线性分配器 | O(1) 分配，批量释放 |
| 固定大小对象 | 池分配器 | 无碎片 |
| 长生命周期 | 系统堆 | 通用 |

#### 缓存友好

```cpp
// 差：指针追踪
struct GameObject {
    Transform* transform;  // 指针 -> 缓存未命中
    Mesh* mesh;
};

// 好：连续存储
struct Transform { float x, y, z; };
std::vector<Transform> transforms;  // 连续内存 -> 缓存友好
```

## GPU 优化

### Draw Call 优化

| 技术 | 说明 | 预期减少 |
|------|------|----------|
| 实例化 | 相同 Mesh 合批 | 10-100x |
| 静态批处理 | 静态物体合并 | 5-10x |
| 动态批处理 | 动态物体合并 | 2-5x |
| GPU Driven | GPU 驱动渲染 | 100x+ |

### 资源绑定优化

| 技术 | 说明 | 性能影响 |
|------|------|----------|
| Bindless | 无绑定资源 | 显著减少 CPU 开销 |
| Descriptor Heap | 描述符堆 | 减少 API 调用 |
| Root Signature | 根签名优化 | 减少状态切换 |

### 内存带宽优化

| 技术 | 说明 |
|------|------|
| 压缩纹理 | BC7, ASTC |
| 顶点压缩 | 16-bit float |
| 索引压缩 | 16-bit index |
| 实例数据 | Structured Buffer |

## 多线程优化

### Job System

```cpp
// 将任务并行化
jobSystem.Schedule([]() {
    UpdateTransforms();
});

jobSystem.Schedule([]() {
    UpdateAnimations();
});

jobSystem.WaitAll();
```

### Command List 并行

```cpp
// 多线程录制 Command List
std::vector<CommandList*> cmdLists;
for (int i = 0; i < numThreads; ++i) {
    cmdLists.push_back(CreateCommandList());
    // 在线程池中并行录制
}
device->ExecuteCommandLists(cmdLists);
```

## 性能分析工具

### CPU 分析

| 工具 | 用途 |
|------|------|
| Tracy Profiler | 帧级分析 |
| easy_profiler | 轻量级分析 |
| VTune | Intel CPU 深度分析 |

### GPU 分析

| 工具 | 用途 |
|------|------|
| PIX for Windows | D3D12 分析 |
| NVIDIA Nsight | NVIDIA GPU 分析 |
| AMD Radeon GPU Profiler | AMD GPU 分析 |
| RenderDoc | 帧捕获分析 |

## 性能回归检测

### 自动化基准测试

```cpp
TEST(Performance, FrameTimeBudget) {
    Renderer renderer;
    Benchmark benchmark;
    
    for (int i = 0; i < 100; ++i) {
        benchmark.Begin();
        renderer.RenderFrame();
        benchmark.End();
    }
    
    EXPECT_LT(benchmark.AverageMs(), 16.6);
}
```

### CI 集成

```yaml
# .github/workflows/performance.yml
- name: Run Performance Tests
  run: |
    ctest --test-dir build -L performance
```
