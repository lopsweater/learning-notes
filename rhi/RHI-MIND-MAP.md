# RHI 学习思维导图

```
                                ┌─────────────────────────────────────┐
                                │              RHI 核心                │
                                │      (渲染硬件接口抽象层)            │
                                └─────────────────┬───────────────────┘
                                                  │
        ┌────────────────┬────────────────┬───────┴───────┬────────────────┐
        ▼                ▼                ▼               ▼                ▼
  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ 设计理念  │    │  后端    │    │ 设计模式  │    │ 常见挑战  │    │ 参考资料  │
  └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
       │               │               │               │               │
       ▼               ▼               ▼               ▼               ▼
```

---

## 一、RHI 设计理念 🎯

```
RHI 设计理念
│
├── 1. 抽象层设计
│   ├── 三层模型
│   │   ├── Layer 3: 高级渲染抽象 (Mesh/Material/Scene)
│   │   ├── Layer 2: RHI 核心抽象 (Device/Buffer/Pipeline)
│   │   └── Layer 1: 原生 API (D3D12/Vulkan/Metal)
│   │
│   ├── 核心接口
│   │   ├── RHIDevice      → 资源工厂
│   │   ├── RHIBuffer      → 缓冲区抽象
│   │   ├── RHITexture     → 纹理抽象
│   │   ├── RHIPipeline    → 管线抽象
│   │   └── RHICommandList → 命令列表抽象
│   │
│   └── 设计原则
│       ├── 最小抽象原则 → 只抽象必要差异
│       ├── 显式优于隐式 → 资源生命周期显式管理
│       ├── 零成本抽象   → 无运行时开销
│       └── 错误尽早暴露 → 参数验证在调用时
│
├── 2. 资源模型 ★重要
│   ├── 资源类型
│   │   ├── Buffer (顶点/索引/常量/Storage)
│   │   └── Texture (1D/2D/3D/Cube/Array)
│   │
│   ├── 内存类型
│   │   ├── Default  → GPU 专属，最快
│   │   ├── Upload   → CPU 可写，上传用
│   │   └── Readback → CPU 可读，回读用
│   │
│   └── 资源视图
│       ├── CBV (常量缓冲视图)
│       ├── SRV (着色器资源视图)
│       ├── UAV (无序访问视图)
│       ├── RTV (渲染目标视图)
│       └── DSV (深度模板视图)
│
├── 3. 命令模型 ★重要
│   ├── 命令队列类型
│   │   ├── Graphics → 图形/计算/复制
│   │   ├── Compute  → 计算/复制
│   │   └── Copy     → 仅复制
│   │
│   ├── 命令流程
│   │   └── Open → Record → Close → Submit → Wait
│   │
│   └── 命令类型
│       ├── 绘制命令 (Draw/DrawIndexed/DrawInstanced)
│       ├── 计算命令 (Dispatch)
│       └── 复制命令 (CopyBuffer/CopyTexture)
│
├── 4. 同步模型 ★核心难点
│   ├── 同步原语
│   │   ├── Fence     → CPU 等待 GPU
│   │   └── Semaphore → GPU 等待 GPU
│   │
│   ├── 帧同步策略
│   │   └── 三缓冲: Frame[N] → Fence → Wait → Signal
│   │
│   └── 跨队列同步
│       └── Queue A Signal → Queue B Wait
│
└── 5. 跨平台策略
    ├── 特性检测 → IsFeatureSupported()
    ├── 回退机制 → 自动回退/功能模拟
    └── 平台扩展 → 条件编译/虚函数扩展
```

---

## 二、D3D12 重点 ★★★

```
D3D12 (DirectX 12)
│
├── 1. 核心特性 ★必须掌握
│   │
│   ├── Root Signature (根签名) ★核心概念
│   │   │
│   │   ├── Root Parameter 类型
│   │   │   ├── Descriptor Table → 指向描述符表 (1 DWORD)
│   │   │   ├── Root CBV        → 直接 GPU 地址 (2 DWORD)
│   │   │   ├── Root Constants  → 内联常量 (1 DWORD/常量)
│   │   │   └── 最大 64 DWORD
│   │   │
│   │   └── 创建流程
│   │       └── 定义参数 → 序列化 → CreateRootSignature
│   │
│   ├── Descriptor Heap (描述符堆) ★核心概念
│   │   │
│   │   ├── 堆类型
│   │   │   ├── CBV_SRV_UAV → 常量/着色器资源/UAV
│   │   │   ├── SAMPLER     → 采样器
│   │   │   ├── RTV         → 渲染目标
│   │   │   └── DSV         → 深度模板
│   │   │
│   │   ├── Shader 可见性
│   │   │   ├── Shader Visible   → GPU 直接访问
│   │   │   └── Non-Shader Visible → 仅 CPU 端
│   │   │
│   │   └── 描述符大小
│   │       └── GetDescriptorHandleIncrementSize()
│   │
│   ├── Pipeline State Object (PSO)
│   │   └── 包含: 着色器 + 混合 + 光栅化 + 深度 + 输入布局 + ...
│   │
│   ├── Resource Barrier (资源屏障) ★易错点
│   │   ├── Transition → 状态转换
│   │   ├── Aliasing  → 资源别名
│   │   └── UAV       → UAV 同步
│   │
│   └── Bundles (命令包)
│       └── 可重用的命令列表，适合频繁重复绘制
│
├── 2. 绑定模型 ★核心
│   │
│   ├── 步骤
│   │   ├── 1. 创建 Descriptor Heap
│   │   ├── 2. 创建 CBV/SRV/UAV
│   │   ├── 3. SetDescriptorHeaps
│   │   ├── 4. SetGraphicsRootDescriptorTable
│   │   └── 或 SetGraphicsRootConstantBufferView
│   │
│   └── 性能提示
│       ├── Descriptor Table → 多变资源 (纹理数组)
│       ├── Root CBV       → 频繁更新 (Per-Object)
│       └── Root Constants → 小数据 (4-16 个 32-bit)
│
├── 3. 内存模型
│   │
│   ├── 堆类型
│   │   ├── DEFAULT  → GPU 专属
│   │   ├── UPLOAD   → CPU 上传
│   │   ├── READBACK → CPU 回读
│   │   └── CUSTOM   → 自定义
│   │
│   ├── 资源放置
│   │   ├── Committed Resource → 自动分配堆
│   │   └── Placed Resource    → 手动指定堆偏移
│   │
│   └── Residency (驻留管理)
│       ├── MakeResident → 使资源驻留显存
│       └── Evict       → 驱逐资源释放显存
│
└── 4. 同步机制
    │
    ├── Fence 操作
    │   ├── Signal      → GPU 发送信号
    │   ├── Wait        → CPU 等待
    │   └── GetCompletedValue → 查询完成值
    │
    └── 帧同步模式
        ├── 每帧独立的 FenceValue
        ├── 提交后 Signal
        └── BeginFrame 时 Wait
```

---

## 三、Vulkan 重点 ★★★

```
Vulkan
│
├── 1. 核心特性 ★必须掌握
│   │
│   ├── Descriptor Set (描述符集) ★核心概念
│   │   │
│   │   ├── 结构
│   │   │   ├── Descriptor Set Layout → 定义绑定布局
│   │   │   ├── Descriptor Pool       → 分配描述符集
│   │   │   └── Descriptor Set        → 实际描述符集
│   │   │
│   │   ├── 绑定模型
│   │   │   ├── Set 0: Frame Data
│   │   │   ├── Set 1: Material Data
│   │   │   └── Set 2: Object Data
│   │   │
│   │   └── 更新方式
│   │       └── vkUpdateDescriptorSets
│   │
│   ├── Push Constants ★特色功能
│   │   ├── 快速更新小块数据
│   │   ├── 最大 128 bytes guaranteed
│   │   └── vkCmdPushConstants
│   │
│   ├── Render Pass + Subpass
│   │   ├── Render Pass  → 定义附件和子通道
│   │   └── Subpass      → 片上内存复用
│   │
│   └── Validation Layers ★调试利器
│       ├── 检测无效参数
│       ├── 检测资源生命周期问题
│       └── 检测同步问题
│
├── 2. 初始化流程 ★必须掌握
│   │
│   └── 流程
│       ├── 1. vkCreateInstance
│       ├── 2. vkEnumeratePhysicalDevices
│       ├── 3. vkGetPhysicalDeviceQueueFamilyProperties
│       ├── 4. vkCreateDevice
│       └── 5. vkGetDeviceQueue
│
├── 3. 图像布局转换 ★易错点
│   │
│   ├── 常见布局
│   │   ├── UNDEFINED                    → 初始
│   │   ├── COLOR_ATTACHMENT_OPTIMAL     → 颜色附件
│   │   ├── SHADER_READ_ONLY_OPTIMAL     → 着色器读取
│   │   ├── TRANSFER_DST_OPTIMAL         → 传输目标
│   │   └── PRESENT_SRC_KHR              → 呈现
│   │
│   └── Pipeline Barrier
│       ├── srcAccessMask / dstAccessMask
│       ├── oldLayout / newLayout
│       └── srcStageMask / dstStageMask
│
└── 4. 同步机制
    │
    ├── Fence
    │   ├── CPU 等待 GPU
    │   └── vkWaitForFences
    │
    ├── Semaphore
    │   ├── GPU 等待 GPU
    │   └── 跨队列同步
    │
    └── Timeline Semaphore (Vulkan 1.2+)
        └── 更灵活的同步模型
```

---

## 四、D3D12 vs Vulkan 关键对比 ★重要

```
                    D3D12                    Vulkan
                    ─────                    ──────
绑定模型:    Root Signature           Descriptor Set + Pipeline Layout
描述符:      Descriptor Heap          Descriptor Pool + Set
命令缓冲:    Command List             Command Buffer
同步:        Fence                    Fence + Semaphore
资源状态:    Resource Barrier         Image Memory Barrier
内存管理:    Heap + Resource          DeviceMemory + Buffer/Image
着色器:      HLSL                     SPIR-V
平台:        Windows Only             跨平台
调试:        PIX                      Validation Layers
```

---

## 五、设计模式 ★实战必备

```
设计模式
│
├── 1. 资源池模式
│   ├── 目的 → 复用资源，减少创建开销
│   ├── 实现 → Acquire / Release / Cleanup
│   └── 应用 → Constant Buffer、临时 Render Target
│
├── 2. 延迟销毁模式 ★必用
│   ├── 问题 → GPU 使用期间不能销毁
│   ├── 解决 → 帧延迟队列 (N 帧后销毁)
│   └── 实现 → Enqueue(resource, fenceValue) → Process()
│
├── 3. 状态追踪模式
│   ├── 问题 → 手动 Barrier 易错
│   ├── 解决 → 自动追踪资源状态
│   └── 实现 → GetState / SetState / GetTransitionBarriers
│
├── 4. 帧图模式
│   ├── 目的 → 自动管理资源生命周期
│   ├── 功能 → 资源别名 + 依赖分析
│   └── 流程 → CreatePass → Compile → Execute
│
├── 5. 渲染图模式
│   ├── 进阶 → 帧图 + 自动 Barrier
│   ├── 优点 → 自动状态转换
│   └── 使用 → AddPass(inputs, outputs, execute)
│
└── 6. 上传上下文
    ├── 目的 → 高效 CPU → GPU 数据传输
    ├── 实现 → Staging Buffer + 线性分配器
    └── 优化 → Copy Queue 异步上传
```

---

## 六、常见挑战与解决 ★避坑指南

```
常见挑战
│
├── 1. 同步危害 ★最常见
│   │
│   ├── 数据竞争
│   │   └── 解决 → Fence 同步 CPU/GPU
│   │
│   ├── 写后读 (RAW)
│   │   └── 解决 → Resource Barrier
│   │
│   └── 死锁
│       └── 解决 → 确保有向无环图 (DAG)
│
├── 2. 内存碎片
│   ├── 线性分配器 → 每帧重置，无碎片
│   ├── 池化分配器 → 固定大小块
│   └── 伙伴分配器 → 自动合并
│
├── 3. 资源别名
│   ├── 条件 → 生命周期不重叠
│   ├── 收益 → 节省 50%+ 显存
│   └── 注意 → 需要别名屏障
│
├── 4. 多线程渲染
│   ├── 每线程独立命令池
│   ├── 并行录制
│   └── 批量提交
│
└── 5. 性能优化
    ├── CPU → 批量提交 / 命令复用 / 多线程
    ├── GPU → 减少状态切换 / 实例化 / 间接绘制
    ├── 内存 → 资源压缩 / 别名 / 驻留管理
    └── 同步 → 最小化同步点 / 时间线 Semaphore
```

---

## 七、学习路径建议 📚

```
入门阶段
│
├── Week 1-2: 基础概念
│   ├── 理解 RHI 抽象层设计
│   ├── 学习 D3D12 或 Vulkan 基础
│   └── 完成一个简单渲染器
│
├── Week 3-4: 核心机制
│   ├── 深入理解绑定模型 (Root Signature / Descriptor Set)
│   ├── 掌握同步机制 (Fence / Semaphore)
│   └── 理解资源状态转换
│
进阶阶段
│
├── Week 5-6: 设计模式
│   ├── 实现延迟销毁队列
│   ├── 实现状态追踪器
│   └── 学习帧图/渲染图
│
├── Week 7-8: 性能优化
│   ├── 多线程命令录制
│   ├── 资源别名实践
│   └── 性能分析工具使用
│
高级阶段
│
└── 持续深入
    ├── 跨平台适配
    ├── 渲染图架构设计
    └── 与引擎集成
```

---

## 八、核心公式速查 📝

```
1. 帧同步
   FenceValue[frame] = ++counter
   Submit → Signal(fence, FenceValue[frame])
   BeginFrame → Wait(fence, FenceValue[frame])

2. 描述符偏移
   offset = index * DescriptorSize

3. 内存对齐
   alignedOffset = (offset + alignment - 1) & ~(alignment - 1)

4. Constant Buffer 对齐
   size = (size + 255) & ~255  // D3D12: 256 bytes

5. 资源生命周期判断
   if (lastUsePass_A < firstUsePass_B || lastUsePass_B < firstUsePass_A)
       → 可别名
```

---

## 九、调试工具速查 🔧

```
D3D12:
├── PIX                → https://devblogs.microsoft.com/pix/
├── NVIDIA Nsight      → https://developer.nvidia.com/nsight-graphics
└── RenderDoc          → https://renderdoc.org/

Vulkan:
├── Validation Layers  → 内置，启用即用
├── RenderDoc          → https://renderdoc.org/
├── Vulkan Configurator → https://vulkan.lunarg.com/
└── NVIDIA Nsight      → https://developer.nvidia.com/nsight-graphics
```

---

## 十、快速记忆口诀 💡

```
【RHI 设计原则】
最小抽象零成本，显式管理早暴露。

【D3D12 核心】
根签描述堆，屏障管线态。
RootSig 定绑定，Heap 存描述符。

【Vulkan 核心】
描述符集布局，推常最快速。
验证层调试，布局转换慎。

【同步要点】
Fence CPU 等，Semaphore GPU 同。
帧末才 Signal，帧首先 Wait。

【性能优化】
批量提交少调用，多线程录制并行。
状态排序减切换，资源别名省显存。
```

---

**重点标记说明：**
- ★ 必须掌握
- ★★★ 核心重点
- ★核心 核心概念
- ★重要 重要知识点
- ★易错点 容易出错
- ★必用 必须使用
- ★实战必备 实战必需
- ★避坑指南 避免踩坑
