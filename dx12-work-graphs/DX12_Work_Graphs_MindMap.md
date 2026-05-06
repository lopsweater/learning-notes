# DX12 GPU Work Graphs 思维导图

```
GPU Work Graphs
│
├── 1. 核心概念
│   ├── Node (节点)
│   │   ├── 计算节点 (Compute)
│   │   │   ├── Broadcasting Launch
│   │   │   ├── Coalescing Launch
│   │   │   └── Thread Launch
│   │   └── 图形节点 (Graphics) [实验性]
│   │       └── Mesh Launch
│   │
│   ├── Record (记录)
│   │   ├── 数据载体
│   │   ├── 固定大小
│   │   └── 可选 SV_DispatchGrid
│   │
│   ├── Graph (图)
│   │   ├── 有向无环图 (DAG)
│   │   ├── 允许自递归
│   │   └── 递归深度 ≤ 32
│   │
│   └── Program (程序)
│       └── Work Graph 是一种 Program Type
│
├── 2. 节点类型详解
│   │
│   ├── Broadcasting Launch (广播启动)
│   │   ├── 一个输入 → 一个 Dispatch Grid
│   │   ├── 所有 ThreadGroup 共享输入
│   │   ├── 支持 SV_DispatchGrid
│   │   │   ├── 固定: [NodeDispatchGrid(x,y,z)]
│   │   │   └── 动态: [NodeMaxDispatchGrid(x,y,z)]
│   │   ├── 输入: DispatchNodeInputRecord<T>
│   │   └── 适用: 数据放大、并行处理
│   │
│   ├── Coalescing Launch (合并启动)
│   │   ├── 多个输入 → 一个 ThreadGroup
│   │   ├── 系统决定合并数量 (1~MaxRecords)
│   │   ├── 必须调用 Count() 获取数量
│   │   ├── 输入: GroupNodeInputRecords<T>
│   │   └── 适用: 批处理、Group 内协作
│   │
│   └── Thread Launch (线程启动)
│       ├── 一个输入 → 一个线程
│       ├── ThreadGroup 大小固定 (1,1,1)
│       ├── 支持 Wave 打包优化
│       ├── 输入: ThreadNodeInputRecord<T>
│       └── 适用: 独立任务、细粒度分发
│
├── 3. 数据流模型
│   │
│   ├── 输入类型
│   │   ├── DispatchNodeInputRecord<T>   (只读，Broadcasting)
│   │   ├── GroupNodeInputRecords<T>      (只读，Coalescing)
│   │   ├── ThreadNodeInputRecord<T>      (只读，Thread)
│   │   ├── RWDispatchNodeInputRecord<T>  (读写)
│   │   ├── RWGroupNodeInputRecords<T>    (读写)
│   │   └── RWThreadNodeInputRecord<T>    (读写)
│   │
│   ├── 输出类型
│   │   ├── NodeOutput<T>                 (单一输出)
│   │   ├── NodeOutput<T> [NodeArraySize] (输出数组)
│   │   ├── EmptyNodeOutput               (空输出，仅信号)
│   │   └── EmptyNodeOutput[N]            (空输出数组)
│   │
│   └── 输出操作
│       ├── GetThreadNodeOutputRecords(count)
│       │   └── 每线程独立输出
│       ├── GetGroupNodeOutputRecords(count)
│       │   └── 组共享输出
│       ├── OutputComplete()              (必须调用!)
│       └── GroupIncrementOutputCount(n)  (空输出信号)
│
├── 4. HLSL 属性
│   │
│   ├── 必需属性
│   │   ├── [Shader("node")]
│   │   ├── [NodeLaunch("broadcasting"|"coalescing"|"thread")]
│   │   └── [NumThreads(x,y,z)]  (Thread Launch 除外)
│   │
│   ├── 可选属性
│   │   ├── [NodeID("name", index)]
│   │   ├── [NodeIsProgramEntry]
│   │   ├── [NodeLocalRootArgumentsTableIndex(idx)]
│   │   ├── [NodeShareInputOf("otherNode")]
│   │   ├── [NodeMaxRecursionDepth(depth)]
│   │   ├── [NodeDispatchGrid(x,y,z)]     (固定 Grid)
│   │   └── [NodeMaxDispatchGrid(x,y,z)]  (动态 Grid)
│   │
│   └── 输入属性
│       └── [MaxRecords(N)]
│
├── 5. API 流程
│   │
│   ├── 创建阶段
│   │   ├── 1. 编译 Shader (lib_6_8)
│   │   ├── 2. 创建 Root Signature
│   │   ├── 3. 创建 State Object
│   │   │   ├── D3D12_STATE_OBJECT_TYPE_EXECUTABLE
│   │   │   ├── DXIL_LIBRARY
│   │   │   ├── GLOBAL_ROOT_SIGNATURE
│   │   │   └── WORK_GRAPH
│   │   └── 4. 查询接口
│   │       ├── ID3D12StateObjectProperties1
│   │       └── ID3D12WorkGraphProperties
│   │
│   ├── 配置阶段
│   │   ├── GetWorkGraphIndex()
│   │   ├── GetWorkGraphMemoryRequirements()
│   │   └── 创建 Backing Memory Buffer
│   │
│   └── 执行阶段
│       ├── SetProgram()
│       │   ├── ProgramIdentifier
│       │   ├── BackingMemory
│       │   └── Flag: INITIALIZE
│       └── DispatchGraph()
│           ├── NODE_CPU_INPUT
│           ├── NODE_GPU_INPUT
│           ├── MULTI_NODE_CPU_INPUT
│           └── MULTI_NODE_GPU_INPUT
│
├── 6. 内存管理
│   │
│   ├── Backing Memory
│   │   ├── 系统管理的记录队列
│   │   ├── 调度元数据
│   │   └── 应用分配，GPU 使用
│   │
│   ├── 输出预留
│   │   └── 基于 MaxRecords 预留
│   │
│   └── 查询大小
│       ├── MinSizeInBytes
│       ├── MaxSizeInBytes
│       └── SizeGranularityInBytes
│
├── 7. 高级特性
│   │
│   ├── 节点数组
│   │   ├── [NodeArraySize(N)]
│   │   ├── 动态索引选择目标
│   │   └── 用于分类/装箱
│   │
│   ├── 递归
│   │   ├── 节点可输出到自身
│   │   ├── 声明 [NodeMaxRecursionDepth]
│   │   └── 最大深度 32
│   │
│   ├── 输入共享
│   │   └── [NodeShareInputOf("node")]
│   │
│   └── Graphics Nodes [实验性]
│       └── Mesh Shader 作为叶节点
│
└── 8. 对比与选型
    │
    ├── vs ExecuteIndirect
    │   ├── Work Graph: 并行调度，更灵活
    │   └── ExecuteIndirect: 串行处理，成熟稳定
    │
    ├── vs Mesh Shader
    │   ├── Work Graph: 通用计算 + 图形
    │   └── Mesh Shader: 图形专用
    │
    └── 节点类型选择
        ├── 需要放大 → Broadcasting
        ├── 需要批处理 → Coalescing
        └── 独立任务 → Thread
```

## 快速参考卡片

### 节点类型速查
```
┌─────────────┬───────────────┬────────────────┬─────────────┐
│  类型       │  输入→线程    │  ThreadGroup   │  典型用途   │
├─────────────┼───────────────┼────────────────┼─────────────┤
│Broadcasting │  1 → Grid     │  共享输入      │  并行放大   │
│Coalescing   │  N → Group    │  合并处理      │  批处理     │
│Thread       │  1 → 1 Thread │  固定(1,1,1)   │  独立任务   │
└─────────────┴───────────────┴────────────────┴─────────────┘
```

### HLSL 模板
```hlsl
// Broadcasting Launch
[Shader("node")]
[NodeLaunch("broadcasting")]
[NodeMaxDispatchGrid(256,256,1)]
[NumThreads(8,8,1)]
[NodeIsProgramEntry]
void MyNode(
    DispatchNodeInputRecord<InputT> input,
    [MaxRecords(16)] NodeOutput<OutputT> output
) { /* ... */ }

// Coalescing Launch
[Shader("node")]
[NodeLaunch("coalescing")]
[NumThreads(32,1,1)]
void MyNode(
    [MaxRecords(64)] GroupNodeInputRecords<InputT> inputs
) {
    uint count = inputs.Count();
    for (uint i = GroupIndex; i < count; i += 32) {
        // Process inputs[i]
    }
}

// Thread Launch
[Shader("node")]
[NodeLaunch("thread")]
void MyNode(
    ThreadNodeInputRecord<InputT> input
) { /* 单线程处理 */ }
```

### API 调用序列
```cpp
// 1. Create State Object
device->CreateStateObject(&desc, IID_PPV_ARGS(&stateObj));

// 2. Query Properties
stateObj->QueryInterface(IID_PPV_ARGS(&workGraphProps));

// 3. Get Memory Requirements
workGraphProps->GetWorkGraphMemoryRequirements(index, &memReqs);

// 4. Set Program
cmdList->SetProgram(&setProgramDesc);

// 5. Dispatch
cmdList->DispatchGraph(&dispatchDesc);
```
