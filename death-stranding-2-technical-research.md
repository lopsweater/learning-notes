# 死亡搁浅2 (Death Stranding 2: On the Beach) 技术调研报告

> 调研日期: 2026-03-20
> 游戏发布日期: 2025年6月26日 (PS5), 2026年3月19日 (Windows)
> 开发商: Kojima Productions
> 发行商: Sony Interactive Entertainment

---

## 目录

1. [游戏概述](#1-游戏概述)
2. [Decima 引擎深度分析](#2-decima-引擎深度分析)
3. [死亡搁浅2的技术演进](#3-死亡搁浅2的技术演进)
4. [渲染与图形技术](#4-渲染与图形技术)
5. [物理与AI系统](#5-物理与ai系统)
6. [开放世界与流式加载](#6-开放世界与流式加载)
7. [PSSR与PS5 Pro增强](#7-pssr与ps5-pro增强)
8. [与竞品引擎对比](#8-与竞品引擎对比)
9. [技术参考资源](#9-技术参考资源)
10. [总结与启示](#10-总结与启示)

---

## 1. 游戏概述

### 1.1 基本信息

《死亡搁浅2：On the Beach》是由小岛工作室开发、索尼互动娱乐发行的开放世界动作冒险游戏。作为2019年《死亡搁浅》的续作，本作延续了独特的"连接"主题，在技术上实现了全面升级。

### 1.2 平台与技术规格

| 项目 | 规格 |
|------|------|
| 游戏引擎 | Decima Engine (增强版) |
| 目标平台 | PlayStation 5, Windows PC |
| 渲染API | DirectX 12 (PC/Windows), PlayStation原生API |
| 分辨率支持 | 4K (动态分辨率), HDR |
| 帧率 | 30fps (质量模式), 60fps (性能模式), 最高120fps |
| PS5 Pro增强 | PSSR (PlayStation Spectral Super Resolution) |

---

## 2. Decima 引擎深度分析

### 2.1 引擎历史与发展

Decima 引擎由 Guerrilla Games 开发，首次用于 2013 年的《杀戮地带：暗影坠落》。引擎以日本江户时代的荷兰贸易站"出岛"(Dejima)命名，象征着 Guerrilla Games (荷兰) 与 Kojima Productions (日本) 之间的合作。

**引擎演进时间线:**

```
2013 - Killzone: Shadow Fall (PS4首发作品)
2015 - Until Dawn (互动恐怖游戏)
2016 - PlayStation VR 支持
2017 - Horizon Zero Dawn (开放世界突破)
2019 - Death Stranding (小岛工作室首作)
2022 - Horizon Forbidden West (PS4/PS5跨代)
2025 - Death Stranding 2 (PS5原生)
```

### 2.2 引擎架构

Decima 采用模块化架构设计，核心子系统包括：

```
┌─────────────────────────────────────────────────────────────┐
│                    Decima Engine Architecture                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Renderer  │  │   Physics   │  │     AI      │         │
│  │   System    │  │   Engine    │  │   System    │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│  ┌──────┴────────────────┴────────────────┴──────┐         │
│  │              Core Systems Layer               │         │
│  │  (Memory, Jobs, Streaming, Resource Mgmt)     │         │
│  └─────────────────────┬─────────────────────────┘         │
│                        │                                    │
│  ┌─────────────────────┴─────────────────────────┐         │
│  │           Platform Abstraction Layer          │         │
│  │    (PS5 SDK, DirectX 12, Metal, Vulkan)       │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 核心技术特点

#### 2.3.1 渲染系统

- **延迟渲染 (Deferred Rendering)**: 基于G-Buffer的延迟渲染管线
- **全局光照 (Global Illumination)**: 基于探针的间接光照系统
- **体积光与雾效**: 实时体积光渲染
- **粒子系统**: GPU加速的粒子模拟

#### 2.3.2 物理引擎

从 Horizon Forbidden West 开始，Decima 采用开源的 **Jolt Physics** 引擎替代自研物理系统：

```cpp
// Jolt Physics 特点
- 开源 (MIT License)
- 高性能多线程设计
- 支持刚体、软体、车辆物理
- 优化的碰撞检测系统
```

#### 2.3.3 AI 系统

Decima 使用 **HTN (Hierarchical Task Network)** 规划系统：

```
HTN Planning Structure:
├── Domain (任务域)
│   ├── Primitive Tasks (原子任务)
│   └── Compound Tasks (复合任务)
├── Planner (规划器)
│   ├── Task Decomposition (任务分解)
│   └── State Validation (状态验证)
└── World State (世界状态)
    ├── Agent State (代理状态)
    └── Environment State (环境状态)
```

### 2.4 工具链

Decima 配备完整的开发工具：

- **编辑器**: 实时场景编辑器
- **资产管线**: 自动化资产导入与处理
- **调试工具**: 运行时性能分析
- **版本控制集成**: Perforce 原生支持

---

## 3. 死亡搁浅2的技术演进

### 3.1 相比初代的改进

#### 3.1.1 渲染技术升级

| 特性 | Death Stranding 1 | Death Stranding 2 |
|------|-------------------|-------------------|
| 目标平台 | PS4/PC | PS5/PC |
| 光照系统 | 静态+动态混合 | 全动态全局光照 |
| 植被渲染 | 实例化渲染 | 增强的程序化植被 |
| 水体渲染 | 基础水体模拟 | 高级流体模拟 |
| 角色渲染 | 高精度面部捕捉 | 升级的面部动画系统 |

#### 3.1.2 世界构建

- **更大的开放世界**: 更广阔的地图区域
- **程序化内容生成**: 动态地形与植被
- **异步多人系统**: 升级的"Social Strand System"
- **天气系统**: 增强的动态天气效果

### 3.2 PS5 硬件利用

#### 3.2.1 SSD 流式加载

```cpp
// PS5 SSD 规格
- 读取速度: 5.5 GB/s (原始), 8-9 GB/s (压缩)
- I/O 架构: 与 GPU/内存直接连接
- 压缩: Kraken 压缩格式

// 流式加载策略
1. 虚拟纹理 (Virtual Texturing)
2. 几何体流式加载 (Geometry Streaming)
3. LOD 动态切换 (Dynamic LOD)
4. 资产预取 (Asset Prefetching)
```

#### 3.2.2 Tempest 3D Audio

- HRTF 头部相关传递函数
- 数百个音源同时处理
- 空间音频定位

### 3.3 新增技术特性

#### 3.3.1 升级的光照系统

```
光照技术栈:
├── 直接光照
│   ├── 太阳光阴影 (Cascaded Shadow Maps)
│   └── 局部光源 (Clustered Lighting)
├── 间接光照
│   ├── 光照探针 (Light Probes)
│   ├── 屏幕空间全局光照 (SSGI)
│   └── 辐照度体积 (Irradiance Volumes)
└── 大气效果
    ├── 体积云 (Volumetric Clouds)
    ├── 大气散射 (Atmospheric Scattering)
    └── 雾效 (Volumetric Fog)
```

#### 3.3.2 角色动画系统

- **面部捕捉升级**: 更高精度的面部表情捕捉
- **运动匹配 (Motion Matching)**: AI驱动的动画过渡
- **程序化动画**: 环境交互的动态响应

---

## 4. 渲染与图形技术

### 4.1 渲染管线

Decima 采用**延迟渲染**管线，针对 PS5 进行了优化：

```
Frame Rendering Pipeline:
┌────────────────────────────────────────────────────────┐
│  1. G-Buffer Pass                                      │
│     ├── Albedo (RGB)                                   │
│     ├── Normal (RGB)                                   │
│     ├── Roughness/Metallic (RG)                       │
│     └── Depth (R32F)                                   │
├────────────────────────────────────────────────────────┤
│  2. Shadow Pass                                        │
│     ├── Cascaded Shadow Maps (太阳光)                  │
│     └── Point Light Shadows (局部光源)                 │
├────────────────────────────────────────────────────────┤
│  3. Lighting Pass                                      │
│     ├── Deferred Lighting                              │
│     ├── Screen Space Reflections                       │
│     └── Screen Space Global Illumination              │
├────────────────────────────────────────────────────────┤
│  4. Post Processing                                    │
│     ├── Temporal Anti-Aliasing (TAA)                  │
│     ├── Bloom                                          │
│     ├── Depth of Field                                 │
│     ├── Motion Blur                                    │
│     └── Tone Mapping                                   │
└────────────────────────────────────────────────────────┘
```

### 4.2 植被与地形渲染

Decima 的植被系统是其核心技术亮点：

#### 4.2.1 GPU 程序化放置

基于 GDC 2017 演讲，Horizon Zero Dawn 的植被系统：

```hlsl
// GPU Procedural Placement Pipeline
1. Density Map Generation
   - 基于地形类型生成密度图
   
2. Pattern Generation
   - 使用蓝噪声分布
   - GPU Compute Shader 执行
   
3. Collision Detection
   - 与地形、岩石、道路的碰撞检测
   
4. Layered Dithering
   - 多层植被的抗锯齿处理
   
5. Instance Data Output
   - 实例化渲染数据输出
```

#### 4.2.2 植被着色器

```hlsl
// Vegetation Shader 特点
- Vertex Program: 风力动画
- Pixel Program: 半透明排序
- Translucency: 次表面散射模拟
- Anti-Aliasing: Alpha to Coverage
```

### 4.3 水体渲染

死亡搁浅2的水体渲染技术：

```
Water Rendering System:
├── 几何体
│   ├── 程序化波浪 (FFT Wave Simulation)
│   ├── 网格细分 (Tessellation)
│   └── 泡沫与涟漪
├── 着色
│   ├── 菲涅尔反射
│   ├── 折射效果
│   ├── 深度雾化
│   └── 高光反射
└── 物理交互
    ├── 角色与水的交互
    ├── 物体浮力模拟
    └── 水花粒子系统
```

### 4.4 粒子系统

GPU 加速的粒子系统：

```cpp
// Particle System Architecture
struct ParticleSystem {
    // GPU Compute 执行
    - Emission (粒子发射)
    - Simulation (物理模拟)
    - Culling (视锥剔除)
    - Sorting (深度排序)
    
    // 渲染特性
    - 软粒子 (Soft Particles)
    - 粒子光照
    - 粒子阴影
    - 体积粒子
};
```

---

## 5. 物理与AI系统

### 5.1 Jolt Physics 集成

从 Horizon Forbidden West 开始使用 Jolt Physics：

#### 5.1.1 架构特点

```cpp
// Jolt Physics 核心组件
namespace JPH {
    // 核心系统
    class PhysicsSystem;       // 物理世界
    class Body;                // 刚体
    class Shape;               // 碰撞形状
    
    // 约束系统
    class Constraint;          // 约束基类
    class HingeConstraint;     // 铰链约束
    class SliderConstraint;    // 滑动约束
    
    // 碰撞检测
    class BroadPhaseLayer;     // 宽相碰撞层
    class ObjectLayer;         // 对象层
    class CollisionCollector;  // 碰撞收集器
}
```

#### 5.1.2 多线程优化

```
Threading Architecture:
┌─────────────────────────────────────────────┐
│           Physics Simulation Step           │
├─────────────────────────────────────────────┤
│  Job System (任务调度)                       │
│  ├── Broad Phase (宽相检测) - 并行           │
│  ├── Narrow Phase (窄相检测) - 并行          │
│  ├── Solver (求解器) - 并行                  │
│  └── Integration (积分) - 并行               │
└─────────────────────────────────────────────┘
```

### 5.2 HTN AI 规划系统

Decima 使用 HTN (Hierarchical Task Network) 进行 AI 行为规划：

#### 5.2.1 HTN 结构

```cpp
// HTN Domain 定义示例
Domain CombatDomain {
    // 复合任务
    CompoundTask AttackEnemy {
        Method 1: MeleeAttack
            Conditions: InMeleeRange()
            Subtasks: { Approach, Strike, Retreat }
            
        Method 2: RangedAttack
            Conditions: HasAmmo() && LineOfSight()
            Subtasks: { Aim, Shoot, TakeCover }
    }
    
    // 原子任务
    PrimitiveTask Approach {
        Effects: SetPosition(NearEnemy)
    }
}
```

#### 5.2.2 规划器执行

```
HTN Planner Execution:
1. 获取当前世界状态
2. 选择最高优先级的复合任务
3. 分解为子任务
4. 验证子任务的前置条件
5. 执行原子任务
6. 更新世界状态
7. 重复直到目标达成或失败
```

### 5.3 行为树与HTN结合

```
AI Architecture:
┌─────────────────────────────────────────────┐
│              AI Decision System             │
├─────────────────────────────────────────────┤
│  ┌─────────────┐      ┌─────────────┐      │
│  │  Behavior   │◄────►│    HTN      │      │
│  │    Tree     │      │  Planner    │      │
│  │ (短期决策)   │      │ (长期规划)   │      │
│  └──────┬──────┘      └──────┬──────┘      │
│         │                    │              │
│         └────────┬───────────┘              │
│                  ▼                          │
│         ┌─────────────┐                     │
│         │  Animation  │                     │
│         │  Controller │                     │
│         └─────────────┘                     │
└─────────────────────────────────────────────┘
```

---

## 6. 开放世界与流式加载

### 6.1 世界流式系统

Decima 的世界流式架构：

```
World Streaming Architecture:
┌─────────────────────────────────────────────┐
│           Streaming Manager                 │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │         Sector Grid                 │    │
│  │  ┌───┬───┬───┬───┬───┬───┬───┐    │    │
│  │  │   │   │   │   │   │   │   │    │    │
│  │  ├───┼───┼───┼───┼───┼───┼───┤    │    │
│  │  │   │   │ ● │ ● │ ● │   │   │    │    │
│  │  ├───┼───┼───┼───┼───┼───┼───┤    │    │
│  │  │   │   │ ● │ ★ │ ● │   │   │    │    │
│  │  ├───┼───┼───┼───┼───┼───┼───┤    │    │
│  │  │   │   │ ● │ ● │ ● │   │   │    │    │
│  │  └───┴───┴───┴───┴───┴───┴───┘    │    │
│  │  ★ = 玩家位置  ● = 加载区域        │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  流式队列优先级:                             │
│  1. 玩家周围区域 (高优先级)                  │
│  2. 玩家朝向区域 (中优先级)                  │
│  3. 背景区域 (低优先级)                      │
└─────────────────────────────────────────────┘
```

### 6.2 虚拟纹理

```cpp
// Virtual Texturing System
struct VirtualTexture {
    // 纹理分块
    struct Tile {
        uint32_t mipLevel;
        uint32_t tileX, tileY;
        bool isResident;
    };
    
    // 页表
    PageTable pageTable;
    
    // 缓存系统
    TextureCache cache;
    
    // 反馈机制
    FeedbackBuffer feedback;  // GPU→CPU 请求
};
```

### 6.3 LOD 系统

```
Level of Detail Strategy:
┌─────────────────────────────────────────────┐
│             LOD Management                  │
├─────────────────────────────────────────────┤
│  距离 LOD (Distance LOD)                    │
│  ├── LOD0: 0-50m (最高细节)                 │
│  ├── LOD1: 50-150m                          │
│  ├── LOD2: 150-400m                         │
│  └── LOD3: 400m+ (Impostor)                 │
│                                             │
│  屏幕尺寸 LOD (Screen Size LOD)             │
│  └── 基于像素覆盖动态切换                    │
│                                             │
│  HLOD (Hierarchical LOD)                    │
│  └── 远距离对象合并渲染                      │
└─────────────────────────────────────────────┘
```

---

## 7. PSSR与PS5 Pro增强

### 7.1 PSSR 技术解析

**PlayStation Spectral Super Resolution (PSSR)** 是索尼的 AI 超分辨率技术：

#### 7.1.1 技术原理

```
PSSR Pipeline:
┌─────────────────────────────────────────────┐
│           PSSR Upscaling                    │
├─────────────────────────────────────────────┤
│  Input: 低分辨率图像 (如 1080p)              │
│         + 运动向量                          │
│         + 深度缓冲                          │
│                  ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │    AI Inference (机器学习推理)       │    │
│  │    - Sony 定制神经网络              │    │
│  │    - 专门针对游戏场景训练            │    │
│  │    - 运行于 PS5 Pro AI 加速器        │    │
│  └─────────────────────────────────────┘    │
│                  ▼                          │
│  Output: 4K 分辨率图像                      │
│                                             │
│  特点:                                      │
│  - 低延迟 (约 2ms)                          │
│  - 无需逐游戏训练                           │
│  - 支持 HDR                                 │
│  - 优于传统升频算法                          │
└─────────────────────────────────────────────┘
```

#### 7.1.2 与 DLSS/FSR 对比

| 特性 | PSSR | DLSS 3 | FSR 3 |
|------|------|--------|-------|
| 硬件要求 | PS5 Pro | RTX 40系列 | 全平台 |
| 训练需求 | 无 | 需要 | 无 |
| 帧生成 | 无 | 有 | 有 |
| 延迟 | ~2ms | ~5ms | ~3ms |
| 画质 | 优秀 | 优秀 | 良好 |

### 7.2 死亡搁浅2的PS5 Pro特性

```
PS5 Pro Enhancement Modes:
┌─────────────────────────────────────────────┐
│  Quality Mode (质量模式)                     │
│  ├── 分辨率: 动态 4K (PSSR)                 │
│  ├── 帧率: 30fps                            │
│  └── 光线追踪: 全开                         │
├─────────────────────────────────────────────┤
│  Performance Mode (性能模式)                 │
│  ├── 分辨率: 动态 4K (PSSR)                 │
│  ├── 帧率: 60fps                            │
│  └── 光线追踪: 部分                         │
├─────────────────────────────────────────────┤
│  Performance Pro Mode (增强性能模式)         │
│  ├── 分辨率: 动态 4K (PSSR)                 │
│  ├── 帧率: 最高 120fps                      │
│  └── 光线追踪: 部分                         │
└─────────────────────────────────────────────┘
```

### 7.3 高级光线追踪

死亡搁浅2 在 PS5 Pro 上的光线追踪增强：

```
Ray Tracing Features:
├── 光线追踪反射
│   └── 水面、金属表面的实时反射
├── 光线追踪阴影
│   └── 高质量软阴影
├── 光线追踪全局光照
│   └── 增强的间接光照
└── 光线追踪环境光遮蔽
    └── 更精确的遮蔽效果
```

---

## 8. 与竞品引擎对比

### 8.1 与 Unreal Engine 5 对比

| 特性 | Decima Engine | Unreal Engine 5 |
|------|---------------|-----------------|
| 开放世界优化 | ★★★★★ | ★★★★☆ |
| 美术管线 | ★★★★☆ | ★★★★★ |
| 渲染质量 | ★★★★★ | ★★★★★ |
| 跨平台支持 | ★★★☆☆ | ★★★★★ |
| 社区生态 | ★★☆☆☆ | ★★★★★ |
| 学习曲线 | ★★★☆☆ | ★★★★☆ |

### 8.2 技术特点对比

```
Decima vs Unreal Engine 5:

Decima 优势:
├── 专门优化的开放世界渲染
├── 卓越的植被系统
├── 高效的流式加载
└── PlayStation 平台深度优化

UE5 优势:
├── Nanite 虚拟几何体
├── Lumen 全局光照
├── 强大的蓝图系统
├── 庞大的资产生态
└── 全平台支持
```

### 8.3 与其他引擎对比

| 引擎 | 代表作 | 特点 |
|------|--------|------|
| Decima | Horizon, Death Stranding | 开放世界植被, PS优化 |
| UE5 | 黑神话悟空, 幻兽帕鲁 | 通用性强, 生态完善 |
| RE Engine | 生化危机, 鬼泣 | 高效率, 快速迭代 |
| Frostbite | 战地, FIFA | 破坏系统, 大规模场景 |
| REDengine | 赛博朋克2077 | 城市渲染, 光照系统 |

---

## 9. 技术参考资源

### 9.1 GDC 演讲

1. **Creating a Tools Pipeline for Horizon: Zero Dawn** (GDC 2017)
   - Guerrilla Games 的工具链开发

2. **GPU-Based Run-Time Procedural Placement in Horizon: Zero Dawn** (GDC 2017)
   - GPU 程序化植被放置系统

3. **Between Tech and Art: The Vegetation of Horizon Zero Dawn** (GDC 2018)
   - 植被渲染技术与美术工作流

4. **Evolution of the Decima Engine from Killzone to Horizon Zero Dawn** (4C Conference)
   - 引擎演进历史

5. **HTN Planning in the Decima Engine** (AI and Games Conference 2024)
   - AI 规划系统实现

### 9.2 技术文档

- [Decima Engine - Wikipedia](https://en.wikipedia.org/wiki/Decima_(game_engine))
- [Death Stranding 2 - Wikipedia](https://en.wikipedia.org/wiki/Death_Stranding_2)
- [Jolt Physics - GitHub](https://github.com/jrouwe/JoltPhysics)
- [PlayStation 5 Pro 官方页面](https://www.playstation.com/ps5/ps5-pro/)

### 9.3 推荐视频

1. **"Why Decima Is One of the Best Graphics Engines Ever Built"** - GamingBolt
2. **"The Most Impressive Game Engine"** - Major_Trenton
3. **"Horizon Forbidden West PS5 Trailer Analysis: The Decima Engine Evolves!"** - Digital Foundry

---

## 10. 总结与启示

### 10.1 技术亮点总结

1. **开放世界渲染**: Decima 在大规模开放世界场景渲染方面处于行业领先地位
2. **植被系统**: GPU 程序化放置与渲染是其核心竞争优势
3. **流式加载**: 针对 SSD 优化的资产流式系统实现无缝世界
4. **AI 系统**: HTN 规划系统提供了灵活且高效的 AI 行为设计
5. **平台优化**: 深度利用 PlayStation 硬件特性，包括 PSSR

### 10.2 对游戏开发的启示

#### 10.2.1 架构设计

```
借鉴要点:
1. 模块化架构设计
   - 核心系统与平台抽象分离
   - 便于移植和维护

2. 数据驱动设计
   - 编辑器优先的工作流
   - 美术友好的工具链

3. 多线程优化
   - Job System 任务调度
   - 充分利用多核 CPU
```

#### 10.2.2 渲染技术

```
可学习的技术:
1. 延迟渲染优化
   - G-Buffer 压缩
   - 光照剔除优化

2. 植被渲染
   - GPU 程序化放置
   - 实例化渲染优化
   - 距离 Fade 技术

3. 流式加载
   - 虚拟纹理
   - LOD 动态切换
   - 预取策略
```

#### 10.2.3 工具链

```
开发效率提升:
1. 所见即所得编辑器
2. 实时预览与调试
3. 版本控制集成
4. 自动化资产处理
```

### 10.3 未来展望

Decima 引擎代表了 AAA 游戏引擎的一种发展方向：

- **专用化**: 针对特定类型游戏深度优化
- **平台优化**: 充分利用目标平台硬件特性
- **工作流优化**: 提升开发效率与团队协作

死亡搁浅2 展示了如何在一个成熟的引擎基础上持续迭代创新，为游戏开发者提供了宝贵的技术参考。

---

## 附录

### A. 术语表

| 术语 | 全称 | 解释 |
|------|------|------|
| PSSR | PlayStation Spectral Super Resolution | 索尼 AI 超分辨率技术 |
| HTN | Hierarchical Task Network | 层次任务网络 AI 规划 |
| LOD | Level of Detail | 细节层次 |
| TAA | Temporal Anti-Aliasing | 时间抗锯齿 |
| SSGI | Screen Space Global Illumination | 屏幕空间全局光照 |
| HLOD | Hierarchical Level of Detail | 层次细节 |

### B. 相关项目

如果你想深入了解游戏引擎开发，可以参考以下项目：

1. **Unreal Engine** - 开源学习的顶级引擎
2. **Godot** - 开源游戏引擎
3. **O3DE** - Amazon 开源引擎
4. **Jolt Physics** - Decima 使用的开源物理引擎

---

*本报告基于公开资料整理，仅供参考学习。*
