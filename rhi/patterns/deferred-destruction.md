# 延迟销毁

## 概述

GPU 资源不能在 CPU 端立即销毁，必须等待 GPU 使用完成。延迟销毁模式确保资源安全释放。

## 问题背景

```cpp
// 错误示例：立即销毁
RHIBuffer* buffer = CreateBuffer();
UseBuffer(buffer);  // GPU 正在使用
delete buffer;      // 危险！GPU 可能还在使用

// 正确方式：等待 GPU
RHIBuffer* buffer = CreateBuffer();
UseBuffer(buffer);
WaitForGPU();       // 等待 GPU 完成
delete buffer;      // 安全
```

## 延迟销毁队列

```cpp
class DeferredDeletionQueue {
    struct Entry {
        RHIResource* resource;
        uint64_t fenceValue;
        RHIFence* fence;
    };
    
    std::queue<Entry> m_queue;
    RHIFence* m_fence;
    
public:
    // 添加待销毁资源
    void Enqueue(RHIResource* resource, uint64_t fenceValue) {
        m_queue.push({resource, fenceValue, m_fence});
    }
    
    // 处理已完成资源
    void Process() {
        while (!m_queue.empty()) {
            auto& entry = m_queue.front();
            
            if (entry.fence->GetCompletedValue() >= entry.fenceValue) {
                delete entry.resource;
                m_queue.pop();
            } else {
                break;  // 后续资源都未完成
            }
        }
    }
    
    // 清空（等待所有资源）
    void Flush() {
        while (!m_queue.empty()) {
            auto& entry = m_queue.front();
            entry.fence->Wait(entry.fenceValue);
            delete entry.resource;
            m_queue.pop();
        }
    }
};
```

## 帧延迟队列

```cpp
class FrameDeletionQueue {
    static const uint32_t FRAME_COUNT = 3;
    
    std::queue<RHIResource*> m_queues[FRAME_COUNT];
    uint32_t m_currentFrame = 0;
    
public:
    // 添加资源到当前帧
    void Enqueue(RHIResource* resource) {
        m_queues[m_currentFrame].push(resource);
    }
    
    // 帧结束（标记资源可销毁）
    void EndFrame(RHIFence* fence, uint64_t fenceValue) {
        m_currentFrame = (m_currentFrame + 1) % FRAME_COUNT;
        
        // 等待帧 fence
        fence->Wait(fenceValue);
        
        // 销毁资源
        while (!m_queues[m_currentFrame].empty()) {
            delete m_queues[m_currentFrame].front();
            m_queues[m_currentFrame].pop();
        }
    }
};
```

## 分帧资源管理

```cpp
class FrameResourceManager {
    struct FrameResources {
        std::vector<std::unique_ptr<RHIResource>> resources;
        uint64_t fenceValue;
    };
    
    FrameResources m_frames[3];
    uint32_t m_currentFrame = 0;
    RHIFence* m_fence;
    
public:
    void BeginFrame() {
        uint32_t frameIndex = m_currentFrame;
        
        // 等待该帧 GPU 完成
        m_fence->Wait(m_frames[frameIndex].fenceValue);
        
        // 清空资源（自动析构 unique_ptr）
        m_frames[frameIndex].resources.clear();
    }
    
    void EndFrame(uint64_t fenceValue) {
        m_frames[m_currentFrame].fenceValue = fenceValue;
        m_currentFrame = (m_currentFrame + 1) % 3;
    }
    
    // 注册临时资源
    void RegisterResource(std::unique_ptr<RHIResource> resource) {
        m_frames[m_currentFrame].resources.push_back(std::move(resource));
    }
};
```

## 使用示例

```cpp
DeferredDeletionQueue deletionQueue(fence);

// 销毁资源
void DestroyResource(RHIResource* resource) {
    uint64_t currentValue = fence->GetCompletedValue() + 1;
    deletionQueue.Enqueue(resource, currentValue);
}

// 每帧处理
void OnFrameEnd() {
    deletionQueue.Process();
}

// 应用退出时
void OnShutdown() {
    deletionQueue.Flush();
}
```

## 最佳实践

### ✅ 推荐

1. **分帧管理** - 使用 N 帧延迟
2. **批量处理** - 减少单独销毁
3. **资源池化** - 优先复用而非销毁
4. **显式同步** - Fence + Frame Index

### ❌ 避免

1. **立即销毁** - GPU 可能还在使用
2. **无限延迟** - 内存泄漏
3. **忽略同步** - 资源竞争

## 相关文件

- [resource-pool.md](./resource-pool.md) - 资源池模式
- [../design/synchronization-model.md](../design/synchronization-model.md) - 同步模型
