# RHI 最佳实践

## 资源管理

### 创建和销毁

```cpp
// ✅ 推荐：延迟销毁
class ResourceDeletionQueue {
    std::queue<std::pair<RHIResource*, uint64_t>> m_queue;
    
public:
    void Enqueue(RHIResource* resource, uint64_t fenceValue) {
        m_queue.push({resource, fenceValue});
    }
    
    void Process(uint64_t completedValue) {
        while (!m_queue.empty() && m_queue.front().second <= completedValue) {
            delete m_queue.front().first;
            m_queue.pop();
        }
    }
};

// ❌ 避免：立即销毁
void UseResource() {
    RHITexture* tex = CreateTexture();
    Draw(tex);
    delete tex;  // GPU 可能还在使用！
}
```

### 内存管理

```cpp
// ✅ 推荐：分帧线性分配
class FrameLinearAllocator {
    LinearAllocator m_allocators[FRAME_COUNT];
    
public:
    void BeginFrame(uint32_t frameIndex) {
        m_allocators[frameIndex].Reset();
    }
};

// ❌ 避免：频繁分配释放
void PerFrameAllocation() {
    RHIBuffer* buffer = CreateBuffer(size);  // 每帧创建
    UseBuffer(buffer);
    DeleteBuffer(buffer);  // 每帧销毁 - 碎片化
}
```

## 命令提交

### 批量提交

```cpp
// ✅ 推荐：批量提交
std::vector<RHICommandList*> cmdLists;
for (auto& cmd : commands) {
    cmdLists.push_back(cmd);
}
queue->Submit(cmdLists.data(), cmdLists.size());

// ❌ 避免：多次单独提交
for (auto& cmd : commands) {
    queue->Submit(&cmd, 1);  // 开销大
}
```

### 状态排序

```cpp
// ✅ 推荐：按状态排序减少切换
std::sort(draws.begin(), draws.end(), [](const Draw& a, const Draw& b) {
    if (a.pipeline != b.pipeline) return a.pipeline < b.pipeline;
    if (a.material != b.material) return a.material < b.material;
    return a.mesh < b.mesh;
});
```

## 描述符管理

### 分帧管理

```cpp
// ✅ 推荐：每帧独立描述符空间
class FrameDescriptorAllocator {
    static const uint32_t DESCRIPTORS_PER_FRAME = 1000;
    
    uint32_t m_currentOffset;
    
public:
    void BeginFrame() {
        m_currentOffset = (currentFrame * DESCRIPTORS_PER_FRAME);
    }
    
    uint32_t Allocate(uint32_t count) {
        uint32_t offset = m_currentOffset;
        m_currentOffset += count;
        return offset;
    }
};
```

## 同步

### 最小化同步

```cpp
// ✅ 推荐：帧末尾同步
void RenderFrame() {
    for (auto& pass : passes) {
        ExecutePass(pass);
    }
    queue->Signal(fence, ++fenceValue);  // 一次同步
}

// ❌ 避免：频繁同步
void RenderFrame() {
    for (auto& pass : passes) {
        ExecutePass(pass);
        fence->Wait();  // 每次等待 - GPU 空闲
    }
}
```

## 多线程

### 并行录制

```cpp
// ✅ 推荐：并行录制命令
std::vector<std::thread> threads;
for (int i = 0; i < threadCount; i++) {
    threads.emplace_back([&, i]() {
        RecordCommands(commandLists[i]);
    });
}
for (auto& t : threads) t.join();
queue->Submit(commandLists);

// ❌ 避免：单线程录制
for (auto& cmd : commands) {
    RecordCommands(cmd);  // 串行
}
```

## 相关文件

- [d3d12-spec.md](./d3d12-spec.md) - D3D12 文档
- [vulkan-spec.md](./vulkan-spec.md) - Vulkan 文档
