# 命令缓冲区模式

## 概述

命令缓冲区模式用于高效管理和复用 GPU 命令列表，支持多线程录制。

## 命令缓冲区池

```cpp
class CommandListPool {
    RHIDevice* m_device;
    QueueType m_queueType;
    
    std::vector<std::unique_ptr<RHICommandList>> m_lists;
    std::queue<RHICommandList*> m_freeLists;
    std::mutex m_mutex;
    
public:
    CommandListPool(RHIDevice* device, QueueType type)
        : m_device(device), m_queueType(type) {}
    
    RHICommandList* Acquire() {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        if (!m_freeLists.empty()) {
            auto list = m_freeLists.front();
            m_freeLists.pop();
            list->Reset();
            return list;
        }
        
        auto list = m_device->CreateCommandList(m_queueType);
        m_lists.push_back(std::unique_ptr<RHICommandList>(list));
        return list;
    }
    
    void Release(RHICommandList* list) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_freeLists.push(list);
    }
};
```

## 多线程命令录制

```cpp
class ParallelCommandRecorder {
    CommandListPool m_pool;
    uint32_t m_threadCount;
    
public:
    void RecordParallel(
        const std::function<void(RHICommandList*, uint32_t)>& recordFunc
    ) {
        std::vector<RHICommandList*> lists(m_threadCount);
        std::vector<std::thread> threads;
        
        for (uint32_t i = 0; i < m_threadCount; i++) {
            threads.emplace_back([&, i]() {
                auto list = m_pool.Acquire();
                list->Open();
                
                recordFunc(list, i);
                
                list->Close();
                lists[i] = list;
            });
        }
        
        for (auto& thread : threads) {
            thread.join();
        }
        
        return lists;
    }
};
```

## 命令复用 (Bundles)

D3D12 支持 Bundle 复用命令：

```cpp
// 创建 Bundle
class Bundle {
    ID3D12GraphicsCommandList* m_bundle;
    
public:
    void Record(const std::function<void(ID3D12GraphicsCommandList*)>& func) {
        m_bundle->Reset(m_allocator, nullptr);
        func(m_bundle);
        m_bundle->Close();
    }
    
    void Execute(ID3D12GraphicsCommandList* cmdList) {
        cmdList->ExecuteBundle(m_bundle);
    }
};

// Vulkan Secondary Command Buffer
class SecondaryCommandBuffer {
    VkCommandBuffer m_buffer;
    
public:
    void Record(const std::function<void(VkCommandBuffer)>& func) {
        VkCommandBufferBeginInfo beginInfo = {};
        beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        beginInfo.flags = VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;
        
        vkBeginCommandBuffer(m_buffer, &beginInfo);
        func(m_buffer);
        vkEndCommandBuffer(m_buffer);
    }
    
    void Execute(VkCommandBuffer primary) {
        vkCmdExecuteCommands(primary, 1, &m_buffer);
    }
};
```

## 最佳实践

### ✅ 推荐

1. **池化命令列表** - 减少创建开销
2. **并行录制** - 充分利用多核
3. **复用不变命令** - Bundle/Secondary CB
4. **批量提交** - 减少 Submit 调用

### ❌ 避免

1. **每帧创建新命令列表** - 性能差
2. **单线程录制** - 浪费 CPU 性能
3. **过多小命令列表** - 开销大

## 相关文件

- [resource-pool.md](./resource-pool.md) - 资源池模式
- [../design/command-model.md](../design/command-model.md) - 命令模型设计
