# Unreal Engine 5 RHI 抽象层架构分析

## 架构总览

```
┌─────────────────────────────────────────────────────────────────┐
│                        渲染器上层                                │
│         (FSceneRenderer, FRenderResource, etc.)                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     RHI 抽象层                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │FRHICommandList│  │FRHIResource  │  │   FDynamicRHI        │   │
│  │  命令队列系统  │  │  资源基类    │  │   动态RHI接口        │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   平台 RHI 实现                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────────────┐   │
│  │ D3D12   │  │ Vulkan  │  │  Metal  │  │ OpenGL/Null      │   │
│  └─────────┘  └─────────┘  └─────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 一、核心接口分析

### 1.1 FRHIResource - 资源基类

**文件位置**: `Engine/Source/Runtime/RHI/Public/RHIResources.h`

```cpp
class RHI_API FRHIResource
{
public:
    // 原子引用计数：30位计数 + 2位状态标志
    std::atomic<uint32> RefCount;
    
    // 生命周期管理
    void AddRef() { RefCount.fetch_add(1 << RefCountShift); }
    void Release() 
    {
        if ((RefCount.fetch_sub(1 << RefCountShift) & RefCountMask) == 1)
        {
            // 加入删除队列
        }
    }
    
protected:
    // 保护析构函数 - 防止直接 delete
    virtual ~FRHIResource();
    
    // 生命周期扩展标志
    bool bAllowExtendLifetime = false;
};
```

**设计亮点**:
- **原子引用计数**: 使用单个原子变量存储引用计数和状态标志，30位用于计数，2位用于删除/销毁状态
- **保护析构函数**: 防止直接 delete，必须通过删除队列销毁
- **生命周期扩展**: `bAllowExtendLifetime` 允许缓存暂时延长资源寿命

**关键派生类**:
- `FRHITexture` - 纹理资源
- `FRHIBuffer` - 缓冲区资源
- `FRHIShader` - 着色器资源
- `FRHIPipelineState` - 管线状态对象
- `FRHIRenderPassInfo` - 渲染通道信息

---

### 1.2 FRHICommandList - 命令队列系统

**文件位置**: `Engine/Source/Runtime/RHI/Public/RHICommandList.h`

```cpp
class FRHICommandListBase
{
public:
    // 命令分配器
    FRHICommandAllocator* CommandAllocator;
    
    // 命令链表头
    FRHICommandBase* Root;
    
    // 管线类型
    ERHIPipeline Pipeline;
    
    // 添加命令
    template<typename TCmd>
    void EnqueueCommand(TCmd&& Cmd)
    {
        // 分配并链接命令
    }
};

class FRHICommandList : public FRHICommandListBase
{
public:
    // 图形命令
    void DrawPrimitive(uint32 BaseVertexIndex, uint32 NumPrimitives, uint32 NumInstances);
    void DrawIndexedPrimitive(FRHIIndexBuffer* IndexBuffer, ...);
    void DispatchComputeShader(uint32 ThreadGroupCountX, ...);
    
    // 资源转换
    void TransitionResourceArray(FRHITransitionInfo* Transitions, int32 NumTransitions);
    
    // 渲染通道
    void BeginRenderPass(const FRHIRenderPassInfo& Info, const TCHAR* Name);
    void EndRenderPass();
};
```

**命令模式实现**:

```cpp
// 命令基类
struct FRHICommandBase
{
    FRHICommandBase* Next = nullptr;
    virtual void ExecuteAndDestruct(FRHICommandListBase& CmdList) = 0;
};

// Lambda 命令模板
template<typename Lambda>
struct TRHILambdaCommand : FRHICommandBase
{
    Lambda TheLambda;
    
    virtual void ExecuteAndDestruct(FRHICommandListBase& CmdList) override
    {
        TheLambda(CmdList);
        delete this;
    }
};
```

**关键特性**:
- **命令模式**: 所有渲染命令封装为 `FRHICommandBase` 对象
- **Lambda 命令**: `TRHILambdaCommand` 模板支持任意可调用对象
- **管线分离**: `ERHIPipeline::Graphics` 和 `ERHIPipeline::AsyncCompute`
- **并行翻译**: 支持多线程命令翻译执行

---

### 1.3 FRHITexture - 纹理资源

**文件位置**: `Engine/Source/Runtime/RHI/Public/RHIResources.h`

```cpp
class FRHITexture : public FRHIResource
{
public:
    // 纹理描述
    FRHITextureDesc Desc;
    
    // 获取信息
    virtual uint32 GetSizeX() const = 0;
    virtual uint32 GetSizeY() const = 0;
    virtual uint32 GetSizeZ() const = 0;
    virtual EPixelFormat GetFormat() const = 0;
    
    // 子资源访问
    virtual uint32 GetNumMips() const = 0;
    virtual uint32 GetNumArraySlices() const = 0;
};

struct FRHITextureDesc
{
    ETextureDimension Dimension;      // 1D/2D/3D/Cube
    EPixelFormat Format;              // 像素格式
    uint32 SizeX, SizeY, SizeZ;       // 尺寸
    uint32 ArraySize;                 // 数组大小
    uint32 NumMips;                   // Mip 级别数
    ETextureCreateFlags Flags;        // 创建标志
};
```

---

## 二、资源状态转换系统

### 2.1 FRHITransitionInfo

**文件位置**: `Engine/Source/Runtime/RHI/Public/RHIResources.h`

```cpp
struct FRHITransitionInfo
{
    FRHIResource* Resource;          // 资源指针
    ERHIAccess AccessBefore;         // 转换前状态
    ERHIAccess AccessAfter;          // 转换后状态
    uint32 ArraySlice;               // 数组切片
    uint32 PlaneSlice;               // 平面切片
    uint32 NumMips;                  // Mip 数量
};
```

### 2.2 ERHIAccess - 资源访问状态

```cpp
enum class ERHIAccess : uint32
{
    Unknown                = 0,
    
    // CPU 访问
    CPURead                = 1 << 0,
    CPUWrite               = 1 << 1,
    
    // GPU 读取
    VertexBuffer           = 1 << 2,
    IndexBuffer            = 1 << 3,
    UniformBuffer          = 1 << 4,
    IndirectArgs           = 1 << 5,
    ShaderResource         = 1 << 6,
    
    // GPU 写入
    UnorderedAccess        = 1 << 7,
    RenderTarget           = 1 << 8,
    DepthStencil           = 1 << 9,
    ShadingRateSource      = 1 << 10,
    
    // 拷贝
    CopySrc                = 1 << 11,
    CopyDest               = 1 << 12,
    ResolveSrc             = 1 << 13,
    ResolveDest            = 1 << 14,
    
    // 光线追踪
    RayTracingAccelerationStructure = 1 << 15,
    RayTracingShaderResource        = 1 << 16,
    
    // Present
    Present                = 1 << 17,
};
```

**使用示例**:

```cpp
// 纹理从着色器资源转换为渲染目标
FRHITransitionInfo Transition(
    MyTexture,
    ERHIAccess::ShaderResource,
    ERHIAccess::RenderTarget
);
RHICmdList.TransitionResource(Transition);

// 渲染完成后转回
FRHITransitionInfo ReverseTransition(
    MyTexture,
    ERHIAccess::RenderTarget,
    ERHIAccess::ShaderResource
);
RHICmdList.TransitionResource(ReverseTransition);
```

---

## 三、平台抽象层

### 3.1 FDynamicRHI - 动态 RHI 接口

**文件位置**: `Engine/Source/Runtime/RHI/Public/DynamicRHI.h`

```cpp
class FDynamicRHI
{
public:
    // 初始化和清理
    virtual void Init() = 0;
    virtual void Shutdown() = 0;
    
    // 资源创建
    virtual FRHITexture* RHICreateTexture(const FRHITextureDesc&) = 0;
    virtual FRHIBuffer* RHICreateBuffer(const FRHIBufferDesc&) = 0;
    virtual FRHIPipelineState* RHICreatePipelineState(const FGraphicsPipelineStateInitializer&) = 0;
    
    // 命令上下文
    virtual FRHICommandContext* RHIGetDefaultContext() = 0;
    virtual FRHIComputeContext* RHIGetDefaultAsyncComputeContext() = 0;
    
    // 平台信息
    virtual const TCHAR* GetNameString() = 0;
    virtual bool IsRayTracingSupported() = 0;
};
```

### 3.2 平台实现架构

```
                    ┌─────────────────┐
                    │   FDynamicRHI   │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ FD3D12DynamicRHI│    │FVulkanDynamicRHI│    │FMetalDynamicRHI│
│   (Windows)    │    │ (Cross-platform)│    │   (macOS/iOS) │
└───────────────┘    └───────────────┘    └───────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ DirectX 12    │    │ Vulkan        │    │ Metal         │
│ API Calls     │    │ API Calls     │    │ API Calls     │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## 四、执行上下文接口

### 4.1 IRHIComputeContext

**文件位置**: `Engine/Source/Runtime/RHI/Public/RHIContext.h`

```cpp
class IRHIComputeContext
{
public:
    // 计算 Shader 分发
    virtual void RHIDispatchComputeShader(uint32 ThreadGroupCountX, ...) = 0;
    virtual void RHIDispatchIndirect(FRHIBuffer* ArgumentBuffer, ...) = 0;
    
    // UAV 操作
    virtual void RHIClearUAV(FRHIUnorderedAccessView* UAV, ...) = 0;
    virtual void RHICopyBufferRegion(FRHIBuffer* DestBuffer, ...) = 0;
    
    // 资源转换
    virtual void RHITransitionResources(FRHITransitionInfo* Transitions, int32 Num) = 0;
};

class IRHICommandContext : public IRHIComputeContext
{
public:
    // 绘制调用
    virtual void RHIDrawPrimitive(uint32 BaseVertexIndex, ...) = 0;
    virtual void RHIDrawIndexedPrimitive(FRHIIndexBuffer* IndexBuffer, ...) = 0;
    virtual void RHIDrawPrimitiveIndirect(FRHIVertexBuffer* ArgumentBuffer, ...) = 0;
    
    // 渲染状态
    virtual void RHISetRenderTargets(uint32 NumRTs, FRHIRenderTargetView* RTs, ...) = 0;
    virtual void RHISetViewport(float MinX, float MinY, ...) = 0;
    virtual void RHISetScissorRect(bool bEnable, uint32 MinX, ...) = 0;
    
    // 绑定资源
    virtual void RHISetShaderTexture(FRHIPixelShader* Shader, uint32 Slot, FRHITexture* Texture) = 0;
    virtual void RHISetShaderUniformBuffer(FRHIComputeShader* Shader, uint32 Slot, FRHIUniformBuffer* Buffer) = 0;
};
```

---

## 五、设计模式总结

### 5.1 使用的设计模式

| 模式 | 应用场景 | 说明 |
|------|----------|------|
| **命令模式** | FRHICommandList | 将渲染操作封装为命令对象 |
| **桥接模式** | FDynamicRHI | 分离抽象与实现 |
| **工厂模式** | RHICreate* | 统一资源创建接口 |
| **模板方法** | FRHIResource | 定义资源生命周期骨架 |
| **策略模式** | 平台 RHI | 不同平台不同实现策略 |

### 5.2 关键设计原则

1. **抽象隔离**: 上层渲染器不直接调用平台 API，通过 RHI 抽象层
2. **延迟执行**: 命令先录制，后执行，支持多线程
3. **资源生命周期**: 引用计数 + 延迟删除队列
4. **状态转换**: 显式声明资源状态转换，避免隐式屏障

---

## 六、与 Decima 引擎对比

| 特性 | Unreal Engine 5 | Decima Engine |
|------|-----------------|---------------|
| RHI 抽象 | FDynamicRHI | 平台抽象层 |
| 命令系统 | FRHICommandList | 自研命令系统 |
| 资源管理 | 引用计数 + 延迟删除 | 类似机制 |
| 多线程 | 命令录制并行 | Job System |
| 目标平台 | 全平台 | PlayStation + PC |

---

## 七、关键文件索引

```
Engine/Source/Runtime/RHI/
├── Public/
│   ├── RHI.h                    - RHI 核心定义
│   ├── RHIResources.h           - 资源基类
│   ├── RHICommandList.h         - 命令队列
│   ├── RHIContext.h             - 执行上下文
│   └── DynamicRHI.h             - 动态接口
└── Private/
    ├── RHI.cpp                  - RHI 实现
    └── RHICommandList.cpp       - 命令系统实现
```

---

*分析完成于 2026-03-20*
