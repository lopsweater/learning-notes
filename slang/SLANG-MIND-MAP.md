# Slang 着色器语言 - 思维导图

> 调研时间: 2026-04-14
> 仓库: https://github.com/shader-slang/slang
> Stars: 3.5k+ | License: Apache 2.0 with LLVM Exception

```
Slang 着色器语言
│
├── 1. 核心定位
│   ├── ★ 解决大规模着色器代码库维护问题
│   ├── ★ 模块化 + 可扩展性 + 高性能
│   ├── 多目标平台支持 (D3D12/Vulkan/Metal/CUDA/CPU)
│   └── NVIDIA + CMU + Stanford + MIT 联合研发
│
├── 2. 核心特性
│   │
│   ├── 2.1 模块系统
│   │   ├── import 声明（类似 ES6 modules）
│   │   ├── 独立编译 + 运行时链接
│   │   ├── __include 语义隔离
│   │   └── 支持 IR 导出/混淆
│   │
│   ├── 2.2 泛型与接口
│   │   ├── interface 定义契约
│   │   ├── 泛型函数/类型
│   │   ├── 关联类型 (associatedtype)
│   │   ├── 类型约束 (where T : IFoo)
│   │   └── ★ 预检查，无 C++ 模板错误风暴
│   │
│   ├── 2.3 自动微分
│   │   ├── [Differentiable] 属性
│   │   ├── fwd_diff (前向模式)
│   │   ├── bwd_diff (反向模式)
│   │   ├── DifferentialPair<T>
│   │   └── 支持控制流 + 泛型 + 接口
│   │
│   ├── 2.4 参数块系统
│   │   ├── ParameterBlock<T>
│   │   ├── 显式绑定管理
│   │   ├── D3D12 Descriptor Table
│   │   └── Vulkan Descriptor Set
│   │
│   └── 2.5 跨平台编译
│       ├── 目标: D3D11/D3D12/Vulkan/Metal/CUDA/CPU
│       ├── 输出: HLSL/SPIRV/GLSL/MSL/C++/WGSL
│       ├── Capability System (特性管理)
│       └── 指针支持 (Vulkan SPIR-V)
│
├── 3. 编译器架构
│   │
│   ├── Front-End
│   │   ├── Lexer → Token 流
│   │   ├── Preprocessor → 宏展开
│   │   ├── Parser → AST
│   │   └── Semantic Checking → 类型检查
│   │
│   ├── Middle-End
│   │   ├── Lowering to IR
│   │   ├── SSA Promotion
│   │   ├── Mandatory Optimizations
│   │   └── Parameter Binding
│   │
│   └── Back-End
│       ├── Target Selection
│       ├── Code Generation
│       └── DXIL/SPIRV/MSL/C++ 输出
│
├── 4. 工具链支持
│   │
│   ├── 编译器
│   │   ├── slangc (命令行)
│   │   ├── slang.dll/.so (API)
│   │   └── WebAssembly (浏览器)
│   │
│   ├── IDE 支持
│   │   ├── VS Code 扩展
│   │   ├── Visual Studio 集成
│   │   └── Language Server Protocol
│   │
│   ├── 调试工具
│   │   ├── RenderDoc 支持
│   │   ├── SPIR-V 工具链
│   │   └── 保留符号名（可读性）
│   │
│   └── PyTorch 集成
│       ├── slangtorch 绑定
│       ├── 自动微分集成
│       └── Neural Graphics 支持
│
├── 5. 与 HLSL/GLSL 对比
│   │
│   ├── vs HLSL
│   │   ├── ✅ 兼容 HLSL 语法（几乎无需修改）
│   │   ├── ✅ 模块化支持
│   │   ├── ✅ 泛型/接口
│   │   ├── ✅ 自动微分
│   │   └── ❌ 不支持 Effect 系统
│   │
│   └── vs GLSL
│   │   ├── ✅ 更好的类型系统
│   │   ├── ✅ 模块化
│   │   ├── ✅ 跨平台
│   │   ├── ✅ 兼容 GLSL 内置函数
│   │   └── ❌ 学习曲线
│
├── 6. 应用场景
│   │
│   ├── 游戏引擎
│   │   ├── 大型着色器代码库
│   │   ├── 材质系统
│   │   ├── 后处理管线
│   │   └── 多平台渲染
│   │
│   ├── Neural Graphics
│   │   ├── NeRF
│   │   ├── Gaussian Splatting
│   │   ├── 可微渲染
│   │   └── AI 训练循环
│   │
│   └── 研究原型
│       ├── 快速迭代
│       ├── 跨平台验证
│       └── 学术论文实现
│
└── 7. 学习路径
    │
    ├── 阶段 1 (Week 1-2): 基础语法
    │   ├── HLSL 迁移
    │   ├── 编译器使用
    │   ├── 模块系统
    │   └── 参数绑定
    │
    ├── 阶段 2 (Week 3-4): 核心特性
    │   ├── 泛型编程
    │   ├── 接口设计
    │   ├── 关联类型
    │   └── 多平台编译
    │
    ├── 阶段 3 (Week 5-6): 高级特性
    │   ├── 自动微分
    │   ├── Neural Graphics
    │   ├── PyTorch 集成
    │   └── 性能优化
    │
    └── 阶段 4 (Week 7-8): 实战项目
        ├── 渲染管线实现
        ├── 材质系统设计
        ├── 多平台部署
        └── 性能调优
```

## 关键洞察

### ★★★ 核心优势

1. **模块化设计**
   - 现代 import/export 语义
   - 支持独立编译
   - 解决大规模代码库维护难题

2. **泛型 + 接口**
   - 类型安全的代码复用
   - 无 C++ 模板的错误风暴
   - 支持关联类型（Swift/Rust 风格）

3. **自动微分**
   - 原生支持反向传播
   - Neural Graphics 友好
   - PyTorch 无缝集成

### ★ 易错点

1. **import vs #include**
   - import 不共享预处理器状态
   - 类似 using namespace，不是文本替换

2. **泛型约束**
   - 必须显式声明类型约束
   - 不像 C++ 模板可以"鸭子类型"

3. **模块定义**
   - 必须有一个主文件（module 声明）
   - 其他文件用 implementing + __include

### ★重要 设计哲学

- **渐进式迁移**: HLSL 代码几乎无需修改
- **性能优先**: 编译时特化，无运行时开销
- **类型安全**: 编译时检查，提前发现错误
- **跨平台抽象**: 一次编写，多平台部署
