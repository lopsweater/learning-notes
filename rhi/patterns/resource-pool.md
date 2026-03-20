# 资源池模式

## 概述

资源池模式用于管理和复用 GPU 资源，避免频繁创建和销毁资源带来的性能开销。

## 设计目标

- ✅ 减少资源创建/销毁开销
- ✅ 复用临时资源
- ✅ 控制内存使用
- ✅ 支持多线程安全

## 实现

### 资源池接口

```cpp
template<typename T>
class ResourcePool {
    struct PoolEntry {
        std::unique_ptr<T> resource;
        bool inUse;
        uint64_t lastUsedFrame;
    };
    
    std::vector<PoolEntry> m_pool;
    std::mutex m_mutex;
    
public:
    // 获取资源
    T* Acquire(const typename T::Desc& desc) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        // 查找匹配且未使用的资源
        for (auto& entry : m_pool) {
            if (!entry.inUse && entry.resource->Matches(desc)) {
                entry.inUse = true;
                entry.lastUsedFrame = GetCurrentFrame();
                return entry.resource.get();
            }
        }
        
        // 创建新资源
        auto resource = CreateResource(desc);
        m_pool.push_back({std::move(resource), true, GetCurrentFrame()});
        return m_pool.back().resource.get();
    }
    
    // 释放资源
    void Release(T* resource) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        for (auto& entry : m_pool) {
            if (entry.resource.get() == resource) {
                entry.inUse = false;
                break;
            }
        }
    }
    
    // 清理未使用资源
    void Cleanup(uint64_t threshold) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        auto it = std::remove_if(m_pool.begin(), m_pool.end(),
            [&](const PoolEntry& entry) {
                return !entry.inUse && 
                       (GetCurrentFrame() - entry.lastUsedFrame) > threshold;
            });
        
        m_pool.erase(it, m_pool.end());
    }
};
```

### Buffer 池

```cpp
class BufferPool : public ResourcePool<RHIBuffer> {
public:
    std::unique_ptr<RHIBuffer> CreateResource(const BufferDesc& desc) {
        return m_device->CreateBuffer(desc);
    }
};

// 使用示例
BufferPool bufferPool(device);

// 获取临时 Buffer
BufferDesc desc = { 1024, 0, BufferUsage::ConstantBuffer, MemoryType::Upload };
RHIBuffer* buffer = bufferPool.Acquire(desc);

// 使用 Buffer
// ...

// 释放 Buffer
bufferPool.Release(buffer);
```

### Texture 池

```cpp
class TexturePool : public ResourcePool<RHITexture> {
public:
    std::unique_ptr<RHITexture> CreateResource(const TextureDesc& desc) {
        return m_device->CreateTexture(desc);
    }
};

// 使用示例
TexturePool texturePool(device);

// 获取临时 Render Target
TextureDesc rtDesc = {
    TextureDimension::Texture2D,
    Format::RGBA16Float,
    1920, 1080, 1, 1, 1,
    TextureUsage::RenderTarget,
    ResourceState::RenderTarget
};

RHITexture* renderTarget = texturePool.Acquire(rtDesc);
```

## 线性分配器

用于临时资源的高速分配：

```cpp
class LinearAllocator {
    RHIBuffer* m_buffer;
    uint64_t m_capacity;
    uint64_t m_offset;
    uint8_t* m_mappedData;
    
public:
    LinearAllocator(RHIDevice* device, uint64_t capacity) 
        : m_capacity(capacity), m_offset(0) {
        BufferDesc desc = { capacity, 0, BufferUsage::ConstantBuffer, MemoryType::Upload };
        m_buffer = device->CreateBuffer(desc);
        m_mappedData = (uint8_t*)m_buffer->Map();
    }
    
    // 分配
    Allocation Allocate(uint64_t size, uint64_t alignment) {
        uint64_t alignedOffset = AlignUp(m_offset, alignment);
        
        if (alignedOffset + size > m_capacity) {
            return {};  // 空间不足
        }
        
        m_offset = alignedOffset + size;
        
        return {
            m_buffer,
            alignedOffset,
            m_mappedData + alignedOffset
        };
    }
    
    // 重置（每帧）
    void Reset() {
        m_offset = 0;
    }
};
```

## 分帧资源池

每个帧独立的资源池：

```cpp
template<typename T>
class FrameResourcePool {
    static const uint32_t FRAME_COUNT = 3;
    
    ResourcePool<T> m_pools[FRAME_COUNT];
    uint32_t m_currentFrame = 0;
    
public:
    T* Acquire(const typename T::Desc& desc) {
        return m_pools[m_currentFrame].Acquire(desc);
    }
    
    void Release(T* resource) {
        m_pools[m_currentFrame].Release(resource);
    }
    
    void NextFrame() {
        m_currentFrame = (m_currentFrame + 1) % FRAME_COUNT;
        
        // 清理旧帧资源
        m_pools[m_currentFrame].Cleanup(0);  // 立即清理
    }
};
```

## 最佳实践

### ✅ 推荐

1. **池化高频资源** - Constant Buffer、临时 Render Target
2. **分帧管理** - 避免帧间资源冲突
3. **延迟清理** - 给 GPU 足够时间完成使用
4. **线程安全** - 使用锁或无锁数据结构

### ❌ 避免

1. **池化长期资源** - Mesh、Texture 等应独立管理
2. **过度池化** - 内存占用过高
3. **不及时释放** - 资源泄漏
4. **忽略同步** - 多线程问题

## 相关文件

- [descriptor-management.md](./descriptor-management.md) - 描述符管理
- [deferred-destruction.md](./deferred-destruction.md) - 延迟销毁
