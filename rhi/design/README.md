# RHI 设计理念

本目录记录 RHI 层的设计原则和抽象策略。

## 文件说明

| 文件 | 内容 |
|------|------|
| `abstraction-layers.md` | 硬件抽象层设计、API 差异封装 |
| `cross-platform.md` | 跨平台策略、特性检测、回退机制 |
| `resource-model.md` | 统一资源模型、Buffer/Texture 抽象 |
| `command-model.md` | 命令提交抽象、Command Buffer/List 封装 |
| `synchronization-model.md` | Fence/Semaphore 抽象、同步原语统一 |
| `memory-model.md` | 内存类型抽象、分配器接口、驻留管理 |

## RHI 抽象层级

```
┌────────────────────────────────────────────────────┐
│                   应用层 (Renderer)                 │
│   PBR、Shadow、PostProcess、UI、Particles...        │
└──────────────────────┬─────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────────┐
│                  高级抽象层 (High-Level)            │
│   Mesh、Material、Texture、Shader、FrameGraph...    │
└──────────────────────┬─────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────────┐
│                  RHI 层 (Core Abstraction)          │
│   Device、Buffer、Texture、Pipeline、CommandQueue   │
└──────────────────────┬─────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │ D3D12   │   │ Vulkan  │   │  Metal  │
   └─────────┘   └─────────┘   └─────────┘
```

## 设计原则

### 1. 最小抽象原则
- 只抽象**必要**的差异
- 暴露**底层控制权**给上层
- 避免**过度封装**导致性能损失

### 2. 显式优于隐式
- 资源生命周期**显式管理**
- 同步操作**显式指定**
- 状态转换**显式声明**

### 3. 零成本抽象
- 抽象层**无运行时开销**
- 编译期多态优于运行期多态
- 内联小函数，避免虚函数开销

### 4. 错误尽早暴露
- 参数验证在**调用时**进行
- 资源状态在**提交时**检查
- 调试层提供**详细错误信息**

## D3D12 vs Vulkan 差异对比

| 特性 | D3D12 | Vulkan | RHI 抽象 |
|------|-------|--------|----------|
| 描述符模型 | Descriptor Heap + Root Signature | Descriptor Set + Pipeline Layout | Descriptor Pool + Binding Layout |
| 命令提交 | Command List + Command Queue | Command Buffer + Queue | Command List + Command Queue |
| 同步 | Fence + Event | Fence + Semaphore + Event | Fence + Semaphore |
| 资源状态 | Resource Barrier | Image Memory Barrier | Resource Barrier |
| 内存管理 | Heap + Resource | Device Memory + Buffer/Image | Device Memory + Resource |
| 着色器 | HLSL | SPIR-V | Shader (统一编译) |

## 学习路径

1. 阅读 `abstraction-layers.md` 理解抽象层设计
2. 阅读 `resource-model.md` 理解资源抽象
3. 阅读 `command-model.md` 理解命令模型
4. 阅读 `synchronization-model.md` 理解同步模型
5. 阅读 `cross-platform.md` 理解跨平台策略
