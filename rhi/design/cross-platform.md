# RHI 跨平台策略

## 跨平台挑战

### API 差异矩阵

| 特性 | D3D12 | Vulkan | Metal |
|------|-------|--------|-------|
| **平台** | Windows | Windows/Linux/Android/Mac | macOS/iOS |
| **绑定模型** | Root Signature | Descriptor Set | Argument Buffer |
| **描述符** | Descriptor Heap | Descriptor Pool | Heap + Argument Buffer |
| **命令缓冲** | Command List | Command Buffer | Command Buffer |
| **同步** | Fence | Fence + Semaphore | Fence |
| **着色器** | HLSL | SPIR-V | MSL |
| **资源状态** | Resource Barrier | Image Layout | Hazard Tracking |

## 跨平台设计策略

### 策略 1: 最小公共接口

```cpp
// 只暴露所有平台都支持的功能
class RHIDevice {
public:
    // ✅ 所有平台都支持
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
    
    // ❌ 平台特定功能，不放入接口
    // D3D12: ExecuteIndirect, Vulkan: Subpass, Metal: Tile Shaders
};
```

**优点：** 简单、一致
**缺点：** 无法利用平台特性

### 策略 2: 特性检测 + 回退机制

```cpp
class RHIDevice {
public:
    // 特性查询
    virtual bool IsFeatureSupported(Feature feature) = 0;
    
    // 可选功能
    virtual Result ExecuteIndirect(...) {
        if (!IsFeatureSupported(Feature::IndirectDraw)) {
            return Result::NotSupported;
        }
        // ...
    }
};
```

**优点：** 灵活，支持平台特性
**缺点：** 增加复杂度

### 策略 3: 平台扩展接口

```cpp
// 核心接口
class RHIDevice { ... };

// D3D12 扩展
class RHIDeviceD3D12 : public RHIDevice {
public:
    ID3D12Device* GetD3D12Device() { return m_device.Get(); }
    
    // D3D12 特有功能
    void ExecuteIndirect(...);
    void SetResidencyPriority(...);
};

// Vulkan 扩展
class RHIDeviceVulkan : public RHIDevice {
public:
    VkDevice GetVkDevice() { return m_device; }
    
    // Vulkan 特有功能
    void BeginRenderPass(...);
    void NextSubpass(...);
};
```

**优点：** 完全控制，性能最优
**缺点：** 需要平台特定代码路径

## 推荐方案：混合策略

```
┌─────────────────────────────────────────────────────┐
│                    应用层代码                        │
│   使用 RHIDevice 核心接口                           │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                   RHI 核心层                         │
│   - 特性检测: IsFeatureSupported()                  │
│   - 回退机制: 自动回退或报错                         │
└───────────────────────┬─────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ D3D12   │    │ Vulkan  │    │  Metal  │
   │ 扩展    │    │ 扩展    │    │ 扩展    │
   └─────────┘    └─────────┘    └─────────┘
        │               │               │
        ▼               ▼               ▼
   平台特定代码     平台特定代码     平台特定代码
```

## 特性检测机制

### 1. 特性枚举

```cpp
enum class Feature {
    // 资源特性
    BufferStructured,       // Structured Buffer
    BufferRaw,              // Raw Buffer (Byte Address Buffer)
    Texture1DArray,         // 1D Texture Array
    
    // 光栅化特性
    ConservativeRaster,     // 保守光栅化
    DepthBoundsTest,        // 深度边界测试
    
    // 计算特性
    ComputeShader,          // 计算着色器
    IndirectDraw,           // 间接绘制
    
    // 高级特性
    RayTracing,             // 光线追踪
    MeshShader,             // 网格着色器
    VariableRateShading,    // 可变速率着色
};
```

### 2. 特性检测实现

```cpp
// D3D12 实现
class RHIDeviceD3D12 : public RHIDevice {
    D3D12_FEATURE_DATA_D3D12_OPTIONS m_options;
    
public:
    bool IsFeatureSupported(Feature feature) override {
        switch (feature) {
            case Feature::ConservativeRaster:
                return m_options.ConservativeRasterizationTier != D3D12_CONSERVATIVE_RASTERIZATION_TIER_NOT_SUPPORTED;
            
            case Feature::RayTracing:
                return m_options.RaytracingTier >= D3D12_RAYTRACING_TIER_1_0;
            
            // ...
        }
    }
};

// Vulkan 实现
class RHIDeviceVulkan : public RHIDevice {
    VkPhysicalDeviceFeatures m_features;
    VkPhysicalDeviceVulkan12Features m_features12;
    
public:
    bool IsFeatureSupported(Feature feature) override {
        switch (feature) {
            case Feature::ConservativeRaster:
                return m_features.conservativeRasterization;
            
            case Feature::RayTracing:
                return m_features12.rayTracingPipeline;
            
            // ...
        }
    }
};
```

## 回退机制

### 1. 自动回退

```cpp
Result CreateTexture(const TextureDesc& desc) {
    if (!IsFeatureSupported(Feature::TextureCompressionBC)) {
        // 自动回退到无压缩格式
        TextureDesc fallbackDesc = desc;
        fallbackDesc.format = GetUncompressedFormat(desc.format);
        return CreateTextureInternal(fallbackDesc);
    }
    return CreateTextureInternal(desc);
}
```

### 2. 功能模拟

```cpp
void DispatchIndirect(RHIBuffer* buffer, uint64_t offset) {
    if (!IsFeatureSupported(Feature::IndirectDispatch)) {
        // 读取 buffer，使用普通 Dispatch 模拟
        IndirectCommand* cmd = buffer->Map<IndirectCommand>();
        Dispatch(cmd->threadGroupCountX, cmd->threadGroupCountY, cmd->threadGroupCountZ);
        buffer->Unmap();
        return;
    }
    DispatchIndirectInternal(buffer, offset);
}
```

## 平台适配层

### 编译时适配

```cpp
#if RHI_BACKEND_D3D12
    using DeviceImpl = RHIDeviceD3D12;
#elif RHI_BACKEND_VULKAN
    using DeviceImpl = RHIDeviceVulkan;
#elif RHI_BACKEND_METAL
    using DeviceImpl = RHIDeviceMetal;
#endif

std::unique_ptr<RHIDevice> CreateDevice() {
    return std::make_unique<DeviceImpl>();
}
```

### 运行时适配

```cpp
std::unique_ptr<RHIDevice> CreateDevice(RenderAPI api) {
    switch (api) {
        case RenderAPI::D3D12:
            return std::make_unique<RHIDeviceD3D12>();
        case RenderAPI::Vulkan:
            return std::make_unique<RHIDeviceVulkan>();
        case RenderAPI::Metal:
            return std::make_unique<RHIDeviceMetal>();
        default:
            return nullptr;
    }
}
```

## 最佳实践

### ✅ 推荐

1. **优先使用核心接口** - 保证跨平台兼容
2. **功能检测 + 回退** - 渐进增强体验
3. **平台扩展隔离** - 使用 `#ifdef` 或虚函数扩展
4. **统一错误处理** - 平台差异转换为统一错误码

### ❌ 避免

1. **硬编码平台行为** - 破坏跨平台性
2. **忽略特性检测** - 导致运行时崩溃
3. **过度抽象** - 增加性能开销
4. **重复实现** - 维护困难

## 相关文件

- [abstraction-layers.md](./abstraction-layers.md) - 抽象层设计
- [resource-model.md](./resource-model.md) - 资源模型设计
- [../backends/comparison.md](../backends/comparison.md) - API 详细对比
