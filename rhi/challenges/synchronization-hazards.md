# 同步危害

## 常见同步问题

### 1. 数据竞争 (Data Race)

```
问题：CPU 和 GPU 同时访问同一资源

CPU: Write Buffer → GPU: Read Buffer (冲突！)

解决：使用 Fence 同步
```

```cpp
// 错误示例
void UpdateBuffer(RHIBuffer* buffer, void* data) {
    memcpy(buffer->Map(), data, size);  // CPU 写入
    // 没有等待！GPU 可能正在读取
    commandList->UseBuffer(buffer);     // GPU 使用
}

// 正确示例
void UpdateBuffer(RHIBuffer* buffer, void* data) {
    fence->Wait(frameValues[currentFrame]);  // 等待 GPU 完成
    memcpy(buffer->Map(), data, size);
    commandList->UseBuffer(buffer);
    frameValues[currentFrame] = ++fenceValue;
    queue->Signal(fence, fenceValue);
}
```

### 2. 写后读 (RAW - Read After Write)

```
问题：读取发生在写入完成之前

Pass 1: Write Texture A
Pass 2: Read Texture A (可能在 Pass 1 完成前开始！)

解决：插入 Resource Barrier
```

```cpp
// D3D12
commandList->ResourceBarrier(1, &CD3DX12_RESOURCE_BARRIER::Transition(
    textureA,
    D3D12_RESOURCE_STATE_UNORDERED_ACCESS,
    D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE
));

// Vulkan
VkImageMemoryBarrier barrier = {};
barrier.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT;
barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
// ...
vkCmdPipelineBarrier(...);
```

### 3. 读后写 (WAR - Write After Read)

```
问题：写入发生在读取完成之前

Pass 1: Read Texture A
Pass 2: Write Texture A (可能覆盖 Pass 1 的读取)

解决：Barrier 确保顺序
```

### 4. 写后写 (WAW - Write After Write)

```
问题：两个写入操作顺序不确定

Pass 1: Write Texture A
Pass 2: Write Texture A (顺序不确定)

解决：Barrier 确保写入顺序
```

### 5. 死锁 (Deadlock)

```
问题：循环等待

Queue A: Wait Fence B
Queue B: Wait Fence A
→ 永远等待

解决：确保有向无环图 (DAG)
```

```cpp
// 死锁示例
graphicsQueue->Wait(computeFence);  // Graphics 等待 Compute
computeQueue->Wait(graphicsFence);  // Compute 等待 Graphics
// 死锁！

// 正确：单向依赖
computeQueue->Signal(computeFence);
graphicsQueue->Wait(computeFence);  // Graphics 等待 Compute 完成
```

### 6. 队列族所有权转移

```
问题：跨队列族访问资源

Graphics Queue: 使用 Texture A
Compute Queue: 使用 Texture A (所有权问题)

解决：显式所有权转移
```

```cpp
// Vulkan 所有权转移
VkImageMemoryBarrier barrier = {};
barrier.srcQueueFamilyIndex = graphicsFamily;
barrier.dstQueueFamilyIndex = computeFamily;
// ...
```

## 同步策略

### Fence 使用场景

- CPU 等待 GPU
- 帧同步

### Semaphore 使用场景

- GPU 等待 GPU
- 跨队列同步

### Barrier 使用场景

- 同一队列内的资源状态转换
- 确保操作顺序

## 相关文件

- [../design/synchronization-model.md](../design/synchronization-model.md) - 同步模型设计
- [multi-threading.md](./multi-threading.md) - 多线程渲染
