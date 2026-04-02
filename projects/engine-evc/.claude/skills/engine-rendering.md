---
name: engine-rendering
description: 渲染系统开发 - RHI、材质系统、后处理、GPU 编程等图形渲染知识
globs:
  - "**/render/**"
  - "**/rhi/**"
  - "*.shader"
  - "*.hlsl"
  - "*.glsl"
---

# Engine Rendering

> **渲染是游戏引擎的核心子系统，此技能提供渲染系统开发的专业知识**

## 作用

提供游戏引擎渲染系统开发知识，包括 RHI（渲染硬件接口）、材质系统、后处理、GPU 编程等。

## 触发时机

- 开发渲染相关代码时
- 用户提及渲染、材质、着色器、RHI 等关键词时
- 分析渲染性能问题时

## 核心概念

### 一、RHI（渲染硬件接口）

#### 1. RHI 架构图

```
┌────────────────────────────────────────────────────────┐
│                  渲染系统架构                           │
└────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Game Thread                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Scene Graph  │  │  Materials   │  │   Lighting   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────┘
                         │ Render Commands
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Render Thread                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Command Buf  │  │  State Cache │  │   Culling    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────┘
                         │ RHI Commands
                         ▼
┌─────────────────────────────────────────────────────────┐
│                      RHI Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐│
│  │  DX12    │  │  Vulkan  │  │  Metal   │  │ OpenGL  ││
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘│
└────────────────────────┬────────────────────────────────┘
                         │ GPU Commands
                         ▼
┌─────────────────────────────────────────────────────────┐
│                       GPU                               │
└─────────────────────────────────────────────────────────┘
```

#### 2. RHI 接口设计

```cpp
// RHI 抽象接口
class IRHI
{
public:
    virtual ~IRHI() = default;
    
    // 设备创建
    virtual std::unique_ptr<RHIDevice> CreateDevice() = 0;
    virtual std::unique_ptr<RHISwapChain> CreateSwapChain(RHIDevice* device, void* window) = 0;
    
    // 资源创建
    virtual std::unique_ptr<RHIBuffer> CreateBuffer(const BufferDesc& desc) = 0;
    virtual std::unique_ptr<RHITexture> CreateTexture(const TextureDesc& desc) = 0;
    virtual std::unique_ptr<RHIPipeline> CreatePipeline(const PipelineDesc& desc) = 0;
    virtual std::unique_ptr<RHIShader> CreateShader(const ShaderDesc& desc) = 0;
    
    // 命令列表
    virtual std::unique_ptr<RHICommandList> CreateCommandList() = 0;
    
    // 同步
    virtual std::unique_ptr<RHIFence> CreateFence() = 0;
    virtual void WaitForFence(RHIFence* fence, uint64_t value) = 0;
};

// 具体实现：DirectX 12
class DX12RHI : public IRHI
{
public:
    std::unique_ptr<RHIDevice> CreateDevice() override
    {
        return std::make_unique<DX12Device>();
    }
    
    std::unique_ptr<RHITexture> CreateTexture(const TextureDesc& desc) override
    {
        return std::make_unique<DX12Texture>(desc);
    }
    
    // ... 其他实现
};

// 具体实现：Vulkan
class VulkanRHI : public IRHI
{
public:
    std::unique_ptr<RHIDevice> CreateDevice() override
    {
        return std::make_unique<VulkanDevice>();
    }
    
    std::unique_ptr<RHITexture> CreateTexture(const TextureDesc& desc) override
    {
        return std::make_unique<VulkanTexture>(desc);
    }
    
    // ... 其他实现
};
```

#### 3. 命令列表设计

```cpp
// 渲染命令列表
class RHICommandList
{
public:
    // 开始/结束
    virtual void Begin() = 0;
    virtual void End() = 0;
    
    // 资源屏障
    virtual void ResourceBarrier(RHITexture* texture, ResourceState before, ResourceState after) = 0;
    
    // 绑定资源
    virtual void SetPipeline(RHIPipeline* pipeline) = 0;
    virtual void SetVertexBuffer(uint32_t slot, RHIBuffer* buffer, uint64_t offset) = 0;
    virtual void SetIndexBuffer(RHIBuffer* buffer, uint64_t offset, IndexFormat format) = 0;
    virtual void SetConstantBuffer(uint32_t slot, RHIBuffer* buffer) = 0;
    virtual void SetTexture(uint32_t slot, RHITexture* texture, RHISampler* sampler) = 0;
    
    // 绘制
    virtual void Draw(uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance) = 0;
    virtual void DrawIndexed(uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance) = 0;
    
    // 计算调度
    virtual void Dispatch(uint32_t x, uint32_t y, uint32_t z) = 0;
    
    // 清除
    virtual void ClearColor(RHITexture* texture, const float color[4]) = 0;
    virtual void ClearDepthStencil(RHITexture* texture, float depth, uint8_t stencil) = 0;
    
    // 复制
    virtual void CopyTexture(RHITexture* dst, RHITexture* src) = 0;
    virtual void CopyBuffer(RHIBuffer* dst, uint64_t dstOffset, RHIBuffer* src, uint64_t srcOffset, uint64_t size) = 0;
};
```

### 二、材质系统

#### 1. 材质架构

```
┌────────────────────────────────────────────────────────┐
│                  材质系统架构                           │
└────────────────────────────────────────────────────────┘

Material Instance
┌──────────────────────────────────────┐
│  Material Instance "Hero_Mat"        │
├──────────────────────────────────────┤
│  Parent: Master_PBR_Material         │
│  Overrides:                          │
│    - BaseColor: hero_texture.png     │
│    - Metallic: 0.8                   │
│    - Roughness: 0.3                  │
│    - Normal: hero_normal.png         │
└──────────────────────────────────────┘
                     │
                     ▼
Material Template
┌──────────────────────────────────────┐
│  Material Template "Master_PBR"      │
├──────────────────────────────────────┤
│  Parameters:                         │
│    - BaseColor (Texture)             │
│    - Metallic (Float)                │
│    - Roughness (Float)               │
│    - Normal (Texture)                │
│  Shaders:                            │
│    - Vertex: PBR_VertexShader        │
│    - Pixel: PBR_PixelShader          │
└──────────────────────────────────────┘
```

#### 2. 材质系统实现

```cpp
// 材质参数
struct MaterialParameter
{
    enum class Type
    {
        Float,
        Float2,
        Float3,
        Float4,
        Texture,
        Buffer
    };
    
    std::string name;
    Type type;
    
    // 值（使用 variant）
    std::variant<
        float,
        Vector2,
        Vector3,
        Vector4,
        TextureHandle,
        BufferHandle
    > value;
    
    // 默认值
    std::variant<
        float,
        Vector2,
        Vector3,
        Vector4,
        std::string,
        std::string
    > defaultValue;
};

// 材质模板
class MaterialTemplate
{
public:
    void AddParameter(const std::string& name, MaterialParameter::Type type, const auto& defaultValue)
    {
        MaterialParameter param;
        param.name = name;
        param.type = type;
        param.defaultValue = defaultValue;
        m_Parameters.push_back(param);
    }
    
    void SetShaders(const std::string& vertexShader, const std::string& pixelShader)
    {
        m_VertexShader = vertexShader;
        m_PixelShader = pixelShader;
    }
    
    std::unique_ptr<MaterialInstance> CreateInstance()
    {
        return std::make_unique<MaterialInstance>(this);
    }
    
private:
    std::string m_Name;
    std::vector<MaterialParameter> m_Parameters;
    std::string m_VertexShader;
    std::string m_PixelShader;
    
    friend class MaterialInstance;
};

// 材质实例
class MaterialInstance
{
public:
    MaterialInstance(MaterialTemplate* template_)
        : m_Template(template_)
    {
        // 复制模板参数
        m_Parameters = template_->m_Parameters;
    }
    
    void SetFloat(const std::string& name, float value)
    {
        auto* param = FindParameter(name);
        if (param && param->type == MaterialParameter::Type::Float)
        {
            param->value = value;
        }
    }
    
    void SetTexture(const std::string& name, TextureHandle texture)
    {
        auto* param = FindParameter(name);
        if (param && param->type == MaterialParameter::Type::Texture)
        {
            param->value = texture;
        }
    }
    
    void Apply(RHICommandList* cmdList)
    {
        // 绑定着色器
        auto* shader = LoadShader(m_Template->m_VertexShader, m_Template->m_PixelShader);
        cmdList->SetPipeline(shader->GetPipeline());
        
        // 绑定参数
        for (const auto& param : m_Parameters)
        {
            if (std::holds_alternative<float>(param.value))
            {
                // 绑定常量缓冲区
            }
            else if (std::holds_alternative<TextureHandle>(param.value))
            {
                // 绑定纹理
                auto texture = std::get<TextureHandle>(param.value);
                cmdList->SetTexture(GetSlot(param.name), texture.texture, texture.sampler);
            }
        }
    }
    
private:
    MaterialParameter* FindParameter(const std::string& name)
    {
        for (auto& param : m_Parameters)
        {
            if (param.name == name)
                return &param;
        }
        return nullptr;
    }
    
    MaterialTemplate* m_Template;
    std::vector<MaterialParameter> m_Parameters;
};
```

### 三、后处理

#### 1. 后处理管线

```
┌────────────────────────────────────────────────────────┐
│                  后处理管线                             │
└────────────────────────────────────────────────────────┘

Scene Render
      │
      ▼
┌──────────────┐
│  HDR Buffer  │
└──────┬───────┘
       │
       ▼
┌──────────────┐     Bloom: 提取亮部
│    Bloom     │ ──────────────────────┐
└──────┬───────┘                       │
       │                               │
       ▼                               ▼
┌──────────────┐                 ┌──────────────┐
│  Tonemapping │                 │   Blur X     │
└──────┬───────┘                 └──────┬───────┘
       │                                │
       │                                ▼
       │                          ┌──────────────┐
       │                          │   Blur Y     │
       │                          └──────┬───────┘
       │                                 │
       └─────────────────────────────────┘
                        │
                        ▼
                  ┌──────────────┐
                  │ Color Grading│
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   FXAA/SMAA  │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   LDR Buffer │
                  └──────────────┘
```

#### 2. 后处理效果实现

```cpp
// 后处理 Pass 基类
class PostProcessPass
{
public:
    virtual ~PostProcessPass() = default;
    virtual void Execute(RHICommandList* cmdList, RHITexture* input, RHITexture* output) = 0;
    virtual const char* GetName() const = 0;
};

// Bloom Pass
class BloomPass : public PostProcessPass
{
public:
    void Execute(RHICommandList* cmdList, RHITexture* input, RHITexture* output) override
    {
        // 1. 提取亮部
        cmdList->SetPipeline(m_BrightnessPipeline);
        cmdList->SetTexture(0, input, m_PointSampler);
        cmdList->SetConstantBuffer(0, m_ThresholdCB);
        cmdList->DrawFullScreenQuad();
        
        // 2. 下采样
        for (int i = 0; i < m_BloomLevels; ++i)
        {
            cmdList->SetPipeline(m_DownsamplePipeline);
            cmdList->SetTexture(0, m_BloomTextures[i], m_LinearSampler);
            cmdList->DrawFullScreenQuad();
        }
        
        // 3. 上采样 + 混合
        for (int i = m_BloomLevels - 1; i >= 0; --i)
        {
            cmdList->SetPipeline(m_UpsamplePipeline);
            cmdList->SetTexture(0, m_BloomTextures[i], m_LinearSampler);
            cmdList->SetConstantBuffer(0, m_BloomParamsCB);
            cmdList->DrawFullScreenQuad();
        }
        
        // 4. 合并到输出
        cmdList->SetPipeline(m_CombinePipeline);
        cmdList->SetTexture(0, input, m_PointSampler);
        cmdList->SetTexture(1, m_BloomResult, m_LinearSampler);
        cmdList->DrawFullScreenQuad();
    }
    
private:
    RHIPipeline* m_BrightnessPipeline;
    RHIPipeline* m_DownsamplePipeline;
    RHIPipeline* m_UpsamplePipeline;
    RHIPipeline* m_CombinePipeline;
    RHITexture* m_BloomTextures[8];
    int m_BloomLevels = 4;
};

// Tonemapping Pass
class TonemappingPass : public PostProcessPass
{
public:
    enum class Algorithm
    {
        Reinhard,
        ACES,
        Filmic,
        Uchimura
    };
    
    void SetAlgorithm(Algorithm algo) { m_Algorithm = algo; }
    
    void Execute(RHICommandList* cmdList, RHITexture* input, RHITexture* output) override
    {
        cmdList->SetPipeline(m_Pipelines[static_cast<int>(m_Algorithm)]);
        cmdList->SetTexture(0, input, m_PointSampler);
        cmdList->SetConstantBuffer(0, m_TonemappingParamsCB);
        cmdList->DrawFullScreenQuad();
    }
    
private:
    Algorithm m_Algorithm = Algorithm::ACES;
    RHIPipeline* m_Pipelines[4];
};
```

### 四、GPU 编程最佳实践

#### 1. 着色器性能优化

```hlsl
// ❌ 不推荐：分支过多
float4 PSMain(VSOutput input) : SV_Target
{
    float4 color;
    
    if (materialFlags & HAS_BASE_COLOR_TEXTURE)
        color = BaseColorTexture.Sample(BaseColorSampler, input.uv);
    else
        color = BaseColor;
    
    if (materialFlags & HAS_NORMAL_TEXTURE)
    {
        float3 normal = NormalTexture.Sample(NormalSampler, input.uv).xyz;
        // ...
    }
    
    // ... 更多分支
    return color;
}

// ✅ 推荐：使用 uniform 常量
float4 PSMain(VSOutput input) : SV_Target
{
    // 编译器会优化掉不使用的代码路径
    float4 color = BaseColor;
    
    [branch]
    if (HAS_BASE_COLOR_TEXTURE)
    {
        color *= BaseColorTexture.Sample(BaseColorSampler, input.uv);
    }
    
    return color;
}

// ✅✅ 推荐：使用 shader 变体
// 编译多个着色器变体，运行时选择
float4 PSMain(VSOutput input) : SV_Target
{
    float4 color = BaseColor;
    
    #if HAS_BASE_COLOR_TEXTURE
    color *= BaseColorTexture.Sample(BaseColorSampler, input.uv);
    #endif
    
    #if HAS_NORMAL_TEXTURE
    float3 normal = UnpackNormal(NormalTexture.Sample(NormalSampler, input.uv));
    color = ApplyNormalMap(color, normal);
    #endif
    
    return color;
}
```

#### 2. 减少带宽

```hlsl
// ❌ 不推荐：读取太多纹理
float4 PSMain(VSOutput input) : SV_Target
{
    float4 diffuse = DiffuseTexture.Sample(DiffuseSampler, input.uv);
    float4 specular = SpecularTexture.Sample(SpecularSampler, input.uv);
    float4 normal = NormalTexture.Sample(NormalSampler, input.uv);
    float4 roughness = RoughnessTexture.Sample(RoughnessSampler, input.uv);
    float4 metallic = MetallicTexture.Sample(MetallicSampler, input.uv);
    float4 ao = AOTexture.Sample(AOSampler, input.uv);
    
    // ... 使用这些值
}

// ✅ 推荐：打包数据
float4 PSMain(VSOutput input) : SV_Target
{
    // ARM 打包：R=AO, G=Roughness, B=Metallic, A=空
    float4 arm = ARMTexture.Sample(ARMSampler, input.uv);
    float ao = arm.r;
    float roughness = arm.g;
    float metallic = arm.b;
    
    float4 diffuse = DiffuseTexture.Sample(DiffuseSampler, input.uv);
    float3 normal = UnpackNormal(NormalTexture.Sample(NormalSampler, input.uv));
    
    // ... 使用这些值
}
```

## 渲染优化技巧

### 1. 减少绘制调用（Draw Call）

- **实例化渲染**：相同网格使用一次绘制调用
- **静态批处理**：静态物体合并为一个网格
- **动态批处理**：小网格动态合并
- **GPU Driven Rendering**：GPU 决定渲染内容

### 2. 减少状态切换

- **排序**：按材质、纹理排序减少状态切换
- **Texture Atlas**：多个小纹理合并为大纹理
- **Bindless Textures**：无绑定纹理（DX12/Vulkan）

### 3. LOD（细节层次）

- **网格 LOD**：距离远时使用简化网格
- **材质 LOD**：距离远时使用简化材质
- **着色器 LOD**：距离远时使用简化着色器

## 相关技能

- **engine-project-context** - 读取渲染模块配置
- **engine-cpp-foundations** - 使用性能优化技巧
- **engine-architecture** - 模块化设计
- **engine-testing** - 渲染测试
