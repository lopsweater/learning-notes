---
description: RHI 接口设计命令。设计跨平台渲染硬件接口，生成接口定义文件。
---

# RHI 设计命令

此命令调用 **rhi-architect** agent，设计 RHI 接口层。

## 此命令的功能

1. 分析需求 - 确定需要支持的功能
2. 设计接口 - 定义抽象接口
3. 映射后端 - 确认 D3D12/Vulkan 映射
4. 生成文档 - 接口设计文档
5. 生成代码 - 接口定义文件

## 设计流程

### 1. 需求分析

确认需要支持的功能：

| 功能类别 | 具体功能 |
|----------|----------|
| 资源创建 | Buffer、Texture、Sampler |
| 描述符管理 | Descriptor Heap、Descriptor Set |
| 命令提交 | Command List、Command Queue |
| 同步 | Fence、Semaphore |
| Swapchain | 交换链、呈现 |

### 2. 接口设计原则

- **最小抽象** - 只抽象必要的差异
- **零开销** - 避免不必要的虚函数调用
- **显式管理** - 资源生命周期由用户控制
- **状态透明** - 不隐藏底层状态

### 3. 后端映射验证

确保接口能正确映射到各后端：

| RHI 接口 | D3D12 | Vulkan | Metal |
|----------|-------|--------|-------|
| RHIDevice | ID3D12Device | VkDevice | MTLDevice |
| RHICommandList | ID3D12GraphicsCommandList | VkCommandBuffer | MTLCommandBuffer |
| RHIBuffer | ID3D12Resource | VkBuffer | MTLBuffer |
| RHITexture | ID3D12Resource | VkImage | MTLTexture |

## 示例会话

用户: /rhi-design 我需要设计一个支持 D3D12 和 Vulkan 的 Buffer 管理接口

Agent:
# RHI Buffer 接口设计

## 需求分析

- 支持平台：Windows (D3D12)、Linux (Vulkan)
- Buffer 类型：Vertex、Index、Constant、Storage
- 内存类型：Device Local、Upload、Readback

## 接口定义

```cpp
// include/rhi/buffer.hpp
#pragma once

#include <cstddef>
#include <cstdint>

namespace rhi {

// Buffer 用途标志
enum class BufferUsage : uint32_t {
    None            = 0,
    VertexBuffer    = 1 << 0,
    IndexBuffer     = 1 << 1,
    ConstantBuffer  = 1 << 2,
    ShaderResource  = 1 << 3,
    UnorderedAccess = 1 << 4,
    TransferSrc     = 1 << 5,
    TransferDst     = 1 << 6,
};

// 内存类型
enum class MemoryType {
    DeviceLocal,    // GPU 专用内存
    Upload,         // CPU 可写，GPU 可读
    Readback,       // GPU 可写，CPU 可读
};

// Buffer 描述
struct BufferDesc {
    size_t size;                // 大小（字节）
    size_t alignment;           // 对齐要求
    BufferUsage usage;          // 用途标志
    MemoryType memoryType;      // 内存类型
    const char* debugName;      // 调试名称
};

// Buffer 接口
class RHIBuffer {
public:
    virtual ~RHIBuffer() = default;
    
    // 获取描述
    virtual const BufferDesc& GetDesc() const = 0;
    
    // 获取 GPU 地址
    virtual uint64_t GetGPUAddress() const = 0;
    
    // 映射内存（仅 Upload/Readback 类型）
    virtual void* Map() = 0;
    virtual void Unmap() = 0;
};

// Buffer 创建接口（设备接口的一部分）
class RHIDevice {
public:
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual void DestroyBuffer(RHIBuffer* buffer) = 0;
};

} // namespace rhi
```

## 后端映射

### D3D12 实现

| RHI 类型 | D3D12 类型 | 映射说明 |
|----------|-----------|----------|
| BufferUsage::VertexBuffer | D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER | 状态映射 |
| BufferUsage::ConstantBuffer | D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER | 状态映射 |
| MemoryType::Upload | D3D12_HEAP_TYPE_UPLOAD | 堆类型映射 |
| GetGPUAddress() | GetGPUVirtualAddress() | 地址获取 |

### Vulkan 实现

| RHI 类型 | Vulkan 类型 | 映射说明 |
|----------|------------|----------|
| BufferUsage::VertexBuffer | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | 用途标志 |
| BufferUsage::ConstantBuffer | VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT | 用途标志 |
| MemoryType::Upload | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | 内存属性 |

## 辅助函数

```cpp
// include/rhi/buffer_utils.hpp
namespace rhi {

// 计算对齐大小
inline size_t AlignSize(size_t size, size_t alignment) {
    return (size + alignment - 1) & ~(alignment - 1);
}

// Buffer 用途标志操作
inline BufferUsage operator|(BufferUsage a, BufferUsage b) {
    return static_cast<BufferUsage>(
        static_cast<uint32_t>(a) | static_cast<uint32_t>(b)
    );
}

inline bool HasFlag(BufferUsage usage, BufferUsage flag) {
    return (static_cast<uint32_t>(usage) & static_cast<uint32_t>(flag)) != 0;
}

// 常量缓冲区对齐（D3D12 要求 256 字节）
inline size_t AlignConstantBuffer(size_t size) {
    return AlignSize(size, 256);
}

} // namespace rhi
```

## 设计检查清单

- [x] 接口足够抽象（支持 D3D12/Vulkan）
- [x] 避免不必要的虚函数调用
- [x] 资源生命周期显式
- [x] 错误处理完善
- [x] 调试信息支持

## 生成的文件

```
include/rhi/
├── buffer.hpp           # Buffer 接口定义
├── buffer_utils.hpp     # Buffer 辅助函数
└── buffer_desc.hpp      # Buffer 描述结构
```

## 后续步骤

1. 实现 D3D12 后端：`/rhi-implement d3d12 buffer`
2. 实现 Vulkan 后端：`/rhi-implement vulkan buffer`
3. 编写单元测试：`/engine-gpu-test`

## 相关命令

- `/rhi-implement` - 实现具体后端
- `/rhi-debug` - 调试 RHI 问题
- `/engine-gpu-test` - GPU 侧测试

## 相关 Skills

- `skills/rhi-patterns/` - RHI 设计模式
- `skills/rhi-d3d12/` - D3D12 后端实现
- `skills/rhi-vulkan/` - Vulkan 后端实现
