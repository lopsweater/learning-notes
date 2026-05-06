# DX12 GPU Work Graphs 深度调研报告

> 调研时间: 2026-05-06  
> 目标: 系统性理解 GPU Work Graphs 的设计理念、核心概念、API 使用和应用场景

---

## 一、概述

### 1.1 什么是 Work Graph

**Work Graphs** 是 D3D12 中的一种 **GPU 自主工作创建系统**。它允许 GPU 上的着色器线程（生产者）直接请求执行其他工作（消费者），而无需回传到 CPU。

传统模式：
```
CPU --[Dispatch]--> GPU Compute --[回传结果]--> CPU --[下一个Dispatch]--> GPU
```

Work Graphs 模式：
```
CPU --[DispatchGraph]--> GPU Node A --[直接触发]--> Node B --[直接触发]--> Node C
                                                   └--> Node D
```

### 1.2 为什么需要 Work Graphs

**传统问题**：
- ❌ GPU 产生的工作需要 CPU 回传才能执行
- ❌ `ExecuteIndirect` 串行处理，效率受限
- ❌ 多 Pass 算法需要显式同步，GPU 空闲等待
- ❌ 最坏情况缓冲分配，内存浪费

**Work Graphs 优势**：
- ✅ GPU 直接生成和消费工作，零 CPU 往返
- ✅ 异步调度，最大化 GPU 利用率
- ✅ 系统管理中间数据内存，简化编程模型
- ✅ 数据流保持缓存局部性，减少内存带宽压力

### 1.3 适用场景

| 场景 | 描述 |
|------|------|
| 多 Pass 计算 | 减少 Pass 之间的内存回写和 GPU 空闲 |
| 动态工作扩展 | GPU 决定实际工作量和类型 |
| 分类/装箱 | 动态分发到不同的处理节点 |
| 分层算法 | 如 BVH 遍历、八叉树处理 |
| 图形-计算融合 | Compute 驱动 Mesh Shader (未来) |

---

## 二、核心概念

### 2.1 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                      Work Graph                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│  │ Node A  │───>│ Node B  │───>│ Node C  │    │ Node D  │   │
│  │[Entry]  │    │         │    │[Leaf]   │    │[Leaf]   │   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│       │              │              ↑              ↑        │
│       │              └──────────────┘──────────────┘        │
│       │                    Records 流动                      │
│       │                                                    │
│  ┌────┴────┐                                               │
│  │Backing  │  ← 系统管理的数据缓冲区                        │
│  │Memory   │                                                │
│  └─────────┘                                               │
└─────────────────────────────────────────────────────────────┘
        ↑
        │ DispatchGraph()
   ┌────┴────┐
   │ Command │
   │  List   │
   └─────────┘
```

### 2.2 关键定义

#### Node（节点）
- 图的基本构建块
- 每个节点关联一个着色器或完整图形程序
- 定义了输入记录类型和处理方式

#### Record（记录）
- 节点之间传递的数据单元
- 固定大小（由着色器声明）
- 可以包含任意数据 + 可选的 DispatchGrid

#### Graph（图）
- 有向无环图（DAG），**除了自递归**
- 递归深度限制：32层
- 保证工作完成，无死锁

#### Program（程序）
- D3D12 的新概念，替代"Pipeline State"
- Work Graph 本身就是一种 Program Type

---

## 三、节点类型详解 ★★★

### 3.1 Broadcasting Launch Nodes（广播启动节点）

**特性**：一个输入记录触发一个完整的 Dispatch Grid

```
输入记录 (包含 DispatchGrid)
    │
    ▼
┌─────────────────────────┐
│  ThreadGroup Grid       │
│  (DispatchGrid.x ×      │
│   DispatchGrid.y ×      │
│   DispatchGrid.z)       │
│                         │
│  所有 ThreadGroup 共享   │
│  同一个输入记录          │
└─────────────────────────┘
```

**适用场景**：
- 数据放大（一个输入 → 多个处理单元）
- 需要跨 ThreadGroup 协作的处理
- 替代传统的 Compute Shader Dispatch

**HLSL 声明**：
```hlsl
struct InputRecord {
    uint3 grid : SV_DispatchGrid;  // 动态 Grid 大小
    float4 data;
};

[Shader("node")]
[NodeLaunch("broadcasting")]
[NodeMaxDispatchGrid(256, 256, 1)]  // 最大 Grid 声明
[NumThreads(8, 8, 1)]
void MyBroadcastNode(
    DispatchNodeInputRecord<InputRecord> input,
    [MaxRecords(2)] NodeOutput<OutputRecord> output
) {
    // 所有 ThreadGroup 共享同一 input
    uint3 tid = DispatchThreadID;
    // ...
}
```

**固定 Grid 变体**：
```hlsl
[Shader("node")]
[NodeLaunch("broadcasting")]
[NodeDispatchGrid(64, 64, 1)]  // 固定 Grid
[NumThreads(8, 8, 1)]
void FixedGridNode(/* ... */) { }
```

---

### 3.2 Coalescing Launch Nodes（合并启动节点）

**特性**：多个输入记录被合并到一个 ThreadGroup 处理

```
输入队列: [Rec0] [Rec1] [Rec2] [Rec3] [Rec4] [Rec5] ...
              │
              ▼
         ┌────┴────┐
         │ 系统决定 │  ← 1 到 MaxRecords
         │ 合并数量 │
         └────┬────┘
              │
              ▼
┌─────────────────────────┐
│  一个 ThreadGroup       │
│  处理 [0..N] 个记录     │
│                         │
│  GroupNodeInputRecords  │ ← 数组访问
│  [索引].data            │
└─────────────────────────┘
```

**适用场景**：
- 批处理优化（合并多个小任务）
- ThreadGroup 内协作处理多个输入
- 输出记录限制比 Thread Launch 宽松

**HLSL 声明**：
```hlsl
[Shader("node")]
[NodeLaunch("coalescing")]
[NumThreads(32, 1, 1)]
void MyCoalescingNode(
    [MaxRecords(64)] GroupNodeInputRecords<InputRecord> inputs  // 最多64个
) {
    uint count = inputs.Count();  // 实际收到的记录数
    
    // 手动分配工作给线程
    for (uint i = GroupIndex; i < count; i += 32) {
        ProcessRecord(inputs[i]);
    }
}
```

**重要特性**：
- 记录数量实现定义（1 到 MaxRecords）
- 不可重复（相同输入可能产生不同分组）
- 必须调用 `Count()` 获取实际数量

---

### 3.3 Thread Launch Nodes（线程启动节点）

**特性**：每个输入记录触发一个线程（类似 Callable Shader 但不返回）

```
输入记录 ──> 单个线程 (1×1×1 ThreadGroup)
```

**适用场景**：
- 独立任务处理
- 小粒度工作分发
- 类似 DXR Callable Shader 的工作模式

**HLSL 声明**：
```hlsl
[Shader("node")]
[NodeLaunch("thread")]
void MyThreadNode(
    ThreadNodeInputRecord<InputRecord> input
) {
    // 单线程处理
    // 无需 NumThreads 属性
    // ThreadGroup 大小固定为 (1,1,1)
}
```

**Wave 打包优势**：
- 不同 Thread Launch 的线程可被打包到同一 Wave
- 提高硬件利用率

---

### 3.4 节点类型对比表

| 特性 | Broadcasting | Coalescing | Thread |
|------|--------------|------------|--------|
| 输入→线程关系 | 1→Grid | N→Group | 1→Thread |
| ThreadGroup 大小 | 声明指定 | 声明指定 | 固定(1,1,1) |
| Dispatch Grid | 支持 | 不适用 | 不适用 |
| 输入可见性 | 所有 TG 共享 | Group 内可见 | 单线程 |
| 输出记录限制 | 最宽松 | 中等 | 最严格 |
| Wave 打包 | 否 | 否 | 是 |
| 典型用途 | 放大/并行 | 批处理 | 独立任务 |

---

## 四、HLSL 语法详解

### 4.1 Shader Function Attributes（着色器函数属性）

```hlsl
[Shader("node")]                                    // 必需：声明节点着色器
[NodeLaunch("broadcasting"|"coalescing"|"thread")]  // 必需：启动类型
[NumThreads(x, y, z)]                              // 必需（Thread Launch 除外）
[NodeID("name", arrayIndex)]                       // 可选：节点 ID（默认为函数名）
[NodeIsProgramEntry]                               // 可选：标记为入口点
[NodeLocalRootArgumentsTableIndex(index)]          // 可选：Local Root Signature 索引
[NodeShareInputOf("otherNode")]                    // 可选：共享输入
[NodeMaxRecursionDepth(depth)]                     // 可选：递归深度
[NodeDispatchGrid(x, y, z)]                       // 固定 Grid
[NodeMaxDispatchGrid(x, y, z)]                     // 动态 Grid 的最大值
```

### 4.2 Record Struct（记录结构）

```hlsl
struct MyRecord {
    uint3 dispatchGrid : SV_DispatchGrid;  // 可选：用于 Broadcasting
    float4 payload;                         // 自定义数据
};

// 空记录（仅作为信号）
struct EmptyRecord {};
```

### 4.3 Node Input Declaration（节点输入声明）

```hlsl
// Broadcasting Launch
DispatchNodeInputRecord<RecordType> input;

// Coalescing Launch
[MaxRecords(64)] GroupNodeInputRecords<RecordType> inputs;

// Thread Launch
ThreadNodeInputRecord<RecordType> input;

// 可读写版本（Coalescing/Thread）
RWGroupNodeInputRecords<RecordType> inputs;
RWThreadNodeInputRecord<RecordType> input;
RWDispatchNodeInputRecord<RecordType> input;  // Broadcasting
```

### 4.4 Node Output Declaration（节点输出声明）

```hlsl
// 单一输出
[MaxRecords(5)] NodeOutput<RecordType> output;

// 输出数组（用于动态分发）
[MaxRecords(5)] [NodeArraySize(16)] NodeOutput<RecordType> outputArray;

// 空输出（仅信号）
EmptyNodeOutput emptyOutput;
EmptyNodeOutput[16] emptyOutputArray;  // 数组版本
```

### 4.5 Output Operations（输出操作）

```hlsl
// Thread 级别输出（每线程独立）
ThreadNodeOutputRecords<RecordType> outRec = 
    output.GetThreadNodeOutputRecords(count);

// Group 级别输出（组共享）
GroupNodeOutputRecords<RecordType> outRec = 
    output.GetGroupNodeOutputRecords(count);

// 写入数据
outRec[0].payload = data;

// 完成输出（必须调用）
outRec.OutputComplete();

// 空输出
emptyOutput.GroupIncrementOutputCount(1);  // 信号量+1
```

---

## 五、API 接口详解

### 5.1 创建 Work Graph

```cpp
// 1. 编译 Shader (lib_6_8+)
// 使用 DXC 编译节点着色器到库目标

// 2. 创建 State Object
D3D12_STATE_SUBOBJECT subobjects[4];

// DXIL Library
D3D12_SHADER_BYTECODE shaderByteCode = { library->GetBufferPointer(), 
                                          library->GetBufferSize() };
D3D12_DXIL_LIBRARY_DESC dxilLibrary = { shaderByteCode, 0, nullptr };
subobjects[0] = { D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY, &dxilLibrary };

// Global Root Signature
D3D12_GLOBAL_ROOT_SIGNATURE globalRootSig = { rootSignature };
subobjects[1] = { D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_ROOT_SIGNATURE, &globalRootSig };

// Work Graph Description
D3D12_WORK_GRAPH_DESC workGraphDesc = {
    L"MyWorkGraph",                                    // Program Name
    D3D12_WORK_GRAPH_FLAG_INCLUDE_ALL_AVAILABLE_NODES, // Flags
    0, 0, nullptr, nullptr                              // 可选覆盖
};
subobjects[2] = { D3D12_STATE_SUBOBJECT_TYPE_WORK_GRAPH, &workGraphDesc };

// State Object Config
D3D12_STATE_OBJECT_CONFIG config = { D3D12_STATE_OBJECT_FLAG_ALLOW_LOCAL_DEPENDENCIES_ON_EXTERNAL_DEFINITIONS };
D3D12_STATE_SUBOBJECT configSubobject = { D3D12_STATE_SUBOBJECT_TYPE_STATE_OBJECT_CONFIG, &config };
subobjects[3] = configSubobject;

// Create
D3D12_STATE_OBJECT_DESC stateObjectDesc = {
    D3D12_STATE_OBJECT_TYPE_EXECUTABLE,
    _countof(subobjects), subobjects
};
device->CreateStateObject(&stateObjectDesc, IID_PPV_ARGS(&stateObject));
```

### 5.2 查询 Work Graph 属性

```cpp
ID3D12WorkGraphProperties* workGraphProps;
stateObject->QueryInterface(IID_PPV_ARGS(&workGraphProps));

// 获取 Work Graph 索引
UINT graphIndex = workGraphProps->GetWorkGraphIndex(L"MyWorkGraph");

// 查询内存需求
D3D12_WORK_GRAPH_MEMORY_REQUIREMENTS memReqs;
workGraphProps->GetWorkGraphMemoryRequirements(graphIndex, &memReqs);

// memReqs.MinSizeInBytes  - 最小需求
// memReqs.MaxSizeInBytes  - 最大可用
// memReqs.SizeGranularityInBytes - 粒度

// 分配 Backing Memory
ID3D12Resource* backingMemory;
D3D12_HEAP_PROPERTIES heapProps = { D3D12_HEAP_TYPE_DEFAULT };
D3D12_RESOURCE_DESC resDesc = {
    D3D12_RESOURCE_DIMENSION_BUFFER, 0,
    memReqs.MinSizeInBytes, 1, 1, 1,
    DXGI_FORMAT_UNKNOWN, {1, 0},
    D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
    D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS
};
device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
    &resDesc, D3D12_RESOURCE_STATE_COMMON, nullptr,
    IID_PPV_ARGS(&backingMemory));
```

### 5.3 设置 Program 并分发工作

```cpp
ID3D12StateObjectProperties1* stateObjProps;
stateObject->QueryInterface(IID_PPV_ARGS(&stateObjProps));

// 获取 Program Identifier
D3D12_PROGRAM_IDENTIFIER programId = 
    stateObjProps->GetProgramIdentifier(L"MyWorkGraph");

// 设置 Program
D3D12_SET_PROGRAM_DESC setProgram = {};
setProgram.Type = D3D12_PROGRAM_TYPE_WORK_GRAPH;
setProgram.WorkGraph.ProgramIdentifier = programId;
setProgram.WorkGraph.Flags = D3D12_SET_WORK_GRAPH_FLAG_INITIALIZE;
setProgram.WorkGraph.BackingMemory = {
    backingMemory->GetGPUVirtualAddress(),
    memReqs.MinSizeInBytes
};
commandList->SetProgram(&setProgram);

// 分发工作（从 CPU）
struct InputData { uint3 grid; float4 payload; };
InputData inputData = { {4, 4, 1}, {1.0f, 2.0f, 3.0f, 4.0f} };

D3D12_NODE_CPU_INPUT nodeInput = {};
nodeInput.EntrypointIndex = 0;  // 入口点索引
nodeInput.NumRecords = 1;
nodeInput.pRecords = &inputData;

D3D12_DISPATCH_GRAPH_DESC dispatch = {};
dispatch.Mode = D3D12_DISPATCH_MODE_NODE_CPU_INPUT;
dispatch.Command = { (UINT64)&nodeInput, 1 };
commandList->DispatchGraph(&dispatch);
```

### 5.4 从 GPU 分发（ExecuteIndirect 模式）

```cpp
// 在 GPU 上准备输入数据
// 使用 UAV 或其他方式填充 GPU 缓冲区

D3D12_NODE_GPU_INPUT gpuInput = {};
gpuInput.EntrypointIndex = 0;
gpuInput.NumRecords = recordCount;
gpuInput.pRecords = gpuBuffer->GetGPUVirtualAddress();

D3D12_DISPATCH_GRAPH_DESC dispatch = {};
dispatch.Mode = D3D12_DISPATCH_MODE_NODE_GPU_INPUT;
dispatch.Command = { (UINT64)&gpuInput, 1 };
commandList->DispatchGraph(&dispatch);
```

---

## 六、完整代码示例

### 6.1 简单的 Work Graph 示例

**HLSL (lib_6_8):**
```hlsl
// 定义输出记录结构
struct PassThroughRecord {
    uint3 grid : SV_DispatchGrid;
    float4 color;
};

// 入口节点：广播启动
[Shader("node")]
[NodeLaunch("broadcasting")]
[NodeMaxDispatchGrid(16, 16, 1)]
[NumThreads(8, 8, 1)]
[NodeIsProgramEntry]
[NodeID("EntryPoint")]
void EntryPointNode(
    DispatchNodeInputRecord<PassThroughRecord> input,
    [MaxRecords(8)] NodeOutput<PassThroughRecord> output
) {
    uint3 tid = DispatchThreadID;
    uint3 gridSize = input.Get().grid;
    
    if (all(tid < gridSize)) {
        // 创建输出记录
        ThreadNodeOutputRecords<PassThroughRecord> outRec = 
            output.GetThreadNodeOutputRecords(1);
        
        outRec[0].grid = uint3(1, 1, 1);
        outRec[0].color = input.Get().color * float4(tid.xy / 16.0, 0, 1);
        outRec.OutputComplete();
    }
}

// 处理节点：线程启动
[Shader("node")]
[NodeLaunch("thread")]
[NodeID("Processor")]
void ProcessorNode(
    ThreadNodeInputRecord<PassThroughRecord> input,
    RWByteAddressBuffer outputBuffer : register(u0)
) {
    // 将颜色写入 UAV
    uint idx = input.Get().color.x * 255;  // 简化示例
    outputBuffer.Store4(idx * 16, asuint(input.Get().color));
}
```

**C++ 端:**
```cpp
// 参考 WorkGraphsDemo.cpp 的完整流程
// 1. 编译 HLSL (lib_6_8)
// 2. 创建 State Object
// 3. 查询内存需求
// 4. 分配 Backing Memory
// 5. SetProgram + DispatchGraph
```

---

## 七、内存管理模型

### 7.1 Backing Memory

Work Graphs 使用系统管理的内存来存储：
- 节点间的记录队列
- 调度元数据
- 输出预留空间

**应用职责**：
- 查询需求大小 (`GetWorkGraphMemoryRequirements`)
- 分配并绑定 GPU 缓冲区
- 在 `SetProgram` 时指定

### 7.2 输出空间预留

节点执行前，系统预留其**最坏情况输出空间**：
```hlsl
// 每个输出端口的最大记录数
[MaxRecords(16)] NodeOutput<RecordType> output;

// 系统预留空间 = 16 × sizeof(RecordType)
```

**优化提示**：
- 声明准确的 `MaxRecords`
- 使用 `EmptyNodeOutput` 当仅需信号

### 7.3 输入记录共享

多个节点可共享同一输入：
```hlsl
// Node A 共享 Node B 的输入
[NodeShareInputOf("NodeB")]
void NodeA(/* ... */) { }

// Node B 正常声明
void NodeB([MaxRecords(64)] GroupNodeInputRecords<Rec> inputs) { }

// 两个节点处理同一批输入，但执行不同逻辑
```

---

## 八、高级特性

### 8.1 节点数组

用于动态分发：
```hlsl
// 输出数组声明
[MaxRecords(4)] [NodeArraySize(8)] 
NodeOutput<BinRecord> binOutput;

// 动态索引
uint binIndex = ComputeBin(data);
NodeOutput<BinRecord> targetBin = binOutput[binIndex];
targetBin.GetThreadNodeOutputRecords(1)[0].data = data;
```

### 8.2 递归

节点可以输出到自身：
```hlsl
[Shader("node")]
[NodeLaunch("thread")]
[NodeMaxRecursionDepth(16)]  // 最大递归深度
void RecursiveNode(
    ThreadNodeInputRecord<Record> input,
    [MaxRecords(1)] NodeOutput<Record> selfOutput,  // 自引用
    [MaxRecords(1)] NodeOutput<Record> finalOutput
) {
    if (input.Get().depth > 0) {
        // 递归处理
        auto rec = selfOutput.GetThreadNodeOutputRecords(1);
        rec[0].depth = input.Get().depth - 1;
        rec.OutputComplete();
    } else {
        // 最终输出
        auto out = finalOutput.GetThreadNodeOutputRecords(1);
        out[0].result = input.Get().result;
        out.OutputComplete();
    }
}
```

### 8.3 同步（Join）

Work Graphs 目前**不直接支持**传统意义上的同步（等待多个输入）。

**变通方案**：
1. **分层图**：将需要同步的部分拆分为单独的图
2. **计数器**：使用 UAV 原子计数器实现
3. **Shader 逻辑**：手动跟踪完成状态

### 8.4 Graphics Nodes（实验性）

未来支持 Mesh Shader 作为叶节点：
```hlsl
[Shader("node")]
[NodeLaunch("mesh")]
[NodeDispatchGrid(64, 1, 1)]  // Meshlet 数量
[NumThreads(32, 1, 1)]
void MeshNode(
    DispatchNodeInputRecord<MeshInput> input,
    OutputIndices<uint3> indices,
    OutputVertices<Vertex> vertices,
    OutputPrimitives<Triangle> primitives
) {
    // Mesh Shader 逻辑
}
```

---

## 九、与其他技术对比

### 9.1 vs ExecuteIndirect

| 维度 | ExecuteIndirect | Work Graphs |
|------|-----------------|-------------|
| 工作生成 | 串行处理命令缓冲 | 并行工作队列 |
| Shader 选择 | 固定 | 节点可变 |
| 内存管理 | 应用手动管理 | 系统可管理 |
| 灵活性 | 受限 | 高度灵活 |
| 性能 | 串行瓶颈 | 并行调度 |
| 复杂度 | 中等 | 较高 |

### 9.2 vs Mesh Shader Amplification

| 维度 | Amplification Shader | Work Graphs |
|------|---------------------|-------------|
| 目标 | 仅图形 | 通用计算 + 图形 |
| 输出 | Mesh Shader 调用 | 任意节点 |
| 放大倍数 | 相对固定 | 动态灵活 |
| 中间数据 | 无持久化 | 可跨节点传递 |

### 9.3 vs DXR Callable Shaders

| 维度 | Callable Shaders | Work Graphs (Thread Launch) |
|------|------------------|------------------------------|
| 执行模型 | 返回调用者 | 不返回 |
| 调用开销 | 较高 | 较低 |
| 适用场景 | Raytracing | 通用计算 |

---

## 十、决策建议

### 10.1 何时使用 Work Graphs

✅ **推荐场景**：
- 多 Pass 算法，Pass 间数据量动态变化
- GPU 需要动态决定下一步工作
- 分类/装箱场景
- 层次化数据处理
- 需要 GPU 自主工作扩展

❌ **不推荐场景**：
- 简单的固定工作负载
- 需要 CPU 参与决策的流程
- 已有成熟的 ExecuteIndirect 方案且性能足够

### 10.2 节点类型选择

| 你的需求 | 推荐类型 |
|---------|---------|
| 一个输入触发大量并行处理 | Broadcasting |
| 需要批处理多个小任务 | Coalescing |
| 每个输入独立处理，无需协作 | Thread |
| 需要跨 ThreadGroup 协作 | Broadcasting |

### 10.3 性能优化建议

1. **精确声明 MaxRecords**：过大会浪费内存预留
2. **使用 EmptyNodeOutput**：当只需信号量时
3. **合理设计图拓扑**：减少不必要的中间节点
4. **利用共享输入**：减少数据复制
5. **考虑 Wave 打包**：Thread Launch 有优势

---

## 十一、学习路径

### 阶段 1：基础概念（第1-2周）
- [ ] 理解 GPU 自主工作创建的动机
- [ ] 掌握 Node、Record、Graph 核心概念
- [ ] 区分三种节点类型的语义差异

### 阶段 2：HLSL 语法（第3-4周）
- [ ] 编写简单的 Broadcasting Launch 节点
- [ ] 实现节点间数据传递
- [ ] 掌握输入/输出记录操作

### 阶段 3：API 集成（第5-6周）
- [ ] 创建 State Object
- [ ] 配置 Backing Memory
- [ ] 实现 DispatchGraph 调用

### 阶段 4：高级应用（第7-8周）
- [ ] 实现节点数组动态分发
- [ ] 探索递归模式
- [ ] 优化性能瓶颈

---

## 十二、参考资源

### 官方文档
1. **Microsoft DirectX-Specs**: https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md
2. **Microsoft Learn**: https://learn.microsoft.com/en-us/windows/win32/direct3d12/work-graphs

### 示例代码
1. **Work-Graphs-Minimal-Example**: https://github.com/przemyslawzaworski/Work-Graphs-Minimal-Example
2. **DirectX-Graphics-Samples**: https://github.com/microsoft/DirectX-Graphics-Samples (待更新)

### 编译器
- **DXC**: 需要 2025+ 版本支持 `lib_6_8` 目标
- **DXIL**: Shader Model 6.8+

### 硬件要求
- **D3D12_WORK_GRAPHS_TIER**:
  - Tier 0: 不支持
  - Tier 1: 基本支持
  - Tier 2: 完整支持（含 Graphics Nodes）

---

## 附录：关键 API 速查

```cpp
// === State Object Creation ===
D3D12_STATE_OBJECT_TYPE_EXECUTABLE
D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY
D3D12_STATE_SUBOBJECT_TYPE_WORK_GRAPH
D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_ROOT_SIGNATURE

// === Work Graph Properties ===
ID3D12WorkGraphProperties::GetWorkGraphIndex()
ID3D12WorkGraphProperties::GetWorkGraphMemoryRequirements()
ID3D12WorkGraphProperties::GetNumEntrypoints()
ID3D12WorkGraphProperties::GetEntrypointRecordSizeInBytes()

// === Program Management ===
ID3D12StateObjectProperties1::GetProgramIdentifier()
ID3D12GraphicsCommandList10::SetProgram()
D3D12_PROGRAM_TYPE_WORK_GRAPH

// === Dispatch ===
ID3D12GraphicsCommandList10::DispatchGraph()
D3D12_DISPATCH_MODE_NODE_CPU_INPUT
D3D12_DISPATCH_MODE_NODE_GPU_INPUT
D3D12_DISPATCH_MODE_MULTI_NODE_CPU_INPUT
D3D12_DISPATCH_MODE_MULTI_NODE_GPU_INPUT
```

---

> 本报告基于 DirectX-Specs WorkGraphs.md v1.012 (2026-02-04) 撰写
