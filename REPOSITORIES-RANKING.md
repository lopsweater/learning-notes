# 调研仓库排序与简介

> 整理时间: 2026-04-16
> 目标: 为近期调研的技术仓库排序，总结应用场景和核心价值

---

## 📊 仓库排序概览

| 排名 | 仓库名称 | Stars | 类型 | 与游戏引擎开发相关度 |
|-----|---------|-------|------|---------------------|
| 🥇 1 | Hermes Agent | 48,330+ | AI Agent 框架 | ⭐⭐⭐ (工作流自动化) |
| 🥈 2 | Aperant (Auto Claude) | 13,938 | 多智能体编程 | ⭐⭐⭐ (开发效率提升) |
| 🥉 3 | 3D Gaussian Splatting | 5,000+ | 神经渲染 | ⭐⭐⭐⭐⭐ (图形渲染) |
| 4 | Slang | 4,000+ | 着色器语言 | ⭐⭐⭐⭐⭐ (着色器编译) |
| 5 | AMD RGA | 468 | GPU 分析工具 | ⭐⭐⭐⭐ (性能分析) |
| 6 | HLSL 静态分析工具链 | - | 工具集成 | ⭐⭐⭐⭐ (着色器优化) |
| 7 | LPM-1.0 | - | AI 视频生成 | ⭐⭐ (角色动画) |

---

## 一、AI Agent 开发框架

### 🥇 1. Hermes Agent

**仓库**: https://github.com/NousResearch/hermes-agent  
**Stars**: 48,330+ ⭐  
**语言**: Python  
**许可证**: MIT

#### 核心定位
> "The self-improving AI agent — creates skills from experience, improves them during use, and runs anywhere"

**自我改进的 AI Agent** - 从经验中自动创建 Skills，使用中不断改进。

#### 应用场景

```
游戏引擎开发中的应用:
│
├── 1. 自动化构建管线
│   ├── 监控 CI/CD 状态
│   ├── 自动拉取失败日志
│   └── 智能分析构建失败原因
│
├── 2. 渲染问题排查
│   ├── 自动收集 GPU 信息
│   ├── 分析性能瓶颈
│   └── 生成优化建议报告
│
├── 3. 文档生成维护
│   ├── 自动提取 API 文档
│   ├── 监控代码变更
│   └── 自动更新文档
│
└── 4. 调试辅助
    ├── 自动复现 Bug
    ├── 生成最小测试用例
    └── 提供修复建议
```

#### 主要解决问题

- **记忆持久化**: 跨会话记住你的偏好、项目细节
- **自我学习**: 自动从工作中提取最佳实践，形成 Skills
- **多平台接入**: Telegram、Discord、Slack、企业微信等
- **任务调度**: 内置 Cron，支持定时提醒和自动化任务

#### 技术亮点

| 特性 | 描述 |
|------|------|
| **40+ 内置工具** | 终端、浏览器、文件、记忆、技能、委托、媒体、调度、MCP |
| **Skills 标准** | 遵循 AgentSkills 开放标准，可共享复用 |
| **记忆系统** | 内置 + Honcho + ClawMem 多层记忆 |
| **RL 训练集成** | 支持 Atropos 强化学习环境 |
| **Serverless 支持** | Modal、Daytona 云端部署 |

#### 与游戏引擎开发的关系

**间接价值**：
- 提升开发效率（自动化重复任务）
- 智能调试辅助
- 文档自动化维护
- 性能监控告警

**不适用于**：
- 直接的图形渲染算法实现
- GPU 编程
- 实时渲染管线优化

---

### 🥈 2. Aperant (Auto Claude)

**仓库**: https://github.com/AndyMik90/Aperant  
**Stars**: 13,938 ⭐  
**语言**: TypeScript (前端) + Python (后端)  
**许可证**: AGPL-3.0

#### 核心定位
> "自动化的多智能体编程框架 - 用户描述目标，AI 自主规划、实现、验证"

**多智能体协作系统** - Planner、Coder、QA Reviewer、QA Fixer 协同工作。

#### 应用场景

```
游戏引擎开发中的应用:
│
├── 1. 复杂功能开发
│   ├── 新渲染特性实现
│   ├── 多模块重构
│   └── API 迁移升级
│
├── 2. Bug 修复自动化
│   ├── 分析 Issue 描述
│   ├── 自动定位代码
│   ├── 生成修复方案
│   └── QA 验证
│
├── 3. 测试用例生成
│   ├── 自动分析代码
│   ├── 生成单元测试
│   └── 运行验证
│
└── 4. 代码审查
    ├── 检查潜在问题
    ├── 生成审查意见
    └── 提供优化建议
```

#### 主要解决问题

- **多智能体协作**: Planner → Coder → QA → Fixer 完整开发流程
- **并行执行**: 最多 12 个智能体同时工作
- **Git Worktree 隔离**: 每个任务独立工作区，主分支安全
- **自动 QA 循环**: 发现问题自动修复

#### 工作流程

```
用户任务 → Spec 创建管线 → Planner 智能体
    ↓                        ↓
    └→ 复杂度评估 → 拆分子任务 → Coder 智能体(可并行)
                                ↓
                        QA Reviewer 验证
                                ↓
                            发现问题?
                           ↙      ↘
                         是         否
                          ↓          ↓
                      QA Fixer    用户审核
                          ↓          ↓
                      重新验证 ←─── 合并分支
```

#### 与 Hermes Agent 的对比

| 维度 | Aperant | Hermes Agent |
|------|---------|--------------|
| **核心目标** | 自动化编程 | 自我改进 Agent |
| **智能体数量** | 固定多智能体协作 | 单 Agent + 子 Agent |
| **记忆系统** | Graphiti 知识图谱 | 内存 + 外部插件 |
| **工作隔离** | Git Worktree | 无明确隔离 |
| **适用场景** | 复杂开发任务 | 日常开发辅助 |

---

## 二、图形渲染技术

### 🥉 3. 3D Gaussian Splatting

**仓库**: https://github.com/graphdeco-inria/gaussian-splatting  
**Stars**: 5,000+ ⭐  
**语言**: Python + CUDA  
**许可证**: proprietary (但生态开放)

#### 核心定位
> "用 3D 高斯球表示场景 - 无需网格，实时渲染"

**神经渲染技术** - 从照片重建 3D 场景，实时渲染 30-100+ FPS。

#### 应用场景

```
游戏引擎集成应用:
│
├── 1. 游戏场景重建
│   ├── 真实世界场景复刻
│   ├── 照片级背景渲染
│   └── 动态场景实时渲染
│
├── 2. 资产生成管线
│   ├── 摄影测量 → 3D 高斯
│   ├── 替代传统网格建模
│   └── 快速迭代场景设计
│
├── 3. 光照和材质
│   ├── 球谐函数 (SH) 表示视角相关颜色
│   ├── 支持透明物体
│   └── 无需 UV 展开
│
└── 4. 实时交互
    ├── VR/AR 内容
    ├── 实时漫游
    └── 动态物体跟踪 (4D Gaussian)
```

#### 主要解决问题

- **传统 NeRF 太慢**: 训练需数小时，渲染秒级
- **网格重建困难**: 拓扑复杂、透明物体、细节丢失
- **实时性需求**: 游戏引擎需要 30+ FPS

#### 技术原理

```
数学表示:
每个高斯球 G:
- 位置: μ ∈ R³
- 协方差: Σ = R S Sᵀ Rᵀ
  └─ R: 四元数旋转
  └─ S: 缩放矩阵
- 颜色: SH 球谐系数 (视角相关)
- 透明度: α ∈ [0, 1]

渲染流程:
GPU 排序 → Tile-based 光栅化 → Alpha Blending → 后处理
```

#### 工业级部署

**Unity 集成**:
```csharp
// Unity Package: com.graphdeco.gaussian-splatting
public class GaussianSplattingRenderer : MonoBehaviour {
    public GaussianSplatAsset splatAsset;
    
    void Update() {
        // GPU 自动处理深度排序和渲染
        Graphics.DrawGaussianSplats(splatAsset);
    }
}
```

**Unreal Engine 插件**:
- UE5.3+ 官方支持（实验性）
- Nanite 兼容
- 支持动态光照

**WebGL 渲染器**:
- https://playcanvas.com/supersplat/editor
- 三方开源实现（如 gsplat.js）

#### 游戏引擎集成的挑战

| 挑战 | 解决方案 |
|------|---------|
| **磁盘空间** | 压缩 + LOD |
| **动态光照** | 球谐函数 + 延迟光照 |
| **物理碰撞** | 生成代理网格 |
| **移动端性能** | 稀疏高斯 + 分块流式加载 |
| **动态物体** | 4D Gaussian Splatting |

---

### 4. Slang

**仓库**: https://github.com/shader-slang/slang  
**Stars**: 4,000+ ⭐  
**语言**: C++ (编译器) + Slang (着色器语言)  
**许可证**: MIT  
**官网**: https://shader-slang.com/

#### 核心定位
> "现代着色器语言 - 支持 HLSL 扩展语法、模块化、GPU 驱动自动微分"

**下一代着色器语言** - 兼容 HLSL，支持高级特性。

#### 应用场景

```
游戏引擎中的应用:
│
├── 1. 着色器模块化
│   ├── #include 替代 import
│   ├── 接口抽象 (类似 C++ concepts)
│   └── 泛型着色器
│
├── 2. 跨平台编译
│   ├── HLSL → SPIR-V (Vulkan)
│   ├── HLSL → MSL (Metal)
│   └── HLSL → DXIL (DirectX 12)
│
├── 3. 自动微分 (Autodiff)
│   ├── 渲染方程可微分
│   ├── 神经渲染集成
│   └── 梯度优化
│
└── 4. 热重载
    ├── 运行时编译
    ├── 快速迭代
    └── 调试支持
```

#### 主要解决问题

- **HLSL 语法落后**: 无模块化、无泛型、无类型推导
- **跨平台编译**: GLSL/SPIR-V/MSL 转换困难
- **着色器复用**: 不同管线重复代码
- **神经渲染**: 不可微分，无法集成神经网络

#### Slang vs HLSL vs GLSL

| 特性 | HLSL | GLSL | Slang |
|------|------|------|-------|
| **模块化** | ❌ #include | ❌ #include | ✅ import |
| **泛型** | ❌ | ❌ | ✅ Generics |
| **接口** | ❌ | ❌ | ✅ interface |
| **类型推导** | ❌ | ❌ | ✅ auto |
| **自动微分** | ❌ | ❌ | ✅ autodiff |
| **跨平台** | DirectX only | OpenGL only | ✅ DX12 + Vulkan + Metal |
| **热重载** | ❌ | ❌ | ✅ 运行时编译 |

#### 代码示例

**接口和泛型**:
```slang
// 定义着色器接口
interface ITextureSampler {
    float4 sample(float2 uv);
}

// 泛型着色器参数
struct DeferredShading<TTexture : ITextureSampler> {
    TTexture albedoMap;
    TTexture normalMap;
    
    float4 shade(float2 uv) {
        float4 albedo = albedoMap.sample(uv);
        float4 normal = normalMap.sample(uv);
        return albedo * calculateLighting(normal);
    }
}
```

**自动微分**:
```slang
[Differentiable]
float4 renderPixel(float3 position, float3 normal) {
    // Slang 自动生成反向传播
    return calculateLighting(position, normal);
}

// 训练循环（用于神经渲染）
auto grad = renderPWGrad(renderPixel);
```

#### 与游戏引擎的集成

**Unity**:
- 实验性支持（Unity 2023+）
- Compute Shader 兼容

**Unreal Engine**:
- UE 5.5+ 内置 Slang 编译器
- 替代传统 HLSL 管线

**自研引擎**:
```cpp
// C++ 集成
#include <slang/slang.h>

slang::IGlobalSession* slangGlobal;
slang::createGlobalSession(&slangGlobal);

slang::SessionDesc sessionDesc = {};
sessionDesc.searchPaths = {"shaders/"};

auto session = slangGlobal->createSession(sessionDesc);
auto module = session->loadModule("main.slang");

// 编译为 SPIR-V (Vulkan)
auto program = session->createCompositeComponentType(...);
auto kernel = program->getEntryPoint(0);
```

#### 对游戏引擎开发的意义

**架构层面**:
- 统一的着色器语言（不再维护 GLSL + HLSL + MSL）
- 模块化设计（接口 → 实现分离）

**性能层面**:
- 编译时优化（比 HLSL 更激进的死代码消除）
- 跨平台一致性（避免 HLSL→GLSL 翻译错误）

**未来技术**:
- 神经渲染集成（可微分渲染管线）
- AI 辅助着色器优化

---

### 5. AMD Radeon GPU Analyzer (RGA)

**仓库**: https://github.com/GPUOpen-Tools/radeon_gpu_analyzer  
**Stars**: 468 ⭐  
**语言**: C++  
**许可证**: MIT  
**开发商**: AMD 官方

#### 核心定位
> "离线 GPU 编译器 - 无需 AMD GPU 即可分析着色器性能"

**着色器分析工具** - 输出 AMD GPU ISA、寄存器使用、性能预估。

#### 应用场景

```
游戏引擎开发中的应用:
│
├── 1. 着色器性能优化
│   ├── VGPR/SGPR 使用分析
│   ├── 指令计数统计
│   └── 周期预估
│
├── 2. 多平台兼容性
│   ├── 编译为不同 GPU 架构 ISA
│   ├── 分析性能差异
│   └── 优化策略制定
│
├── 3. CI/CD 集成
│   ├── 自动化着色器分析
│   ├── 性能回归检测
│   └── 资源使用监控
│
└── 4. 调试辅助
    ├── ISA 级调试
    ├── 控制流分析
    └── 寄存器分配可视化
```

#### 主要解决问题

- **无 GPU 调试**: 开发机上没有 AMD GPU 也能分析
- **性能瓶颈定位**: 找出着色器耗时原因
- **跨 GPU 架构**: RDNA 2/3、CDNA 都支持

#### 输出内容

```json
{
  "pipeline": {
    "shaders": [{
      "type": "PS",
      "hardware_stages": [{
        "asic": "gfx1030",  // RDNA 2 (RX 6800)
        "statistics": {
          "vgprs": 32,      // 向量寄存器
          "sgprs": 48,      // 标量寄存器
          "isa_size": 1024, // ISA 大小
          "instructions": {
            "total": 256,
            "salo": 64,     // SALU 操作
            "valu": 128     // VALU 操作
          },
          "performance": {
            "estimated_cycles": 1500,
            "bottleneck": "throughput"
          }
        }
      }]
    }]
  }
}
```

#### 命令行使用

```bash
# HLSL → ISA 分析
rga -s dx12 -c gfx1030 -a analysis.json shader.hlsl

# 输出 ISA 汇编
rga -s dx12 -c gfx1030 --isa output.isa shader.hlsl

# 支持的 GPU 架构
rga -s dx12 --list-asics
# gfx1030, gfx1100, gfx1153, gfx950...

# 完整分析（ISA + VGPR + 周期）
rga -s dx12 -c gfx1030 \
    --isa out.isa \
    --analysis out.json \
    --livereg vgpr.txt \
    shader.hlsl
```

#### 实际应用案例

**场景**: 优化复杂像素着色器

```hlsl
// 问题：PS 太慢，需要分析
float4 PSMain(PSInput input) : SV_Target {
    float4 color = 0;
    for (int i = 0; i < 10; i++) {
        color += SampleTexture(i, input.uv);
    }
    return color;
}
```

**分析流程**:
```bash
# 1. 编译并分析
rga -s dx12 -c gfx1030 -a report.json shader.hlsl

# 2. 查看结果
cat report.json | jq '.pipeline.shaders[0].hardware_stages[0].statistics'
# {
#   "vgprs": 64,  // 寄存器压力较大
#   "total_instructions": 450,
#   "estimated_cycles": 2800
# }

# 3. 优化后重新分析
# (降低纹理采样次数、使用动态索引)
rga -s dx12 -c gfx1030 -a optimized.json shader_optimized.hlsl

# 4. 对比
# VGPR: 64 → 32
# 周期: 2800 → 1200
```

#### 与 NVIDIA 工具的对比

| 工具 | AMD RGA | NVIDIA Nsight |
|------|---------|---------------|
| **离线分析** | ✅ 无需 GPU | ❌ 需要 NVIDIA GPU |
| **ISA 输出** | ✅ AMD ISA | ✅ NVIDIA SASS |
| **性能预估** | ✅ 周期预估 | ✅ 周期精确 |
| **跨平台** | ✅ Linux + Windows | ✅ Linux + Windows |
| **集成难度** | ★★★ 简单 CLI | ★★★★ 需要驱动 |

#### 游戏引擎集成方案

**CI/CD Pipeline**:
```yaml
# .github/workflows/shader-analysis.yml
jobs:
  analyze:
    steps:
      - name: Analyze Shaders
        run: |
          for shader in shaders/*.hlsl; do
            rga -s dx12 -c gfx1030 -a "${shader}.json" "$shader"
          done
      
      - name: Check Regressions
        run: |
          python scripts/check_shader_regressions.py
```

**Python 工具集成**:
```python
import subprocess
import json

def analyze_shader(hlsl_path, target_gpu="gfx1030"):
    output_json = hlsl_path.replace('.hlsl', '.rga.json')
    
    subprocess.run([
        "rga", "-s", "dx12",
        "-c", target_gpu,
        "-a", output_json,
        hlsl_path
    ], check=True)
    
    with open(output_json) as f:
        return json.load(f)

# 使用
analysis = analyze_shader("shaders/pbr.ps.hlsl")
vgpr = analysis['pipeline']['shaders'][0]['hardware_stages'][0]['statistics']['vgprs']
print(f"VGPR 使用: {vgpr}")
```

---

### 6. HLSL 静态分析工具链

#### 核心定位
> "编译时分析 HLSL - 指令计数、资源使用、性能预估"

#### 主要工具

| 工具 | 描述 | Stars |
|------|------|-------|
| **DXC** | Microsoft 官方编译器 | 3,531 |
| **SPIRV-Reflect** | SPIR-V 反射 API | 831 |
| **naga** | Rust 通用着色器翻译器 | 1,569 |
| **AMD RGA** | AMD GPU 分析 | 468 |

#### 应用场景

```
游戏引擎优化流程:
│
├── 1. CI/CD 自动检测
│   ├── 编译着色器
│   ├── 提取指令计数
│   └── 拒绝性能退化 PR
│
├── 2. 压力测试
│   ├── 批量编译分析
│   ├── 找出性能瓶颈
│   └── 优化热点着色器
│
└── 3. 多平台对比
    ├── 同一 HLSL 编译到不同 API
    ├── 对比 SPIR-V vs DXIL
    └── 分析差异原因
```

#### 工具链组合方案

```
方案 A: DXC + 自定义 DXIL 分析器
HLSL → DXC → DXIL → 解析指令 → 统计

方案 B: AMD RGA (推荐)
HLSL → RGA → AMD ISA + 性能报告

方案 C: naga 库集成 (通用)
HLSL → naga → IR → 自定义分析
```

---

### 7. LPM-1.0 (Large Performance Model)

**官网**: https://large-performance-model.github.io/  
**类型**: AI 视频角色生成模型

#### 核心定位
> "全双工实时对话角色 - 精准唇形、身份一致"

**AI 视频角色性能模型** - 实时生成说话/聆听的角色视频。

#### 应用场景

```
游戏引擎中的潜在应用:
│
├── 1. NPC 实时对话
│   ├── 动态生成 NPC 表情动画
│   ├── 实时语音驱动
│   └── 毫秒级延迟
│
├── 2. 过场动画生成
│   ├── 降低动画制作成本
│   ├── 快速迭代对话内容
│   └── 多语言版本
│
└── 3. 玩家化身
    ├── 实时面部驱动
    ├── 多人游戏中的表达
    └── 语音聊天可视化
```

#### 主要解决问题

- **实时性**: 传统视频生成需秒级，LPM 毫秒级
- **身份一致性**: 无限时长零漂移
- **全双工对话**: 说话/聆听无缝切换

#### 技术规格

| 特性 | 数值 |
|------|------|
| 模型规模 | 17B DiT |
| 分辨率 | 480P (在线) |
| 帧率 | 24 fps |
| 延迟 | 毫秒级 |
| 身份保持 | 零漂移 |

---

## 📈 推荐学习路径

### 路径一：图形工程师（推荐）

```
Week 1-2: Slang 基基础
├── 着色器模块化设计
├── 跨平台编译
└── 热重载实践

Week 3-4: AMD RGA 性能分析
├── ISA 分析基础
├── VGPR/SGPR 优化
└── CI/CD 集成

Week 5-6: 3D Gaussian Splatting
├── 原理理解
├── Unity/Unreal 集成
└── 性能优化技巧

Week 7-8: 神经渲染进阶
├── 球谐函数
├── 4D Gaussian Splatting
└── 渲染管线集成
```

### 路径二：AI Agent 应用

```
Week 1-2: Hermes Agent 安装配置
├── 多模型支持
├── 记忆系统
└── Skills 创建

Week 3-4: 工作流自动化
├── CI/CD 监控
├── 日志分析
└── 文档生成

Week 5-6: 多智能体协作（Aperant）
├── Spec 驱动开发
├── QA 循环
└── Git Worktree 使用
```

---

## 🎯 核心价值总结

| 仓库 | 核心价值 | 是否深度调研 | 学习建议 |
|------|---------|-------------|---------|
| **Hermes Agent** | 自我改进的 AI Agent 生态 | ✅ 已完成 | 优先实践 Skills 系统 |
| **Aperant** | 多智能体协作编程框架 | ✅ 已完成 | 用于复杂重构任务 |
| **3D Gaussian Splatting** | 实时神经渲染技术 | ✅ 已完成 | 游戏场景重建革命性技术 |
| **Slang** | 现代着色器语言 | ✅ 已完成 | 引擎着色器系统升级首选 |
| **AMD RGA** | 离线 GPU 性能分析 | ✅ 已完成 | CI/CD 集成必备 |
| **HLSL 分析工具链** | 编译时着色器分析 | ✅ 已完成 | 性能优化基础工具 |
| **LPM-1.0** | AI 视频角色生成 | 📖 已初步调研 | 未来 NPC 动画趋势 |

---

## 🔗 相关资源

### 深度分析报告

- **Aperant**: `/root/learning-notes/aperant_deep_analysis.md`
- **Hermes Agent**: `/root/learning-notes/hermes-agent-deep-dive.md`
- **AMD RGA**: `/root/learning-notes/rga-deployment-guide.md`
- **HLSL 工具链**: `/root/learning-notes/hlsl-static-analysis-survey.md`
- **Slang**: `/root/learning-notes/slang/`
- **Neural Graphics**: `/root/learning-notes/neural-graphics/NEURAL-GRAPHICS-REALTIME-REPORT.md`

### 外部链接

- Hermes Agent: https://hermes-agent.nousresearch.com/docs
- Slang 官网: https://shader-slang.com/
- AMD RGA: https://gpuopen.com/radeon-gpu-analyzer/
- 3D Gaussian Splatting: https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/
- LPM-1.0: https://large-performance-model.github.io/

---

*整理完成时间: 2026-04-16*
