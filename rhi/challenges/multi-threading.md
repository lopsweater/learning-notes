# 多线程渲染

## 概述

多线程渲染利用多核 CPU 并行录制命令，提高渲染效率。

## 命令录制并行化

```cpp
// 每线程独立的命令池和缓冲区
struct ThreadContext {
    VkCommandPool commandPool;
    std::vector<VkCommandBuffer> commandBuffers;
    std::mutex mutex;
};

class ParallelCommandRecorder {
    std::vector<ThreadContext> m_contexts;
    uint32_t m_threadCount;
    
public:
    void RecordParallel(const RenderTask* tasks, uint32_t taskCount) {
        std::vector<std::thread> threads;
        std::atomic<uint32_t> taskIndex{0};
        
        for (uint32_t i = 0; i < m_threadCount; i++) {
            threads.emplace_back([&, i]() {
                auto& ctx = m_contexts[i];
                VkCommandBuffer cmd = AllocateCommandBuffer(ctx);
                
                vkBeginCommandBuffer(cmd, &beginInfo);
                
                while (true) {
                    uint32_t idx = taskIndex.fetch_add(1);
                    if (idx >= taskCount) break;
                    
                    RecordTask(cmd, tasks[idx]);
                }
                
                vkEndCommandBuffer(cmd);
                
                std::lock_guard<std::mutex> lock(ctx.mutex);
                ctx.commandBuffers.push_back(cmd);
            });
        }
        
        for (auto& thread : threads) {
            thread.join();
        }
    }
};
```

## 资源创建并行化

```cpp
class ThreadSafeResourceManager {
    std::mutex m_mutex;
    std::unordered_map<std::string, RHITexture*> m_textures;
    
public:
    RHITexture* GetOrCreateTexture(const std::string& name, 
                                    const TextureDesc& desc) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            auto it = m_textures.find(name);
            if (it != m_textures.end()) {
                return it->second;
            }
        }
        
        // 创建在锁外进行
        RHITexture* texture = m_device->CreateTexture(desc);
        
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            // 双重检查
            auto it = m_textures.find(name);
            if (it != m_textures.end()) {
                delete texture;  // 已被其他线程创建
                return it->second;
            }
            m_textures[name] = texture;
            return texture;
        }
    }
};
```

## 描述符更新并行化

```cpp
class ThreadSafeDescriptorAllocator {
    std::atomic<uint32_t> m_offset{0};
    VkDescriptorPool m_pool;
    uint32_t m_descriptorSize;
    
public:
    VkDescriptorSet Allocate(VkDescriptorSetLayout layout) {
        uint32_t offset = m_offset.fetch_add(m_descriptorSize);
        
        // 使用线性分配，无需锁
        VkDescriptorSetAllocateInfo allocInfo = {};
        allocInfo.descriptorPool = m_pool;
        allocInfo.descriptorSetCount = 1;
        allocInfo.pSetLayouts = &layout;
        
        VkDescriptorSet set;
        vkAllocateDescriptorSets(device, &allocInfo, &set);
        return set;
    }
};
```

## D3D12 多线程

```cpp
// 每线程独立的命令分配器
class D3D12ThreadContext {
    ID3D12CommandAllocator* m_allocator;
    ID3D12GraphicsCommandList* m_commandList;
    
public:
    void BeginFrame() {
        m_allocator->Reset();
        m_commandList->Reset(m_allocator, nullptr);
    }
    
    void EndFrame() {
        m_commandList->Close();
    }
};

// 提交所有线程的命令
void SubmitAll(std::vector<D3D12ThreadContext>& contexts) {
    std::vector<ID3D12CommandList*> cmdLists;
    for (auto& ctx : contexts) {
        cmdLists.push_back(ctx.GetCommandList());
    }
    queue->ExecuteCommandLists(cmdLists.size(), cmdLists.data());
}
```

## 最佳实践

### ✅ 推荐

1. **每线程独立命令池** - 避免锁竞争
2. **并行录制** - 充分利用多核
3. **批量提交** - 减少 API 调用
4. **无锁数据结构** - 减少同步开销

### ❌ 避免

1. **共享命令缓冲区** - 线程不安全
2. **过度锁粒度** - 性能下降
3. **频繁同步** - 并行度降低

## 相关文件

- [synchronization-hazards.md](./synchronization-hazards.md) - 同步危害
- [../patterns/command-buffer.md](../patterns/command-buffer.md) - 命令缓冲区模式
