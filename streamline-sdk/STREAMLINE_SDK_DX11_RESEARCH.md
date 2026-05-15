# NVIDIA Streamline SDK DX11 支持调研报告

> 调研时间: 2026-04-27  
> 目标: 深度分析 Streamline SDK 架构，找出 DX11 使用其功能的可行方案

---

## 一、Streamline SDK 概述

### 1.1 什么是 Streamline SDK

**NVIDIA Streamline SDK** 是一个开源的跨硬件厂商框架，用于简化 NVIDIA 和其他独立硬件厂商（IHV）的超分辨率技术集成到游戏和应用中。

**核心价值**：
- **单次集成**：一次集成，支持多种超分辨率技术
- **插件架构**：即插即用的功能模块（DLSS、NRD、Reflex 等）
- **跨厂商支持**：理论上支持 NVIDIA 和其他 GPU 厂商的技术

### 1.2 架构图解

```
┌─────────────────────────────────────────────────────┐
│                   Application / Game                 │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                  Streamline Framework                │
│  ┌──────────┬──────────┬──────────┬──────────┐      │
│  │   DLSS   │   NRD    │  Reflex  │   ...    │      │
│  │  Plugin  │  Plugin  │  Plugin  │  Plugin  │      │
│  └──────────┴──────────┴──────────┴──────────┘      │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│        Graphics API (Vulkan / DX12 / DX11?)         │
└─────────────────────────────────────────────────────┘
```

### 1.3 支持的技术

| 技术 | 功能说明 |
|------|---------|
| **DLSS** | 深度学习超级采样，AI 加速的图像重建 |
| **DLAA** | 深度学习抗锯齿，提升图像质量 |
| **Frame Generation** | AI 帧生成技术（DLSS 3/4） |
| **NRD** | NVIDIA Real-time Denoisers，实时光线追踪降噪 |
| **Reflex** | 低延迟技术，优化系统响应性 |
| **Image Scaling** | NVIDIA 图像缩放（NIS） |

---

## 二、DX11 支持情况（核心问题）

### ⚠️ 重要发现：官方不支持 DX11

根据 NVIDIA 官方文档和示例代码分析：

**结论**：**Streamline SDK 目前官方只支持 Vulkan 和 DX12，不支持 DX11**

**证据**：
1. 官方示例 `nvpro-samples/vk_streamline` 只提供 Vulkan 版本
2. Streamline 的 Hooking 机制依赖 DX12/Vulkan 的底层特性
3. Frame Generation 等技术需要 DX12 的特定功能

### 2.1 为什么不支持 DX11？

| 技术原因 | 说明 |
|---------|------|
| **资源绑定模型** | DX11 的资源绑定模型与 Streamline 的抽象层不兼容 |
| **帧缓冲管理** | Frame Generation 需要直接控制交换链（DX12/Vulkan 级别） |
| **异步计算** | DLSS 需要异步计算队列（DX11 不原生支持） |
| **资源屏障** | DX12/Vulkan 的资源状态跟踪是 Streamline 的核心机制 |

---

## 三、DX11 使用 Streamline 功能的可行方案

### 方案对比总览

| 方案 | 可行性 | 复杂度 | 推荐度 |
|------|--------|--------|--------|
| **方案 A：使用原生 DLSS SDK** | ✅ 完全可行 | 中等 | ★★★★★ |
| **方案 B：DX11↔DX12 互操作** | ⚠️ 复杂 | 高 | ★★☆☆☆ |
| **方案 C：升级到 DX12** | ✅ 最佳长期方案 | 高 | ★★★★☆ |
| **方案 D：使用其他方案** | ✅ 可行 | 低 | ★★★☆☆ |

---

### 方案 A：使用原生 DLSS SDK（推荐）

**核心思路**：绕过 Streamline，直接使用 NVIDIA NGX DLSS SDK

#### 优势
- ✅ **官方支持 DX11**
- ✅ API 相对简单
- ✅ 官方有示例代码
- ✅ 社区支持完善

#### DLSS SDK DX11 集成步骤

```cpp
// 1. 初始化 NGX
NVSDK_NGX_Result result = NVSDK_NGX_D3D11_Init(
    NVSDK_NGX_Version,                 // SDK 版本
    L"./",                              // 工作目录
    g_pd3dDevice,                       // D3D11 设备
    NVSDK_NGX_ProjectSettings_Default,  // 项目设置
    NULL, NULL                          // 回调
);

// 2. 创建 DLSS 特征
NVSDK_NGX_D3D11_CreateFeature(
    g_pd3dDevice,
    NVSDK_NGX_Feature_SuperSampling,
    &dlssHandle,
    NULL
);

// 3. 设置参数
NVSDK_NGX_Parameter_SetUI(NVSDK_NGX_Parameter_OutWidth, outputWidth);
NVSDK_NGX_Parameter_SetUI(NVSDK_NGX_Parameter_OutHeight, outputHeight);

// 4. 执行 DLSS
NVSDK_NGX_D3D11_EvaluateFeature(
    g_pd3dDevice,
    dlssHandle,
    inputs,        // 深度、运动向量等
    NULL
);
```

#### 必需资源

| 资源 | 格式 | 说明 |
|------|------|------|
| **Color Buffer** | RGBA32F | 渲染的低分辨率图像 |
| **Depth Buffer** | R32F | 线性深度 |
| **Motion Vectors** | RG16F | 2D 运动向量 |
| **Exposure** | R32F | 曝光值（可选） |

#### 限制
- ❌ 无法使用 Frame Generation（需要 DX12）
- ❌ 无法使用 Streamline 的统一接口
- ⚠️ 需要单独处理签名验证

---

### 方案 B：DX11↔DX12 互操作

**核心思路**：通过 DX11/DX12 互操作桥接 Streamline

#### 技术架构

```
┌──────────────────────────────────┐
│       DX11 Rendering Engine       │
└──────────────────────────────────┘
              ↓ 共享资源
┌──────────────────────────────────┐
│   DX12 Interop Layer (新增代码)    │
└──────────────────────────────────┘
              ↓
┌──────────────────────────────────┐
│    Streamline (DX12 Plugin)       │
└──────────────────────────────────┘
```

#### 关键 API

```cpp
// 1. 创建 DX11/DX12 共享设备
IDXGIResource* dx11Texture;
HRESULT hr = g_pd3d11Device->CreateTexture2D(
    &desc, NULL, &dx11Texture
);

// 2. 获取共享句柄
HANDLE sharedHandle;
dx11Texture->GetSharedHandle(&sharedHandle);

// 3. 在 DX12 中打开资源
ID3D12Resource* dx12Resource;
g_pd3d12Device->OpenSharedHandle(sharedHandle, 
    IID_PPV_ARGS(&dx12Resource));

// 4. 传递给 Streamline
sl::D3D12Constants constants;
constants.buffer = dx12Resource;
```

#### 复杂度分析

| 方面 | 复杂度 | 说明 |
|------|--------|------|
| **资源同步** | ⭐⭐⭐⭐⭐ | DX11/DX12 需要手动同步 |
| **性能开销** | ⭐⭐⭐⭐ | 跨 API 复制成本高 |
| **调试难度** | ⭐⭐⭐⭐⭐ | 两套 API 交互问题多 |
| **维护成本** | ⭐⭐⭐⭐⭐ | 代码复杂度高 |

#### 评估结论
- ⚠️ **技术可行，但不推荐**
- ⚠️ 性能损失可能抵消 DLSS 收益
- ⚠️ 复杂度远超直接升级 DX12

---

### 方案 C：升级到 DX12（长期最佳）

**核心思路**：将渲染引擎升级到 DX12，直接使用 Streamline

#### 升级路径

```
DX11 Engine → DX12 Migration → Streamline Integration
     │              │                   │
     ↓              ↓                   ↓
  评估阶段      重构阶段           集成阶段
```

#### 迁移检查清单

| 项目 | 工作量估算 | 说明 |
|------|-----------|------|
| **资源管理** | 3-4 周 | 手动管理资源生命周期 |
| **命令队列** | 2-3 周 | 命令列表和队列抽象 |
| **资源屏障** | 2-3 周 | 正确设置资源状态转换 |
| **描述符堆** | 1-2 周 | 描述符堆管理 |
| **帧缓冲** | 1-2 周 | 渲染目标管理重构 |
| **测试验证** | 2-3 周 | 功能和性能验证 |
| **总计** | **11-17 周** | 约 3-4 个月 |

#### 优势
- ✅ 完整使用 Streamline 所有功能
- ✅ 性能最优
- ✅ 未来扩展性好
- ✅ 支持最新 GPU 特性

#### 劣势
- ⚠️ 工作量大
- ⚠️ 需要重构大量代码
- ⚠️ 团队需要学习 DX12

---

### 方案 D：替代方案

#### D.1 使用 FSR (FidelityFX Super Resolution)

**AMD FSR** 完全支持 DX11，且是开源的。

```cpp
// FSR 2.2 DX11 集成示例
fsr2CtxDesc desc = {};
desc.width = renderWidth;
desc.height = renderHeight;
desc.device = g_pd3dDevice;
desc.commandList = g_pd3d11Context;

FfxFsr2Context fsr2Context;
fsr2CreateContext(&fsr2Context, &desc);

// 执行超分
fsr2Dispatch(&fsr2Context, &dispatchParams);
```

#### D.2 使用 Intel XeSS

**XeSS** 同样支持 DX11，且有开源版本。

#### D.3 使用 NVIDIA NIS

**NVIDIA Image Scaling (NIS)** 完全支持 DX11，轻量级方案。

---

## 四、实践指南

### 4.1 方案选择决策树

```
                    是否必须使用 DLSS？
                          │
                    ┌─────┴─────┐
                   Yes          No
                    │           │
           是否需要              │
         Frame Generation?      ↓
              │           使用 FSR/XeSS
        ┌─────┴─────┐      (推荐 FSR 2.2)
       Yes          No
        │           │
        ↓           ↓
   升级到 DX12    使用原生 DLSS SDK
   (方案 C)       (方案 A)
```

### 4.2 推荐方案：原生 DLSS SDK（方案 A）

如果 DX11 项目需要使用 DLSS，**强烈推荐方案 A**：

**理由**：
1. 官方支持，风险最低
2. 集成相对简单
3. 性能接近最优
4. 社区资源丰富

### 4.3 DLSS SDK DX11 完整集成代码示例

#### 初始化

```cpp
// dlss_dx11.h
#pragma once
#include <d3d11.h>
#include <nvsdk_ngx.h>
#include <nvsdk_ngx_defs.h>
#include <nvsdk_ngx_helpers.h>

class DLSSWrapper {
public:
    bool Initialize(ID3D11Device* device);
    void Shutdown();
    bool CreateFeature(uint32_t width, uint32_t height);
    bool Execute(
        ID3D11DeviceContext* ctx,
        ID3D11Texture2D* colorBuffer,
        ID3D11Texture2D* depthBuffer,
        ID3D11Texture2D* motionVectors,
        ID3D11Texture2D* outputBuffer,
        const NVSDK_NGX_DLSS_Eval_Params& params
    );

private:
    ID3D11Device* m_device = nullptr;
    NVSDK_NGX_Handle* m_dlssHandle = nullptr;
    bool m_initialized = false;
};
```

```cpp
// dlss_dx11.cpp
#include "dlss_dx11.h"
#include <fstream>
#include <vector>

bool DLSSWrapper::Initialize(ID3D11Device* device) {
    if (m_initialized) return true;
    
    m_device = device;
    
    // 1. 初始化 NGX
    NVSDK_NGX_Result result = NVSDK_NGX_D3D11_Init(
        NVSDK_NGX_Version,
        L"./",  // 日志和签名文件目录
        device,
        NVSDK_NGX_ProjectSettings_Default,
        NULL, NULL
    );
    
    if (NVSDK_NGX_FAILED(result)) {
        // 错误处理
        return false;
    }
    
    // 2. 加载签名文件（重要！）
    // 从 NVIDIA Developer 下载应用 ID 和签名文件
    
    m_initialized = true;
    return true;
}

bool DLSSWrapper::CreateFeature(uint32_t width, uint32_t height) {
    // 设置初始化参数
    NVSDK_NGX_Parameter* params = nullptr;
    NVSDK_NGX_D3D11_GetParameters(m_device, &params);
    
    // 输出分辨率
    NVSDK_NGX_Parameter_SetUI(params, 
        NVSDK_NGX_Parameter_OutWidth, width);
    NVSDK_NGX_Parameter_SetUI(params, 
        NVSDK_NGX_Parameter_OutHeight, height);
    
    // 渲染分辨率（DLSS 会自动计算）
    // 或者手动设置
    NVSDK_NGX_Parameter_SetUI(params, 
        NVSDK_NGX_Parameter_Width, width / 2);
    NVSDK_NGX_Parameter_SetUI(params, 
        NVSDK_NGX_Parameter_Height, height / 2);
    
    // 创建 DLSS 特征
    NVSDK_NGX_Result result = NVSDK_NGX_D3D11_CreateFeature(
        m_device,
        NVSDK_NGX_Feature_SuperSampling,
        &m_dlssHandle,
        params
    );
    
    return NVSDK_NGX_SUCCEEDED(result);
}

bool DLSSWrapper::Execute(
    ID3D11DeviceContext* ctx,
    ID3D11Texture2D* colorBuffer,
    ID3D11Texture2D* depthBuffer,
    ID3D11Texture2D* motionVectors,
    ID3D11Texture2D* outputBuffer,
    const NVSDK_NGX_DLSS_Eval_Params& evalParams
) {
    // 准备评估参数
    NVSDK_NGX_DLSS_Eval_Params params = evalParams;
    
    params.pInColor = colorBuffer;
    params.pInDepth = depthBuffer;
    params.pInMotionVectors = motionVectors;
    params.pInOutput = outputBuffer;
    
    // 执行 DLSS
    NVSDK_NGX_Result result = NVSDK_NGX_D3D11_EvaluateFeature(
        ctx,
        m_dlssHandle,
        &params,
        nullptr
    );
    
    return NVSDK_NGX_SUCCEEDED(result);
}

void DLSSWrapper::Shutdown() {
    if (m_dlssHandle) {
        NVSDK_NGX_D3D11_DestroyFeature(m_device, m_dlssHandle);
        m_dlssHandle = nullptr;
    }
    
    if (m_initialized) {
        NVSDK_NGX_D3D11_Shutdown();
        m_initialized = false;
    }
}
```

#### 使用示例

```cpp
// game_renderer.cpp
#include "dlss_dx11.h"

class GameRenderer {
    DLSSWrapper m_dlss;
    ID3D11Texture2D* m_dlssOutput = nullptr;
    
public:
    void Initialize() {
        m_dlss.Initialize(g_pd3dDevice);
        m_dlss.CreateFeature(1920, 1080);
        
        // 创建输出纹理
        D3D11_TEXTURE2D_DESC desc = {};
        desc.Width = 1920;
        desc.Height = 1080;
        desc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
        desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | 
                         D3D11_BIND_RENDER_TARGET;
        
        g_pd3dDevice->CreateTexture2D(&desc, nullptr, &m_dlssOutput);
    }
    
    void Render() {
        // 1. 渲染低分辨率图像
        RenderLowResScene();
        
        // 2. 准备 DLSS 输入
        NVSDK_NGX_DLSS_Eval_Params params = {};
        params.InWidth = 960;   // 渲染分辨率
        params.InHeight = 540;
        params.OutWidth = 1920;  // 输出分辨率
        params.OutHeight = 1080;
        params.JitterOffsetX = jitterX;
        params.JitterOffsetY = jitterY;
        params.RenderSubrectDimensions = {960, 540};
        
        // 运动向量参数
        params.MvScale = {1.0f / 960.0f, 1.0f / 540.0f};
        params.FrameTimeDelta = deltaTime;
        params.Reset = false;
        params.pInDepth = m_depthBuffer;
        
        // 3. 执行 DLSS
        m_dlss.Execute(
            g_pd3d11Context,
            m_colorBuffer,      // 低分辨率渲染结果
            m_depthBuffer,       // 深度缓冲
            m_motionVectors,     // 运动向量
            m_dlssOutput,        // 输出
            params
        );
        
        // 4. 使用输出结果
        Present(m_dlssOutput);
    }
};
```

---

## 五、注意事项和避坑指南

### 5.1 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| **签名验证失败** | 缺少应用 ID 和签名文件 | 从 NVIDIA Developer 下载 |
| **图像闪烁** | 运动向量不准确 | 检查运动向量计算 |
| **图像模糊** | 缺少 Mipmap Bias | 设置 `bias = log2(renderRes/outputRes)` |
| **帧率下降** | 渲染分辨率太高 | 调整 DLSS 质量模式 |

### 5.2 性能优化建议

```cpp
// 推荐的渲染分辨率配置
enum class DLSSQuality {
    UltraPerformance,  // 0.25x 分辨率
    Performance,        // 0.33x 分辨率
    Balanced,          // 0.50x 分辨率
    Quality,           // 0.67x 分辨率
    UltraQuality       // 0.77x 分辨率
};

// Mipmap Bias 计算
float CalculateMipBias(DLSSQuality quality) {
    float ratio = 0.0f;
    switch (quality) {
        case DLSSQuality::UltraPerformance: ratio = 0.25f; break;
        case DLSSQuality::Performance:      ratio = 0.33f; break;
        case DLSSQuality::Balanced:         ratio = 0.50f; break;
        case DLSSQuality::Quality:          ratio = 0.67f; break;
        case DLSSQuality::UltraQuality:     ratio = 0.77f; break;
    }
    return log2f(ratio);
}

// 设置 Mipmap Bias（所有纹理采样器）
void SetMipmapBias(float bias) {
    for (auto& sampler : m_samplers) {
        sampler.MipLODBias = bias;
    }
}
```

### 5.3 调试技巧

```cpp
// 启用 DLSS 调试覆盖层
// 1. 使用开发版 DLL（nvngx_dlss.dll 改名为 nvngx_dlss_d.dll）
// 2. 注册表启用覆盖层
// Windows Registry:
// [HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\DLSS]
// "Overlay"=dword:00000001

// 或者使用 Streamline 的 ImGui 插件（需要 DX12）
```

---

## 六、参考资源

### 6.1 官方文档

| 资源 | 链接 |
|------|------|
| NVIDIA DLSS 开发者页面 | https://developer.nvidia.com/rtx/dlss |
| NVIDIA Streamline 页面 | https://developer.nvidia.com/rtx/streamline |
| DLSS SDK 下载 | https://developer.nvidia.com/dlss-graphics-downloads |
| NVIDIA 开发者论坛 | https://forums.developer.nvidia.com/ |

### 6.2 GitHub 项目

| 项目 | Stars | 说明 |
|------|-------|------|
| nvpro-samples/vk_streamline | ⭐ 30 | NVIDIA 官方 Vulkan 示例 |
| NVIDIA/DLSS | - | DLSS SDK（需登录下载） |

### 6.3 社区资源

- **NVIDIA GTC 演讲**: DLSS 技术深度解析
- **GDC 演讲**: DLSS 3 集成最佳实践
- **Reddit r/nvidia**: DLSS 集成讨论
- **NVIDIA 开发者 Discord**: 实时技术支持

---

## 七、总结与建议

### 7.1 核心结论

1. **Streamline SDK 官方不支持 DX11**
   - 仅支持 Vulkan 和 DX12
   - Frame Generation 等技术依赖 DX12 特性

2. **DX11 使用 DLSS 的正确方案**
   - ✅ 使用原生 DLSS SDK（推荐）
   - ❌ 不要尝试 Streamline + DX11 互操作

3. **替代方案**
   - AMD FSR 2.2（开源，支持 DX11）
   - Intel XeSS（开源版本支持 DX11）
   - NVIDIA NIS（轻量级，支持 DX11）

### 7.2 行动建议

**短期方案**：
```
使用原生 DLSS SDK + DX11
├── 下载 DLSS SDK（需 NVIDIA Developer 账号）
├── 按照本文档集成 DLSS
├── 测试验证功能和性能
└── 发布游戏更新
```

**长期规划**：
```
评估升级到 DX12 的可行性
├── 分析当前代码库结构
├── 估算迁移工作量
├── 制定详细迁移计划
└── 分阶段实施（3-6 个月）
```

### 7.3 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| DLSS SDK 版本更新 | 中 | 低 | 关注 Release Notes |
| 性能不达预期 | 低 | 中 | 多平台测试 |
| 兼容性问题 | 低 | 中 | 驱动版本检测 |
| 签名验证失败 | 中 | 高 | 提前申请应用 ID |

---

**报告结束**

如有疑问，建议参考 NVIDIA 官方文档或联系开发者支持。
