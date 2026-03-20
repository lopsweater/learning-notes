# 性能优化

## CPU 优化

### 1. 减少 API 调用

```cpp
// 差：每个物体单独提交
for (auto& obj : objects) {
    commandList->SetPipeline(obj.pipeline);
    commandList->Draw(obj);
}

// 好：按 Pipeline 批量绘制
for (auto& [pipeline, objs] : objectsByPipeline) {
    commandList->SetPipeline(pipeline);
    for (auto& obj : objs) {
        commandList->Draw(obj);
    }
}
```

### 2. 命令列表复用

```cpp
// 使用 Bundle/Secondary Command Buffer
ID3D12GraphicsCommandList* bundle;
bundle->Reset(bundleAllocator, nullptr);
// 录制静态几何体
bundle->DrawInstanced(...);
bundle->Close();

// 每帧执行
commandList->ExecuteBundle(bundle);
```

### 3. 多线程录制

```cpp
// 并行录制命令列表
#pragma omp parallel for
for (int i = 0; i < threadCount; i++) {
    commandLists[i]->Reset(allocators[i], nullptr);
    RecordCommands(commandLists[i], i);
    commandLists[i]->Close();
}
queue->ExecuteCommandLists(threadCount, commandLists);
```

## GPU 优化

### 1. 减少状态切换

```cpp
// 按 Pipeline 排序
std::sort(draws.begin(), draws.end(), [](const Draw& a, const Draw& b) {
    return a.pipeline < b.pipeline;
});
```

### 2. 实例化渲染

```cpp
// 一次绘制多个实例
commandList->DrawIndexedInstanced(
    indexCount,
    instanceCount,  // 实例数量
    0, 0, 0
);
```

### 3. 间接绘制

```cpp
// GPU 驱动绘制
commandList->ExecuteIndirect(
    commandSignature,
    maxCommandCount,
    argumentBuffer,
    argumentOffset,
    countBuffer,
    countOffset
);
```

## 内存优化

### 1. 资源压缩

```cpp
// 使用压缩纹理格式
VkFormat compressedFormats[] = {
    VK_FORMAT_BC1_RGB_UNORM_BLOCK,   // DXT1
    VK_FORMAT_BC3_UNORM_BLOCK,       // DXT5
    VK_FORMAT_BC7_UNORM_BLOCK,       // BC7
};
```

### 2. 资源别名

```cpp
// 生命周期不重叠的资源共享内存
// 见 resource-aliasing.md
```

### 3. 驻留管理

```cpp
// 显存不足时驱逐低优先级资源
if (currentUsage > budget * 0.9) {
    EvictLRUResources();
}
```

## 带宽优化

### 1. 减少数据传输

```cpp
// 使用压缩顶点格式
struct Vertex {
    uint16_t pos[3];      // 而非 float[3]
    uint16_t normal;      // 八面体编码
    uint16_t texCoord;    // 半精度
};
```

### 2. 异步上传

```cpp
// 使用 Copy Queue 异步上传
copyQueue->Submit(uploadCommands);
// 与渲染并行执行
graphicsQueue->Submit(renderCommands);
```

## 同步优化

### 1. 减少同步点

```cpp
// 差：每帧多次同步
for (auto& pass : passes) {
    ExecutePass(pass);
    fence->Wait();  // 等待 GPU
}

// 好：批量提交，一次同步
for (auto& pass : passes) {
    ExecutePass(pass);
}
queue->Signal(fence, value);
fence->Wait(value);  // 最后一次等待
```

### 2. 时间线 Semaphore

```cpp
// Vulkan 1.2+ 时间线 Semaphore
VkSemaphore timelineSemaphore;
uint64_t timelineValue = 0;

queue->Signal(timelineSemaphore, ++timelineValue);
// 其他队列等待
queue->Wait(timelineSemaphore, timelineValue);
```

## 分析工具

| API | 工具 |
|-----|------|
| D3D12 | PIX, NVIDIA Nsight, AMD Radeon GPU Profiler |
| Vulkan | RenderDoc, NVIDIA Nsight, Vulkan Configurator |

## 相关文件

- [multi-threading.md](./multi-threading.md) - 多线程渲染
- [resource-aliasing.md](./resource-aliasing.md) - 资源别名
