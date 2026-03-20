# RHI 同步模型设计

## 同步原语抽象

```
┌─────────────────────────────────────────────────────────────┐
│                     同步场景                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CPU ←──► GPU      Fence                                   │
│  GPU ←──► GPU      Semaphore (Vulkan) / Fence (D3D12)      │
│  Queue ──► Queue   Semaphore / Fence                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Fence 抽象

```cpp
// Fence 接口
class RHIFence {
public:
    // 获取当前完成值
    virtual uint64_t GetCompletedValue() = 0;
    
    // CPU 等待指定值
    virtual void Wait(uint64_t value, uint64_t timeout = UINT64_MAX) = 0;
    
    // CPU 发出信号
    virtual void Signal(uint64_t value) = 0;
};

// Fence 使用示例
class FrameSync {
    static const uint32_t FRAME_COUNT = 3;
    
    RHIFence* m_fence;
    uint64_t m_frameValues[FRAME_COUNT] = {0, 0, 0};
    uint64_t m_currentValue = 0;
    
public:
    void BeginFrame(uint32_t frameIndex) {
        // 等待该帧的 GPU 工作完成
        m_fence->Wait(m_frameValues[frameIndex]);
    }
    
    void EndFrame(uint32_t frameIndex, RHICommandQueue* queue) {
        m_currentValue++;
        m_frameValues[frameIndex] = m_currentValue;
        
        // GPU 发出信号
        queue->Signal(m_fence, m_currentValue);
    }
};
```

## Semaphore 抽象

```cpp
// Semaphore 接口 (Vulkan 需要)
class RHISemaphore {
public:
    virtual void Signal() = 0;
    virtual void Wait() = 0;
};

// Semaphore 使用示例 (跨队列同步)
void CrossQueueSync(
    RHICommandQueue* graphicsQueue,
    RHICommandQueue* computeQueue,
    RHISemaphore* semaphore
) {
    // 计算队列完成工作后发送信号
    computeQueue->Submit(...);
    computeQueue->Signal(semaphore);
    
    // 图形队列等待计算完成
    graphicsQueue->Wait(semaphore);
    graphicsQueue->Submit(...);
}
```

## D3D12 vs Vulkan 同步映射

| 场景 | D3D12 | Vulkan |
|------|-------|--------|
| CPU 等待 GPU | Fence.Wait() | vkWaitForFences() |
| GPU 信号 CPU | Fence.Signal() | vkSignalSemaphore() |
| 队列间同步 | Cross-Queue Fence | Semaphore |
| 时间线同步 | ID3D12Fence (Timeline) | VkSemaphore (Timeline) |

### D3D12 同步

```cpp
// D3D12 Fence 同步
ID3D12Fence* fence;
device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));

// GPU Signal
commandQueue->Signal(fence, fenceValue);

// CPU Wait
HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
fence->SetEventOnCompletion(fenceValue, event);
WaitForSingleObject(event, INFINITE);
CloseHandle(event);
```

### Vulkan 同步

```cpp
// Vulkan Fence 同步
VkFence fence;
vkCreateFence(device, &fenceInfo, nullptr, &fence);

// 提交带 Fence
vkQueueSubmit(queue, 1, &submitInfo, fence);

// CPU Wait
vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX);
vkResetFences(device, 1, &fence);

// Semaphore 跨队列同步
VkSemaphore semaphore;
VkSubmitInfo submitInfo = {};
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = &semaphore;
vkQueueSubmit(computeQueue, 1, &submitInfo, VK_NULL_HANDLE);

submitInfo.waitSemaphoreCount = 1;
submitInfo.pWaitSemaphores = &semaphore;
vkQueueSubmit(graphicsQueue, 1, &submitInfo, VK_NULL_HANDLE);
```

## 帧同步策略

### 三缓冲同步

```
Frame 0: [CPU] ──► [GPU] ──► Fence(1)
Frame 1: [CPU] ──► [GPU] ──► Fence(2)
Frame 2: [CPU] ──► [GPU] ──► Fence(3)
                        │
                        ▼
                   Fence(0) 完成 → Frame 0 可复用
```

```cpp
class TripleBuffering {
    static const uint32_t FRAME_COUNT = 3;
    
    RHIFence* m_fence;
    uint64_t m_frameValues[FRAME_COUNT] = {};
    uint32_t m_currentFrame = 0;
    
public:
    void BeginFrame() {
        // 等待当前帧的 GPU 工作完成
        m_fence->Wait(m_frameValues[m_currentFrame]);
    }
    
    void EndFrame(RHICommandQueue* queue) {
        static uint64_t s_counter = 0;
        s_counter++;
        
        m_frameValues[m_currentFrame] = s_counter;
        queue->Signal(m_fence, s_counter);
        
        m_currentFrame = (m_currentFrame + 1) % FRAME_COUNT;
    }
};
```

## 同步最佳实践

### ✅ 推荐

1. **使用时间线 Fence** - 更清晰的同步模型
2. **最小化同步点** - 减少 GPU 空闲
3. **批量提交** - 减少同步开销
4. **帧延迟队列** - 延迟销毁资源

### ❌ 避免

1. **过度同步** - 每次操作都等待
2. **CPU-GPU 频繁交互** - 增加延迟
3. **忽略多队列同步** - 导致数据竞争

## 相关文件

- [command-model.md](./command-model.md) - 命令模型设计
- [../patterns/deferred-destruction.md](../patterns/deferred-destruction.md) - 延迟销毁模式
