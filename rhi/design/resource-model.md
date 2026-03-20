# RHI 资源模型设计

## 资源类型抽象

### 1. Buffer 抽象

```cpp
// Buffer 描述
struct BufferDesc {
    uint64_t size;                    // 大小（字节）
    uint32_t stride;                  // 结构化缓冲步长（0 表示原始缓冲）
    BufferUsage usage;                // 用途标志
    MemoryType memoryType;            // 内存类型
    ResourceState initialState;       // 初始状态
};

// Buffer 用途
enum class BufferUsage : uint32_t {
    None            = 0,
    VertexBuffer    = 1 << 0,
    IndexBuffer     = 1 << 1,
    ConstantBuffer  = 1 << 2,
    ShaderResource  = 1 << 3,
    UnorderedAccess = 1 << 4,
    IndirectBuffer  = 1 << 5,
    CopySrc         = 1 << 6,
    CopyDst         = 1 << 7,
};

// Buffer 接口
class RHIBuffer : public RHIResource {
public:
    virtual void* Map() = 0;
    virtual void Unmap() = 0;
    virtual BufferDesc GetDesc() const = 0;
    virtual uint64_t GetGPUAddress() const = 0;
};
```

### 2. Texture 抽象

```cpp
// Texture 描述
struct TextureDesc {
    TextureDimension dimension;       // 维度
    Format format;                    // 格式
    uint32_t width;                   // 宽度
    uint32_t height;                  // 高度
    uint32_t depth;                   // 深度/层数
    uint16_t mipLevels;               // Mip 层数
    uint16_t sampleCount;             // 采样数
    TextureUsage usage;               // 用途标志
    ResourceState initialState;       // 初始状态
};

// Texture 维度
enum class TextureDimension {
    Texture1D,
    Texture2D,
    Texture3D,
    TextureCube,
    Texture1DArray,
    Texture2DArray,
    TextureCubeArray,
};

// Texture 接口
class RHITexture : public RHIResource {
public:
    virtual TextureDesc GetDesc() const = 0;
    virtual void GenerateMips(RHICommandList* cmdList) = 0;
};
```

## 内存类型抽象

```cpp
// 内存类型
enum class MemoryType {
    Default,     // GPU 专属，GPU 访问最快
    Upload,      // CPU 可写，用于上传数据
    Readback,    // CPU 可读，用于读取数据
    Custom,      // 自定义内存类型
};

// 内存属性
enum class MemoryProperty : uint32_t {
    None           = 0,
    DeviceLocal    = 1 << 0,   // GPU 本地内存
    HostVisible    = 1 << 1,   // CPU 可见
    HostCoherent   = 1 << 2,   // CPU 一致性
    HostCached     = 1 << 3,   // CPU 缓存
    LazilyAllocated = 1 << 4,  // 延迟分配
};
```

## D3D12 vs Vulkan 资源映射

| RHI 抽象 | D3D12 | Vulkan |
|---------|-------|--------|
| RHIBuffer | ID3D12Resource | VkBuffer + VkDeviceMemory |
| RHITexture | ID3D12Resource | VkImage + VkDeviceMemory |
| MemoryType::Default | D3D12_HEAP_TYPE_DEFAULT | VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT |
| MemoryType::Upload | D3D12_HEAP_TYPE_UPLOAD | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
| MemoryType::Readback | D3D12_HEAP_TYPE_READBACK | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |

## 资源生命周期

```
┌────────────────────────────────────────────────────────────┐
│                    资源生命周期                             │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   Create ──► Ready ──► InUse ──► Pending ──► Destroy     │
│     │          │          │          │          │         │
│     │          │          │          │          │         │
│     ▼          ▼          ▼          ▼          ▼         │
│   分配内存   可用于绑定   GPU 使用   等待GPU    释放内存   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## 资源视图抽象

```cpp
// 资源视图类型
enum class ViewType {
    ConstantBuffer,      // CBV
    ShaderResource,      // SRV
    UnorderedAccess,     // UAV
    RenderTarget,        // RTV
    DepthStencil,        // DSV
    Sampler,             // Sampler
};

// Buffer 视图描述
struct BufferViewDesc {
    RHIBuffer* buffer;
    ViewType type;
    Format format;            // 格式（用于类型化缓冲）
    uint64_t offset;          // 偏移
    uint64_t size;            // 大小（0 表示整个缓冲）
    uint32_t stride;          // 结构化缓冲步长
};

// Texture 视图描述
struct TextureViewDesc {
    RHITexture* texture;
    ViewType type;
    Format format;
    uint16_t mipLevel;
    uint16_t mipCount;
    uint16_t arrayLayer;
    uint16_t arraySize;
};
```

## 相关文件

- [abstraction-layers.md](./abstraction-layers.md) - 抽象层设计
- [memory-model.md](./memory-model.md) - 内存模型设计
