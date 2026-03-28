# DX12 + Vulkan RHI 设计实现调研报告

> 调研时间: 2026-03-23
> 目标: 开发游戏引擎的 RHI，覆盖 DX12 和 Vulkan

---

## 一、核心发现：专门支持 DX12 + Vulkan 的高星项目

### 1.1 推荐度排序

| 项目 | Stars | 语言 | DX12 | Vulkan | 推荐度 | 说明 |
|------|-------|------|------|--------|--------|------|
| **NVIDIA-RTX/NVRHI** | 1,793 | C++ | ✅ | ✅ | ⭐⭐⭐⭐⭐ | NVIDIA 官方，工业级 |
| **NVIDIA-RTX/NRI** | 394 | C++ | ✅ | ✅ | ⭐⭐⭐⭐⭐ | NVIDIA 官方，低开销 |
| **DiligentGraphics/DiligentEngine** | 4,238 | C++ | ✅ | ✅ | ⭐⭐⭐⭐⭐ | 功能最完善，教程齐全 |
| **LukasBanana/LLGL** | 2,550 | C++ | ✅ | ✅ | ⭐⭐⭐⭐ | 轻量级，易上手 |
| **Try/Tempest** | 204 | C++17 | ✅ | ✅ | ⭐⭐⭐⭐ | 现代 C++，头文件优先 |
| **crud89/LiteFX** | 116 | C++23 | ✅ | ✅ | ⭐⭐⭐⭐ | 最新 C++ 标准 |
| **shader-slang/slang-rhi** | 169 | C++ | ✅ | ✅ | ⭐⭐⭐ | Slang shader 集成 |
| **Ipotrick/Daxa** | 526 | C++ | ❌ | ✅ | ⭐⭐⭐ | Vulkan only，现代设计 |

---

## 二、重点项目详细分析

### 2.1 NVRHI - NVIDIA 官方 RHI ⭐⭐⭐⭐⭐

**GitHub**: https://github.com/NVIDIA-RTX/NVRHI  
**Stars**: 1,793  
**语言**: C++17

**简介**: NVIDIA 官方渲染硬件接口抽象层，支持 DX11、DX12、Vulkan。

**核心特性**:
- ✅ 自动资源状态追踪和屏障放置（可选）
- ✅ 自动资源生命周期管理，延迟安全销毁
- ✅ 高效的资源绑定模型，运行时开销极低
- ✅ 可直接访问底层 GAPI
- ✅ 并行命令列表录制和多队列渲染
- ✅ 支持所有 Pipeline 类型：Graphics、Compute、Ray Tracing、Meshlet
- ✅ Validation Layer 和资源反射

**被 NVIDIA SDK 广泛使用**:
- DLSS SDK
- RTXDI / RTXGI / RTXPT
- RTX Neural Shading / Texture Compression
- Donut Framework

**架构**:
```
┌─────────────────────────────────────────────────────┐
│                   Application                         │
├─────────────────────────────────────────────────────┤
│                     NVRHI                             │
│  ┌─────────────┬─────────────┬─────────────┐        │
│  │  nvrhi_d3d11│  nvrhi_d3d12│   nvrhi_vk  │        │
│  └─────────────┴─────────────┴─────────────┘        │
│  ┌─────────────┬─────────────┬─────────────┐        │
│  │   DX11      │    DX12     │   Vulkan    │        │
│  └─────────────┴─────────────┴─────────────┘        │
└─────────────────────────────────────────────────────┘
```

**代码示例**:
```cpp
// 创建 Buffer
nvrhi::BufferDesc bufferDesc;
bufferDesc.byteSize = 1024;
bufferDesc.isVertexBuffer = true;
bufferDesc.debugName = "MyVertexBuffer";
nvrhi::BufferHandle buffer = m_device->createBuffer(bufferDesc);

// 创建 Pipeline
nvrhi::GraphicsPipelineDesc pipelineDesc;
pipelineDesc.VS = vertexShader;
pipelineDesc.PS = pixelShader;
pipelineDesc.primType = nvrhi::PrimitiveType::TriangleList;
nvrhi::GraphicsPipelineHandle pipeline = m_device->createGraphicsPipeline(pipelineDesc, layout);

// 绘制
commandList->setPipelineState(pipeline);
commandList->setVertexBuffer(0, buffer);
commandList->drawInstanced(3, 1, 0, 0);
```

**优点**:
- 工业级稳定性，NVIDIA 官方维护
- 自动化程度高，降低 DX12/Vulkan 复杂度
- 完整的 Ray Tracing 支持
- MIT 许可证

**缺点**:
- 不支持 Metal / OpenGL（仅 DX11/DX12/Vulkan）
- 文档相对较少

---

### 2.2 NRI - NVIDIA Render Interface ⭐⭐⭐⭐⭐

**GitHub**: https://github.com/NVIDIA-RTX/NRI  
**Stars**: 394  
**语言**: C++

**简介**: NVIDIA 低级渲染接口，专门设计用于支持 D3D12 和 Vulkan 的所有低级特性。

**设计目标**:
- 统一 D3D12 和 Vulkan
- 显式性（提供现代 GAPI 低级特性访问）
- 生活质量改进（流式传输、上采样扩展）
- 低开销
- 跨平台、厂商无关（支持 AMD/Intel）

**核心特性**:
- ✅ 多 API 支持（D3D12 / Vulkan / D3D11）
- ✅ 高性能，低开销
- ✅ 内置 Validation Layer
- ✅ Memory Management 深度集成
- ✅ 支持 Ray Tracing、Mesh Shaders
- ✅ 集成 NVIDIA/AMD/Intel SDK

**为什么选择 NRI 而非其他方案？**

| 对比项 | NVRHI | vkd3d-proton | NRI |
|--------|-------|--------------|-----|
| 类型 | D3D11 风格抽象 | D3D12 模拟 | 统一底层抽象 |
| 开销 | 中等 | 较高 | 极低 |
| 显式性 | 部分 | 完全 D3D12 | 完全统一 |
| 跨 API | DX11/DX12/VK | VK only | DX11/DX12/VK |

**架构**:
```cpp
// NRI 接口设计
namespace nri {
    struct Device {
        // 核心接口
        Result CreateBuffer(const BufferDesc& desc, Buffer** buffer);
        Result CreateTexture(const TextureDesc& desc, Texture** texture);
        Result CreatePipeline(const GraphicsPipelineDesc& desc, Pipeline** pipeline);
        
        // 命令提交
        Result CreateCommandQueue(const CommandQueueDesc& desc, CommandQueue** queue);
        Result CreateCommandBuffer(const CommandBufferDesc& desc, CommandBuffer** buffer);
    };
}
```

---

### 2.3 Diligent Engine - 功能最完善的 RHI ⭐⭐⭐⭐⭐

**GitHub**: https://github.com/DiligentGraphics/DiligentEngine  
**Stars**: 4,238  
**语言**: C++

**简介**: 现代跨平台低级图形库，支持 DX11/DX12/Vulkan/Metal/WebGPU/OpenGL。

**支持的 API**:

| 平台 | D3D11 | D3D12 | Vulkan | Metal | OpenGL | WebGPU |
|------|-------|-------|--------|-------|--------|--------|
| Windows | ✅ | ✅ | ✅ | - | ✅ | ✅ |
| Linux | - | - | ✅ | - | ✅ | ✅ |
| macOS | - | - | ✅* | ✅ | ✅ | ✅ |
| Android | - | - | ✅ | - | ✅ | - |

**核心特性**:
- ✅ 精确相同的客户端代码适用于所有平台
- ✅ 精确相同的 HLSL 着色器在所有平台运行
- ✅ 自动着色器资源绑定
- ✅ 多线程命令缓冲区生成
- ✅ 自动/显式资源状态转换
- ✅ Ray Tracing、Mesh Shaders、Bindless Resources
- ✅ 完整的教程和示例

**架构**:
```
┌───────────────────────────────────────────────────────────┐
│                      Application                            │
├───────────────────────────────────────────────────────────┤
│                   Diligent Engine                          │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Render Device  │  Device Context  │  Swap Chain   │  │
│  └─────────────────────────────────────────────────────┘  │
├───────────────────────────────────────────────────────────┤
│                  Backend Implementations                    │
│  ┌────────┬────────┬────────┬────────┬────────┬────────┐  │
│  │ D3D12  │ Vulkan │ Metal  │ D3D11  │ OpenGL │WebGPU  │  │
│  └────────┴────────┴────────┴────────┴────────┴────────┘  │
└───────────────────────────────────────────────────────────┘
```

**代码示例**:
```cpp
// 创建 Pipeline
GraphicsPipelineStateCreateInfo PSOCreateInfo;
PSOCreateInfo.PSODesc.Name = "Cube PSO";
PSOCreateInfo.PSODesc.PipelineType = PIPELINE_TYPE_GRAPHICS;

// Shader
PSOCreateInfo.pVS = pVS;
PSOCreateInfo.pPS = pPS;

// Input Layout
InputLayoutDesc LayoutDesc;
LayoutDesc.NumElements = 2;
LayoutDesc.LayoutElements = LayoutElems;
PSOCreateInfo.GraphicsPipeline.InputLayout = LayoutDesc;

// 创建
RefCntAutoPtr<IPipelineState> pPSO;
m_pDevice->CreateGraphicsPipelineState(PSOCreateInfo, &pPSO);

// 使用
m_pContext->SetPipelineState(pPSO);
DrawAttribs drawAttrs(3, DRAW_FLAG_VERIFY_ALL);
m_pContext->Draw(drawAttrs);
```

**优点**:
- 教程完善，文档齐全
- 支持最广泛的 API
- Apache 2.0 许可证
- 活跃维护

---

### 2.4 LLGL - 轻量级抽象层 ⭐⭐⭐⭐

**GitHub**: https://github.com/LukasBanana/LLGL  
**Stars**: 2,550  
**语言**: C++

**简介**: 低级图形库，薄抽象层，支持 OpenGL、Direct3D、Vulkan、Metal。

**核心特性**:
- ✅ 薄抽象层，最小化开销
- ✅ 支持 OpenGL、Direct3D 11/12、Vulkan、Metal
- ✅ 跨平台窗口管理
- ✅ 简洁的 C++ API

**代码示例**:
```cpp
// 创建 Buffer
BufferDescriptor bufferDesc;
bufferDesc.size = sizeof(vertices);
bufferDesc.bindFlags = BindFlags::VertexBuffer;
Buffer* buffer = renderer->CreateBuffer(bufferDesc, vertices);

// 创建 Pipeline
GraphicsPipelineDescriptor pipelineDesc;
pipelineDesc.vertexShader = vertexShader;
pipelineDesc.fragmentShader = fragmentShader;
pipelineDesc.renderPass = renderPass;
Pipeline* pipeline = renderer->CreatePipeline(pipelineDesc);

// 绘制
commandBuffer->SetVertexBuffer(*buffer);
commandBuffer->SetPipeline(*pipeline);
commandBuffer->Draw(3, 0);
```

---

### 2.5 Tempest - 现代 C++17 头文件优先设计 ⭐⭐⭐⭐

**GitHub**: https://github.com/Try/Tempest  
**Stars**: 204  
**语言**: C++17

**简介**: 3D 图形、UI 和声音的 API 抽象层，支持 Vulkan、DX12、Metal。

**核心特性**:
- ✅ C++17 现代 API
- ✅ 头文件优先设计
- ✅ 支持 Vulkan、DX12、Metal
- ✅ 包含 UI 和声音抽象

---

### 2.6 LiteFX - C++23 最新标准 ⭐⭐⭐⭐

**GitHub**: https://github.com/crud89/LiteFX  
**Stars**: 116  
**语言**: C++23

**简介**: 现代、灵活的计算机图形和渲染引擎，支持 Vulkan 和 DirectX 12。

**核心特性**:
- ✅ C++23 最新标准
- ✅ 支持 Vulkan 和 DirectX 12
- ✅ 现代模块化设计

---

## 三、RHI 架构设计对比

### 3.1 抽象层级对比

```
┌────────────────────────────────────────────────────────────────┐
│                     抽象层级 (从低到高)                          │
└────────────────────────────────────────────────────────────────┘

高层抽象 (易用性高，灵活性低)
    │
    │  bgfx - 立即模式 API
    │  Diligent Engine - 自动资源管理
    ▼
中层抽象 (平衡)
    │
    │  NVRHI - 自动状态追踪
    │  LLGL - 薄抽象层
    │  Tempest - 现代 C++
    ▼
低层抽象 (灵活性高，复杂度高)
    │
    │  NRI - 显式统一接口
    │  Daxa - Vulkan Bindless
    ▼
原生 API (DX12 / Vulkan)
```

### 3.2 关键设计决策

| 设计决策 | 选项 | 推荐 |
|----------|------|------|
| **资源状态管理** | 自动追踪 / 手动管理 | 自动（降低复杂度） |
| **资源绑定模型** | Bindless / 传统描述符 | Bindless（现代 GPU） |
| **命令提交** | 立即 / 延迟 | 延迟（多线程友好） |
| **同步模型** | Barrier 自动插入 / 手动 | 自动（初学者友好） |
| **着色器语言** | HLSL / GLSL / Slang | HLSL（跨平台编译） |

---

## 四、开发建议

### 4.1 学习路径

**第一阶段：学习 NVRHI**
- 研读 [NVRHI Programming Guide](https://github.com/NVIDIA-RTX/NVRHI/blob/main/doc/ProgrammingGuide.md)
- 学习 [NVRHI Tutorial](https://github.com/NVIDIA-RTX/NVRHI/blob/main/doc/Tutorial.md)
- 运行 [Donut Samples](https://github.com/NVIDIA-RTX/Donut-Samples)

**第二阶段：研究 Diligent Engine**
- 学习完整的 RHI 实现模式
- 参考多后端架构设计
- 研究自动资源绑定系统

**第三阶段：实现自己的 RHI**
- 参考 NRI 的接口设计
- 使用 NVRHI 的自动化理念
- 借鉴 Diligent Engine 的架构

### 4.2 推荐技术栈

```
┌─────────────────────────────────────────────────────────────┐
│                   游戏引擎 RHI 架构建议                       │
└─────────────────────────────────────────────────────────────┘

1. 基础层
   - 使用 NVRHI 或 NRI 作为底层抽象
   - 获得自动资源管理和低开销

2. 扩展层
   - 添加 Metal 支持（如需要）
   - 集成 Slang shader 系统

3. 上层
   - Render Graph
   - 资源缓存系统
   - Shader Hot Reload
```

### 4.3 关键学习资源

| 资源 | 链接 | 说明 |
|------|------|------|
| NVRHI Programming Guide | GitHub | 官方编程指南 |
| Diligent Engine Tutorials | GitHub | 完整教程系列 |
| DirectX 12 Spec | Microsoft | D3D12 官方规范 |
| Vulkan Spec | Khronos | Vulkan 官方规范 |
| Render Graph Architecture | GDC 2017 | Frostbite 演讲 |

---

## 五、完整项目列表

### 5.1 DX12 + Vulkan 专用项目

| 项目 | Stars | 语言 | 特点 |
|------|-------|------|------|
| **NVIDIA-RTX/NVRHI** | 1,793 | C++ | NVIDIA 官方，工业级 |
| **NVIDIA-RTX/NRI** | 394 | C++ | 低开销，显式统一 |
| **DiligentGraphics/DiligentEngine** | 4,238 | C++ | 功能最完善 |
| **LukasBanana/LLGL** | 2,550 | C++ | 轻量级，易上手 |
| **Try/Tempest** | 204 | C++17 | 现代 C++ |
| **crud89/LiteFX** | 116 | C++23 | 最新标准 |
| **shader-slang/slang-rhi** | 169 | C++ | Slang 集成 |

### 5.2 Vulkan Only 项目（设计参考）

| 项目 | Stars | 说明 |
|------|-------|------|
| **Ipotrick/Daxa** | 526 | 现代 Vulkan Bindless 抽象 |
| **zeux/niagara** | 1,683 | Vulkan 渲染器，优秀设计 |
| **inexorgame/vulkan-renderer** | 1,120 | Render Graph 架构 |

### 5.3 游戏引擎 RHI 参考

| 项目 | Stars | 说明 |
|------|-------|------|
| **NVIDIA-RTX/Donut** | 433 | NVIDIA 渲染框架 |
| **NVIDIA-RTX/RTXPT** | 917 | 实时光线追踪 |
| **ExplosionEngine/Explosion** | 192 | 跨平台游戏引擎 |

---

## 六、快速决策指南

### 6.1 应该选择哪个项目作为参考？

| 你的需求 | 推荐项目 |
|----------|----------|
| 工业级稳定性，快速上手 | **NVRHI** |
| 最低开销，完全控制 | **NRI** |
| 学习完整 RHI 实现 | **Diligent Engine** |
| 轻量级，简单集成 | **LLGL** |
| 现代 C++ 设计 | **Tempest** / **LiteFX** |

### 6.2 应该避免什么？

- ❌ 从零开始实现（工作量巨大）
- ❌ 过度抽象（性能损失）
- ❌ 忽视资源状态管理（DX12/Vulkan 核心）
- ❌ 单线程设计（无法发挥现代 GPU）

---

*本报告基于 GitHub API 实时数据整理*
