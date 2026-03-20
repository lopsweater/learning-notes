---
description: RHI 后端实现命令。实现具体的 D3D12/Vulkan 后端代码。
---

# RHI 实现命令

此命令调用 **rhi-implementer** agent，实现具体的图形 API 后端。

## 此命令的功能

1. 读取接口定义 - 理解 RHI 接口
2. 实现后端代码 - D3D12/Vulkan 实现
3. 处理平台差异 - 条件编译
4. 编写测试代码 - 验证实现正确性
5. 生成文档 - 实现说明

## 支持的后端

| 后端 | 平台 | 图形 API |
|------|------|----------|
| d3d12 | Windows | DirectX 12 |
| vulkan | Windows/Linux | Vulkan |

## 示例会话

用户: /rhi-implement d3d12 buffer

Agent:
# D3D12 Buffer 实现

## 实现文件结构

```
src/rhi/d3d12/
├── d3d12_device.cpp       # 设备实现
├── d3d12_buffer.cpp       # Buffer 实现
├── d3d12_buffer.hpp       # Buffer 内部定义
└── d3d12_utils.hpp        # D3D12 工具函数
```

## Buffer 实现

```cpp
// src/rhi/d3d12/d3d12_buffer.hpp
#pragma once

#include "rhi/buffer.hpp"
#include <d3d12.h>
#include <wrl/client.h>

using Microsoft::WRL::ComPtr;

namespace rhi {
namespace d3d12 {

class D3D12Buffer : public RHIBuffer {
public:
    D3D12Buffer(ComPtr<ID3D12Resource> resource, const BufferDesc& desc);
    ~D3D12Buffer() override;
    
    const BufferDesc& GetDesc() const override { return desc_; }
    uint64_t GetGPUAddress() const override;
    void* Map() override;
    void Unmap() override;
    
    ID3D12Resource* GetResource() const { return resource_.Get(); }
    
private:
    ComPtr<ID3D12Resource> resource_;
    BufferDesc desc_;
    void* mappedPtr_ = nullptr;
};

} // namespace d3d12
} // namespace rhi
```

```cpp
// src/rhi/d3d12/d3d12_buffer.cpp
#include "d3d12_buffer.hpp"
#include "d3d12_utils.hpp"

namespace rhi {
namespace d3d12 {

D3D12Buffer::D3D12Buffer(ComPtr<ID3D12Resource> resource, const BufferDesc& desc)
    : resource_(resource), desc_(desc) {
}

D3D12Buffer::~D3D12Buffer() {
    if (mappedPtr_) {
        resource_->Unmap(0, nullptr);
        mappedPtr_ = nullptr;
    }
}

uint64_t D3D12Buffer::GetGPUAddress() const {
    return resource_->GetGPUVirtualAddress();
}

void* D3D12Buffer::Map() {
    if (mappedPtr_) {
        return mappedPtr_;
    }
    
    D3D12_RANGE range = {0, desc_.size};
    HRESULT hr = resource_->Map(0, &range, &mappedPtr_);
    if (FAILED(hr)) {
        return nullptr;
    }
    
    return mappedPtr_;
}

void D3D12Buffer::Unmap() {
    if (mappedPtr_) {
        resource_->Unmap(0, nullptr);
        mappedPtr_ = nullptr;
    }
}

} // namespace d3d12
} // namespace rhi
```

## 设备实现（Buffer 创建部分）

```cpp
// src/rhi/d3d12/d3d12_device.cpp
#include "d3d12_device.hpp"
#include "d3d12_buffer.hpp"

namespace rhi {
namespace d3d12 {

RHIBuffer* D3D12Device::CreateBuffer(const BufferDesc& desc) {
    // 1. 转换堆属性
    D3D12_HEAP_PROPERTIES heapProps = {};
    heapProps.Type = ConvertHeapType(desc.memoryType);
    heapProps.CreationNodeMask = 1;
    heapProps.VisibleNodeMask = 1;
    
    // 2. 转换资源描述
    D3D12_RESOURCE_DESC resourceDesc = {};
    resourceDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    resourceDesc.Alignment = desc.alignment;
    resourceDesc.Width = AlignUp(desc.size, desc.alignment);
    resourceDesc.Height = 1;
    resourceDesc.DepthOrArraySize = 1;
    resourceDesc.MipLevels = 1;
    resourceDesc.Format = DXGI_FORMAT_UNKNOWN;
    resourceDesc.SampleDesc.Count = 1;
    resourceDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    resourceDesc.Flags = ConvertBufferFlags(desc.usage);
    
    // 3. 确定初始状态
    D3D12_RESOURCE_STATES initialState = D3D12_RESOURCE_STATE_COMMON;
    if (desc.memoryType == MemoryType::Upload) {
        initialState = D3D12_RESOURCE_STATE_GENERIC_READ;
    } else if (desc.memoryType == MemoryType::Readback) {
        initialState = D3D12_RESOURCE_STATE_COPY_DEST;
    }
    
    // 4. 创建资源
    ComPtr<ID3D12Resource> resource;
    HRESULT hr = device_->CreateCommittedResource(
        &heapProps,
        D3D12_HEAP_FLAG_NONE,
        &resourceDesc,
        initialState,
        nullptr,
        IID_PPV_ARGS(&resource)
    );
    
    if (FAILED(hr)) {
        return nullptr;
    }
    
    // 5. 设置调试名称
    if (desc.debugName) {
        auto wname = ToWideString(desc.debugName);
        resource->SetName(wname.c_str());
    }
    
    return new D3D12Buffer(resource, desc);
}

void D3D12Device::DestroyBuffer(RHIBuffer* buffer) {
    delete buffer;
}

} // namespace d3d12
} // namespace rhi
```

## 工具函数

```cpp
// src/rhi/d3d12/d3d12_utils.hpp
#pragma once

#include "rhi/buffer.hpp"
#include <d3d12.h>
#include <string>

namespace rhi {
namespace d3d12 {

// 内存类型转换
inline D3D12_HEAP_TYPE ConvertHeapType(MemoryType type) {
    switch (type) {
        case MemoryType::DeviceLocal: return D3D12_HEAP_TYPE_DEFAULT;
        case MemoryType::Upload:      return D3D12_HEAP_TYPE_UPLOAD;
        case MemoryType::Readback:    return D3D12_HEAP_TYPE_READBACK;
    }
    return D3D12_HEAP_TYPE_DEFAULT;
}

// Buffer 用途转换
inline D3D12_RESOURCE_FLAGS ConvertBufferFlags(BufferUsage usage) {
    D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE;
    
    if (HasFlag(usage, BufferUsage::UnorderedAccess)) {
        flags |= D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    }
    
    return flags;
}

// 字符串转换
inline std::wstring ToWideString(const char* str) {
    if (!str) return L"";
    size_t len = strlen(str);
    std::wstring result(len, 0);
    MultiByteToWideChar(CP_UTF8, 0, str, -1, &result[0], len + 1);
    return result;
}

// 对齐计算
inline size_t AlignUp(size_t size, size_t alignment) {
    return (size + alignment - 1) & ~(alignment - 1);
}

} // namespace d3d12
} // namespace rhi
```

## CMake 配置

```cmake
# src/rhi/d3d12/CMakeLists.txt
target_sources(EngineRHI PRIVATE
    d3d12_device.cpp
    d3d12_buffer.cpp
    d3d12_texture.cpp
    d3d12_command_list.cpp
)

target_link_libraries(EngineRHI PRIVATE
    d3d12
    dxgi
)
```

## 单元测试

```cpp
// tests/rhi/d3d12/buffer_test.cpp
#include <gtest/gtest.h>
#include "rhi/d3d12/d3d12_device.hpp"

TEST(D3D12Buffer, 创建VertexBuffer) {
    D3D12Device device;
    ASSERT_TRUE(device.Initialize());
    
    BufferDesc desc = {};
    desc.size = 1024;
    desc.alignment = 16;
    desc.usage = BufferUsage::VertexBuffer;
    desc.memoryType = MemoryType::DeviceLocal;
    desc.debugName = "TestVertexBuffer";
    
    RHIBuffer* buffer = device.CreateBuffer(desc);
    ASSERT_NE(buffer, nullptr);
    EXPECT_EQ(buffer->GetDesc().size, 1024);
    EXPECT_NE(buffer->GetGPUAddress(), 0);
    
    device.DestroyBuffer(buffer);
}

TEST(D3D12Buffer, 映射上传Buffer) {
    D3D12Device device;
    ASSERT_TRUE(device.Initialize());
    
    BufferDesc desc = {};
    desc.size = 256;
    desc.alignment = 256;
    desc.usage = BufferUsage::ConstantBuffer;
    desc.memoryType = MemoryType::Upload;
    desc.debugName = "TestConstantBuffer";
    
    RHIBuffer* buffer = device.CreateBuffer(desc);
    ASSERT_NE(buffer, nullptr);
    
    void* ptr = buffer->Map();
    ASSERT_NE(ptr, nullptr);
    
    // 写入数据
    memset(ptr, 0xAB, 256);
    
    buffer->Unmap();
    device.DestroyBuffer(buffer);
}
```

## 实现检查清单

- [x] 资源创建正确
- [x] 内存分配正确
- [x] GPU 地址获取正确
- [x] 映射/取消映射正确
- [x] 调试名称设置
- [x] 资源销毁正确
- [x] 单元测试通过

## 相关命令

- `/rhi-design` - 设计 RHI 接口
- `/rhi-debug` - 调试 RHI 问题
- `/engine-gpu-test` - 运行 GPU 测试

## 相关 Skills

- `skills/rhi-d3d12/` - D3D12 后端实现详解
- `skills/rhi-vulkan/` - Vulkan 后端实现详解
