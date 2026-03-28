# RHI (Render Hardware Interface) 设计实现调研报告

> 调研时间: 2026-03-23
> 关键词: RHI, Graphics API Abstraction, Vulkan, DirectX, Metal, Cross-Platform

---

## 一、什么是 RHI

**RHI (Render Hardware Interface)** 是图形引擎中的抽象层，用于统一不同图形 API（Vulkan、DirectX、Metal、OpenGL 等）的接口，使上层渲染代码无需关心底层 API 细节。

### RHI 核心职责

| 职责 | 说明 |
|------|------|
| **API 统一** | 提供统一的接口屏蔽不同图形 API 差异 |
| **资源管理** | 纹理、Buffer、Pipeline 等资源的创建和管理 |
| **状态管理** | 渲染状态、混合模式、深度测试等 |
| **命令提交** | 绘制命令、计算命令的提交 |
| **同步机制** | GPU/CPU 同步、资源屏障 |
| **多线程支持** | 多线程命令录制和提交 |

---

## 二、GitHub 高星 RHI 项目

### 2.1 Tier 1: 主流框架 (Stars > 10,000)

| 项目 | Stars | 语言 | 支持的 API | 说明 |
|------|-------|------|------------|------|
| **google/filament** | 19,918 | C++ | Vulkan, Metal, OpenGL, WebGL | Google PBR 渲染引擎，完整的 RHI 抽象 |
| **gfx-rs/wgpu** | 16,735 | Rust | Vulkan, Metal, DX12, WebGL | Rust 实现，WebGPU 标准 |
| **bkaradzic/bgfx** | 16,863 | C++ | Vulkan, DX9-12, Metal, OpenGL, WebGL | "Bring Your Own Engine" 风格 |
| **ConfettiFX/The-Forge** | 5,493 | C++ | Vulkan, DX12, Metal, PS/Xbox/Switch | 跨平台游戏框架，支持主机平台 |

### 2.2 Tier 2: 专业级框架 (Stars 1,000 - 5,000)

| 项目 | Stars | 语言 | 支持的 API | 说明 |
|------|-------|------|------------|------|
| **DiligentGraphics/DiligentEngine** | 4,238 | C++ | Vulkan, DX11/12, Metal, OpenGL, WebGPU | 现代 RHI，支持 Ray Tracing |
| **dotnet/Silk.NET** | 4,963 | C# | Vulkan, OpenGL, OpenAL, DirectX, WebGPU | .NET 高性能绑定 |
| **LukasBanana/LLGL** | 2,550 | C++ | Vulkan, DX11/12, Metal, OpenGL | 轻量级抽象层 |
| **zeux/niagara** | 1,683 | C++ | Vulkan | Vulkan 渲染器（无抽象层，但设计优秀） |
| **inexorgame/vulkan-renderer** | 1,120 | C++ | Vulkan | Render Graph 架构 |

### 2.3 Tier 3: 轻量级框架 (Stars < 1,000)

| 项目 | Stars | 语言 | 支持的 API | 说明 |
|------|-------|------|------------|------|
| **MethanePowered/MethaneKit** | 952 | C++20 | Vulkan, DX12, Metal | 现代 C++20，跨平台 |
| **google/dawn** | 940 | C++ | Vulkan, Metal, DX12, OpenGL | WebGPU 原生实现 |
| **jdryg/vg-renderer** | 620 | C | bgfx 后端 | 矢量图形渲染器 |
| **nicebyte/nicegraf** | 219 | C | Vulkan, Metal, OpenGL, D3D11 | 纯 C 抽象 |
| **Try/Tempest** | 204 | C++17 | Vulkan, DX12, Metal | 头文件优先设计 |
| **gopro/ngfx** | 65 | C++ | Vulkan, DX12, Metal | GoPro 内部使用 |
| **Snapchat/SnapRHI** | 35 | C++ | Vulkan, Metal, DX12 | Snapchat 轻量级 RHI |

---

## 三、重点项目详细分析

### 3.1 bgfx - 最流行的跨平台渲染库

**GitHub**: https://github.com/bkaradzic/bgfx  
**Stars**: 16,863  
**语言**: C++

**特点**:
- 支持 11 种渲染后端: Vulkan, DirectX 9/11/12, Metal, OpenGL, OpenGL ES, WebGL
- "Bring Your Own Engine" 设计哲学
- 立即模式 API (类似 OpenGL 风格)
- 内置着色器跨编译 (GLSL → HLSL → MSL → SPIR-V)
- 极小的构建依赖

**架构**:
```
┌─────────────────────────────────────────┐
│              Application                 │
├─────────────────────────────────────────┤
│                  bgfx                    │
│  ┌───────┬───────┬───────┬───────┐      │
│  │ GL    │ VK    │ DX12  │ Metal │      │
│  └───────┴───────┴───────┴───────┘      │
└─────────────────────────────────────────┘
```

**核心 API 风格**:
```cpp
// 立即模式渲染
bgfx::setVertexBuffer(0, vertexBuffer);
bgfx::setIndexBuffer(indexBuffer);
bgfx::setProgram(program);
bgfx::submit(viewId);
```

---

### 3.2 wgpu - Rust WebGPU 实现

**GitHub**: https://github.com/gfx-rs/wgpu  
**Stars**: 16,735  
**语言**: Rust

**特点**:
- Rust 实现的安全图形 API
- 基于 WebGPU 标准
- 支持 Vulkan, Metal, DirectX 12, OpenGL, WebGL
- Firefox、Servo 等项目使用

**架构**:
```
┌─────────────────────────────────────────┐
│             User Code                    │
├─────────────────────────────────────────┤
│              wgpu                        │
│  ┌───────┬───────┬───────┬───────┐      │
│  │ Vulkan│ Metal │ DX12  │ GL    │      │
│  └───────┴───────┴───────┴───────┘      │
└─────────────────────────────────────────┘
```

**核心 API 风格**:
```rust
let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
    label: Some("Render Pipeline"),
    layout: Some(&pipeline_layout),
    vertex: wgpu::VertexState { ... },
    fragment: Some(wgpu::FragmentState { ... }),
    // ...
});

// Render Pass
render_pass.set_pipeline(&pipeline);
render_pass.draw(0..3, 0..1);
```

---

### 3.3 Filament - Google PBR 渲染引擎

**GitHub**: https://github.com/google/filament  
**Stars**: 19,918  
**语言**: C++

**特点**:
- Google 官方 PBR 渲染引擎
- Android / iOS / PC / Web 全平台支持
- Vulkan, Metal, OpenGL, WebGL 后端
- 高度优化的移动端渲染
- 完整的材质系统

**RHI 架构**:
```cpp
// Filament RHI 抽象
class Driver {
    // 资源创建
    virtual Handle<HwVertexBuffer> createVertexBuffer() = 0;
    virtual Handle<HwIndexBuffer> createIndexBuffer() = 0;
    virtual Handle<HwTexture> createTexture() = 0;
    
    // 命令提交
    virtual void beginRenderPass() = 0;
    virtual void endRenderPass() = 0;
    virtual void draw() = 0;
};

// 后端实现: VulkanDriver, MetalDriver, OpenGLDriver
```

---

### 3.4 Diligent Engine - 现代跨平台 RHI

**GitHub**: https://github.com/DiligentGraphics/DiligentEngine  
**Stars**: 4,238  
**语言**: C++

**特点**:
- 支持 Vulkan, DirectX 11/12, Metal, OpenGL, WebGPU
- Ray Tracing 支持
- Pipeline State Object (PSO) 缓存
- Shader 跨编译
- 完整的教程和示例

**核心架构**:
```cpp
// Pipeline State Object
GraphicsPipelineStateCreateInfo PSOCreateInfo;
PSOCreateInfo.PSODesc.PipelineType = PIPELINE_TYPE_GRAPHICS;
PSOCreateInfo.pVS = pVS;
PSOCreateInfo.pPS = pPS;

// 创建 Pipeline
RefCntAutoPtr<IPipelineState> pPSO;
m_pDevice->CreateGraphicsPipelineState(PSOCreateInfo, &pPSO);

// 绘制
m_pContext->SetPipelineState(pPSO);
m_pContext->CommitShaderResources(pSRB, RESOURCE_STATE_TRANSITION_MODE_TRANSITION);
DrawAttribs drawAttrs;
m_pContext->Draw(drawAttrs);
```

---

### 3.5 The-Forge - 主机级跨平台框架

**GitHub**: https://github.com/ConfettiFX/The-Forge  
**Stars**: 5,493  
**语言**: C++

**特点**:
- 支持所有主流平台: PC, macOS, iOS, Android, PS4/5, Xbox, Switch, Quest
- Ray Tracing 支持
- Multi-GPU 支持
- 专为游戏优化
- Visibility Buffer 渲染

**RHI 抽象**:
```cpp
// Renderer 接口
typedef struct Renderer {
    // 资源创建
    void (*createBuffer)(...);
    void (*createTexture)(...);
    void (*createPipeline)(...);
    
    // 命令提交
    void (*cmdBindPipeline)(...);
    void (*cmdBindVertexBuffer)(...);
    void (*cmdDraw)(...);
} Renderer;

// 后端: VulkanRenderer, MetalRenderer, DX12Renderer
```

---

## 四、RHI 设计模式对比

### 4.1 API 风格对比

| 风格 | 代表项目 | 优点 | 缺点 |
|------|----------|------|------|
| **立即模式** | bgfx | 易用，类似 OpenGL | 难以充分利用多线程 |
| **延迟模式** | Vulkan, DX12 | 高性能，多线程友好 | 复杂，学习曲线陡峭 |
| **对象导向** | Diligent, Filament | 类型安全，易扩展 | 有一定开销 |
| **函数式** | wgpu (Rust) | 安全，无 UB | 语言绑定限制 |

### 4.2 资源管理策略

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| **RAII** | 资源随对象生命周期管理 | C++ 项目 |
| **引用计数** | 共享资源管理 | 资源复用场景 |
| **延迟销毁** | GPU 使用完毕后销毁 | 现代 API (VK/DX12) |
| **帧池** | 每帧重置的资源池 | 临时资源 |

### 4.3 多线程支持

```
┌────────────────────────────────────────────────────────────┐
│                    多线程渲染架构                            │
└────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │  主线程       │
                    │  逻辑更新     │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ 命令线程1 │    │ 命令线程2 │    │ 命令线程3 │
    │ CmdList  │    │ CmdList  │    │ CmdList  │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
         └───────────────┼───────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   提交线程    │
                  │   GPU Queue  │
                  └──────────────┘
```

---

## 五、Render Graph 架构

现代 RHI 趋向于使用 **Render Graph** 管理渲染流程：

### 5.1 Render Graph 概念

```cpp
// Frostbite 风格的 Render Graph
RenderGraph renderGraph;

// 添加 Pass
auto& pass = renderGraph.addPass("GBufferPass", RenderGraphQueue::Graphics);
pass.write(depthTexture, TextureUsage::DepthWrite);
pass.write(gbuffer0, TextureUsage::RenderTarget);
pass.write(gbuffer1, TextureUsage::RenderTarget);
pass.execute([=](RenderGraphContext& ctx) {
    // 渲染代码
});

// 自动资源管理和同步
renderGraph.compile();
renderGraph.execute();
```

### 5.2 Render Graph 项目

| 项目 | Stars | 说明 |
|------|-------|------|
| **inexorgame/vulkan-renderer** | 1,120 | Vulkan Render Graph 引擎 |
| **asc-community/VulkanAbstractionLayer** | 152 | Render Graph Vulkan 抽象 |
| **troughton/Substrate** | 165 | Swift Render Graph |

---

## 六、推荐学习路径

### 6.1 入门级

1. **bgfx** - 最易上手，立即模式 API
2. **LLGL** - 轻量级，代码量适中

### 6.2 进阶级

1. **Diligent Engine** - 现代 C++ 设计，教程完善
2. **MethaneKit** - C++20，现代设计模式

### 6.3 专业级

1. **Filament** - 工业级设计，Google 最佳实践
2. **The-Forge** - 主机级跨平台实现
3. **wgpu** - Rust 安全设计，WebGPU 标准

---

## 七、与 AI Game Engine 的集成建议

### 7.1 RHI 层设计建议

```
┌────────────────────────────────────────────────────────────┐
│                    AI Game Engine                           │
├────────────────────────────────────────────────────────────┤
│                    High-Level Renderer                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Scene Graph  │  Materials  │  Lighting  │  Effects │   │
│  └─────────────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────────────┤
│                    RHI Abstraction Layer                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Buffers  │  Textures  │  Pipelines  │  Commands    │   │
│  └─────────────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────────────┤
│  Vulkan  │  DirectX 12  │  Metal  │  WebGPU  │  OpenGL   │
└────────────────────────────────────────────────────────────┘
```

### 7.2 可选方案

| 方案 | 复杂度 | 推荐理由 |
|------|--------|----------|
| **使用 bgfx** | 低 | 成熟稳定，跨平台完善 |
| **使用 Diligent Engine** | 中 | 现代 C++，功能完善 |
| **自己实现** | 高 | 完全可控，适合学习 |

### 7.3 关键学习资源

- [bgfx Examples](https://github.com/bkaradzic/bgfx/tree/master/examples)
- [Diligent Engine Tutorials](https://github.com/DiligentGraphics/DiligentEngine/tree/master/Tutorials)
- [Filament Documentation](https://google.github.io/filament/Filament.html)
- [Vulkan Tutorial](https://vulkan-tutorial.com/)
- [Render Graph Architecture (GDC 2017)](https://www.gdcvault.com/play/1024612/FrameGraph-Extensible-Rendering-Architecture-in)

---

## 附录：完整项目列表

| 项目 | Stars | 语言 | 支持的 API |
|------|-------|------|------------|
| google/filament | 19,918 | C++ | Vulkan, Metal, OpenGL, WebGL |
| gfx-rs/wgpu | 16,735 | Rust | Vulkan, Metal, DX12, WebGPU |
| bkaradzic/bgfx | 16,863 | C++ | Vulkan, DX9-12, Metal, GL, WebGL |
| ConfettiFX/The-Forge | 5,493 | C++ | Vulkan, DX12, Metal, PS, Xbox |
| dotnet/Silk.NET | 4,963 | C# | Vulkan, GL, DX, WebGPU |
| DiligentGraphics/DiligentEngine | 4,238 | C++ | Vulkan, DX11/12, Metal, GL, WebGPU |
| LukasBanana/LLGL | 2,550 | C++ | Vulkan, DX11/12, Metal, OpenGL |
| zeux/niagara | 1,683 | C++ | Vulkan |
| inexorgame/vulkan-renderer | 1,120 | C++ | Vulkan (Render Graph) |
| MethanePowered/MethaneKit | 952 | C++20 | Vulkan, DX12, Metal |
| google/dawn | 940 | C++ | Vulkan, Metal, DX12, OpenGL |
| nicebyte/nicegraf | 219 | C | Vulkan, Metal, OpenGL, D3D11 |
| Try/Tempest | 204 | C++17 | Vulkan, DX12, Metal |
| gopro/ngfx | 65 | C++ | Vulkan, DX12, Metal |
| Snapchat/SnapRHI | 35 | C++ | Vulkan, Metal, DX12 |

---

*本报告基于 GitHub API 实时数据整理*
