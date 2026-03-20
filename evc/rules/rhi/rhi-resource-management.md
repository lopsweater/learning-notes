---
paths:
  - "src/rhi/**/*"
---
# RHI 资源管理规则

> 此文件定义 RHI 资源生命周期管理的规则和最佳实践。

## 资源生命周期

### 创建 → 使用 → 销毁

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Create    │ ──► │    Use      │ ──► │   Destroy   │
│  (分配资源)  │     │  (使用资源)  │     │  (释放资源)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

### 关键原则

1. **显式创建** - 所有资源由用户显式创建
2. **显式销毁** - 所有资源由用户显式销毁
3. **生命周期管理** - 资源在使用期间必须有效
4. **延迟销毁** - GPU 使用完成后才能销毁

## 资源类型

### Buffer 资源

| 类型 | 用途 | 内存位置 |
|------|------|----------|
| Vertex Buffer | 顶点数据 | Device Local |
| Index Buffer | 索引数据 | Device Local |
| Constant Buffer | 常量数据 | Upload |
| Storage Buffer | 读写数据 | Device Local |

### Texture 资源

| 类型 | 用途 | 内存位置 |
|------|------|----------|
| Render Target | 渲染输出 | Device Local |
| Depth Stencil | 深度测试 | Device Local |
| Shader Resource | 纹理采样 | Device Local |
| Storage Image | 读写图像 | Device Local |

### Descriptor 资源

| 类型 | 用途 |
|------|------|
| CBV | 常量缓冲区视图 |
| SRV | 着色器资源视图 |
| UAV | 无序访问视图 |
| Sampler | 采样器 |

## 资源池化

### Buffer Pool

```cpp
class BufferPool {
public:
    BufferPool(RHIDevice* device, size_t bufferSize, size_t poolSize);
    ~BufferPool();
    
    // 分配（复用或创建）
    RHIBuffer* Allocate(size_t size, size_t alignment);
    
    // 重置（不销毁，等待下一帧复用）
    void Reset(uint64_t fenceValue);
    
private:
    RHIDevice* device_;
    std::vector<RHIBuffer*> buffers_;
    size_t bufferSize_;
    size_t poolSize_;
    size_t currentIndex_;
};
```

### Descriptor Heap Pool

```cpp
class DescriptorHeapPool {
public:
    DescriptorHeapPool(RHIDevice* device, uint32_t descriptorCount);
    ~DescriptorHeapPool();
    
    // 分配描述符
    DescriptorHandle Allocate();
    
    // 释放描述符（延迟）
    void Free(DescriptorHandle handle, uint64_t fenceValue);
    
private:
    RHIDevice* device_;
    std::vector<DescriptorHandle> freeList_;
    std::queue<std::pair<uint64_t, DescriptorHandle>> deferredFreeList_;
};
```

## 延迟销毁

### 为什么需要延迟销毁

GPU 执行是异步的，资源可能仍在使用中：

```
CPU: 提交命令 → 销毁资源
GPU:          ← 使用资源（崩溃！）
```

### 延迟销毁实现

```cpp
class DeferredDeleter {
public:
    // 添加待销毁资源
    void EnqueueBuffer(RHIBuffer* buffer, uint64_t fenceValue) {
        std::lock_guard<std::mutex> lock(mutex_);
        deferredBuffers_.push({fenceValue, buffer});
    }
    
    // 处理已完成帧的资源
    void ProcessCompleted(uint64_t completedFenceValue) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        while (!deferredBuffers_.empty()) {
            auto& [fenceValue, buffer] = deferredBuffers_.front();
            if (fenceValue <= completedFenceValue) {
                device_->DestroyBuffer(buffer);
                deferredBuffers_.pop();
            } else {
                break;
            }
        }
    }
    
private:
    RHIDevice* device_;
    std::mutex mutex_;
    std::queue<std::pair<uint64_t, RHIBuffer*>> deferredBuffers_;
};
```

### 使用示例

```cpp
void DestroyBuffer(RHIBuffer* buffer) {
    // 不立即销毁，加入延迟队列
    uint64_t currentFenceValue = GetCurrentFenceValue();
    deferredDeleter_->EnqueueBuffer(buffer, currentFenceValue);
}

void BeginFrame() {
    // 处理已完成帧的资源
    uint64_t completedFenceValue = fence_->GetCompletedValue();
    deferredDeleter_->ProcessCompleted(completedFenceValue);
}
```

## 资源状态管理

### 状态转换规则

| 资源类型 | 初始状态 | 常见状态 |
|----------|----------|----------|
| Vertex Buffer | Common | VertexBuffer |
| Index Buffer | Common | IndexBuffer |
| Constant Buffer | Generic Read | ConstantBuffer |
| Render Target | Common | RenderTarget, Present |
| Depth Texture | Common | DepthWrite, DepthRead |

### 状态转换示例

```cpp
// 渲染到纹理，然后采样
void RenderToTexture(RHICommandList* cmd, RHITexture* texture) {
    // 转换到渲染目标
    cmd->TextureBarrier(texture, 
        ResourceState::Common, 
        ResourceState::RenderTarget
    );
    
    // 渲染
    cmd->SetRenderTarget(texture);
    cmd->Draw();
    
    // 转换到着色器资源
    cmd->TextureBarrier(texture, 
        ResourceState::RenderTarget, 
        ResourceState::ShaderResource
    );
    
    // 后处理采样
    cmd->SetShaderResource(0, texture);
    cmd->Draw();
}
```

### 常见错误

```cpp
// ❌ 错误：缺少状态转换
void RenderToTexture(RHICommandList* cmd, RHITexture* texture) {
    cmd->SetRenderTarget(texture);  // 状态未转换
    cmd->Draw();
}

// ❌ 错误：状态转换不完整
void RenderToTexture(RHICommandList* cmd, RHITexture* texture) {
    cmd->TextureBarrier(texture, Common, RenderTarget);
    cmd->Draw();
    // 缺少转换到 ShaderResource
    cmd->SetShaderResource(0, texture);  // 错误状态
}

// ✅ 正确：完整状态转换
void RenderToTexture(RHICommandList* cmd, RHITexture* texture) {
    cmd->TextureBarrier(texture, Common, RenderTarget);
    cmd->Draw();
    cmd->TextureBarrier(texture, RenderTarget, ShaderResource);
    cmd->SetShaderResource(0, texture);
}
```

## 内存对齐要求

### D3D12 对齐要求

| 资源类型 | 对齐要求 |
|----------|----------|
| Constant Buffer | 256 字节 |
| Raw Buffer | 4 字节 |
| Texture | 64KB（MSAA: 4MB） |

### Vulkan 对齐要求

```cpp
// 从设备属性获取
VkPhysicalDeviceProperties props;
vkGetPhysicalDeviceProperties(physicalDevice, &props);

// 使用对齐要求
size_t alignment = props.limits.minUniformBufferOffsetAlignment;
```

### 对齐辅助函数

```cpp
inline size_t AlignUp(size_t size, size_t alignment) {
    return (size + alignment - 1) & ~(alignment - 1);
}

inline size_t AlignConstantBuffer(size_t size) {
    return AlignUp(size, 256);  // D3D12 要求
}
```

## 资源泄漏检测

### RAII 包装

```cpp
template<typename T>
class RHIResourcePtr {
public:
    RHIResourcePtr() = default;
    RHIResourcePtr(RHIDevice* device, T* resource)
        : device_(device), resource_(resource) {}
    
    ~RHIResourcePtr() {
        if (resource_ && device_) {
            DestroyResource(resource_);
        }
    }
    
    // 禁止拷贝
    RHIResourcePtr(const RHIResourcePtr&) = delete;
    RHIResourcePtr& operator=(const RHIResourcePtr&) = delete;
    
    // 允许移动
    RHIResourcePtr(RHIResourcePtr&& other) noexcept
        : device_(other.device_), resource_(other.resource_) {
        other.device_ = nullptr;
        other.resource_ = nullptr;
    }
    
    T* Get() const { return resource_; }
    T** GetAddressOf() { return &resource_; }
    
private:
    void DestroyResource(T* resource);  // 特化实现
    
    RHIDevice* device_ = nullptr;
    T* resource_ = nullptr;
};

// 特化
template<>
void RHIResourcePtr<RHIBuffer>::DestroyResource(RHIBuffer* buffer) {
    device_->DestroyBuffer(buffer);
}
```

### 调试跟踪

```cpp
#ifdef _DEBUG
#define TRACK_RESOURCE(resource, name) \
    ResourceTracker::Get().Track(resource, name)
#else
#define TRACK_RESOURCE(resource, name)
#endif
```

## 资源管理检查清单

- [ ] 所有资源有显式创建
- [ ] 所有资源有显式销毁
- [ ] 使用延迟销毁队列
- [ ] 资源状态转换完整
- [ ] 内存对齐正确
- [ ] 无资源泄漏
- [ ] 使用 RAII 包装

## 相关文件

- [rhi-interface-design.md](./rhi-interface-design.md) - 接口设计规则
- [rhi-backend-implementation.md](./rhi-backend-implementation.md) - 后端实现规则
