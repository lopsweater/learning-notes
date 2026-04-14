# Slang 编译器架构分析

> 调研时间: 2026-04-14
> 目标: 理解 Slang 编译器的内部设计和实现

## 一、编译流水线概览

```
源代码 (.slang)
    ↓
┌─────────────────────────────────────┐
│         Front-End (前端)              │
├─────────────────────────────────────┤
│  Lexer        → Token 流             │
│  Preprocessor → 宏展开               │
│  Parser       → AST                  │
│  Semantic     → 类型检查             │
│  Lowering     → IR                   │
│  Optimize     → 优化 IR              │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│       Parameter Binding (参数绑定)    │
├─────────────────────────────────────┤
│  Type Layout   → 内存布局            │
│  Binding       → 寄存器/描述符分配   │
│  Reflection    → 反射信息生成        │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│         Back-End (后端)               │
├─────────────────────────────────────┤
│  Target Selection → 目标选择         │
│  Code Gen         → 代码生成         │
│  Output           → DXIL/SPIRV/...   │
└─────────────────────────────────────┘
    ↓
目标代码 (HLSL/SPIRV/MSL/C++/...)
```

## 二、Front-End 详细分析

### 2.1 词法分析 (Lexer)

**位置**: `source/slang/lexer.{h,cpp}`

**输入**: 字符流
**输出**: Token 流

**Token 结构**:
```cpp
struct Token
{
    TokenCode type;     // 类型：标识符、字面量、操作符...
    StringSlice text;   // 原始文本
    SourceLoc loc;      // 源码位置（单整数编码）
};
```

**关键特性**：
- **惰性生成**：按需生成 Token，不预先生成全部
- **紧凑编码**：源码位置用单整数表示（file + line + col）
- **字面量延迟解析**：整数/浮点字面量仅存储文本，后续解析

**关键字处理**：
```cpp
// 不是硬编码关键字，而是环境中的标识符
// 例如：if, for, while 只是绑定到语法的标识符
// 允许用户重定义（兼容 HLSL）
```

### 2.2 预处理 (Preprocessor)

**位置**: `source/slang/preprocessor.{h,cpp}`

**输入**: Token 流
**输出**: 预处理后的 Token 流

**主要功能**：
```cpp
class Preprocessor
{
    // 输入流栈
    Stack<InputSource*> inputStreams;
    
    // 宏定义环境
    MacroEnvironment env;
    
    // 处理指令
    void handleDirective(Token directive);
    void handleInclude(Token path);
    void handleDefine(Token name, Token value);
    void handleIfdef(Token name);
    // ...
};
```

**关键特性**：
- **惰性条件编译**：不活跃分支仍做词法分析，但不评估指令
- **宏存储**：存储已分词的 Token 序列，展开时"重放"
- **环境栈**：函数式宏参数通过伪宏映射

**import vs #include**:
```slang
// #include: 文本替换，预处理器状态传播
#include "foo.h"
// 宏定义相互可见

// import: 模块导入，预处理器状态隔离
import foo;
// 宏定义不传播
```

### 2.3 语法分析 (Parser)

**位置**: `source/slang/parser.{h,cpp}`

**输入**: Token 流
**输出**: AST（抽象语法树）

**解析策略**：
```cpp
class Parser
{
    // 递归下降解析
    void parseDecl();
    void parseStmt();
    void parseExpr();
    
    // 泛型判断启发式
    // < 后标识符：
    //   尝试解析为泛型参数列表
    //   看下一个 Token 是否像函数调用
    //   否则回溯
};
```

**AST 节点类型**：
```cpp
// 声明节点
class Decl : public Node
{
    // VarDecl, FunctionDecl, StructDecl, ...
};

// 表达式节点
class Expr : public Node
{
    // LiteralExpr, BinaryExpr, CallExpr, ...
};

// 语句节点
class Stmt : public Node
{
    // IfStmt, ForStmt, ReturnStmt, ...
};
```

**语法即声明**：
```cpp
// 关键字不是硬编码，而是声明
// 例如：
syntax if;  // if 关键字绑定到 IfStmt 语法
syntax for; // for 关键字绑定到 ForStmt 语法

// 允许扩展语言语法（未来支持宏系统）
```

**作用域处理**：
```cpp
// 早期设计：AST 节点携带词法作用域
// 问题：混乱，难以维护

// 未来方向：分离作用域信息
// 解析全局声明后，再处理函数体
```

### 2.4 语义检查 (Semantic Checking)

**位置**: `source/slang/check.{h,cpp}`

**输入**: AST
**输出**: 类型标注的 AST

**核心职责**：
```cpp
class SemanticChecker
{
    // 类型检查
    Type* checkExpr(Expr* expr);
    void checkStmt(Stmt* stmt);
    void checkDecl(Decl* decl);
    
    // 解析重载
    FunctionDecl* resolveOverload(
        String name,
        Array<Type*> argTypes
    );
    
    // 泛型实例化
    Type* instantiateGeneric(
        GenericDecl* generic,
        Array<Type*> typeArgs
    );
    
    // 接口实现检查
    void checkInterfaceConformance(
        StructDecl* decl,
        InterfaceDecl* iface
    );
};
```

**类型表示**：
```cpp
// 类型层次
class Type { /* ... */ };
class BasicType : public Type { /* float, int, ... */ };
class VectorType : public Type { /* float3, int4, ... */ };
class StructType : public Type { /* user-defined */ };
class InterfaceType : public Type { /* interface types */ };
class GenericType : public Type { /* T */ };
```

**延迟检查**：
```cpp
// 支持乱序声明
void foo() { bar(); }  // bar 未声明
void bar() { }         // 后声明

// 实现：按需检查
void checkFunction(FunctionDecl* func)
{
    if (func->isChecked) return;
    func->isChecked = true;
    
    // 检查函数体
    for (auto stmt : func->body)
        checkStmt(stmt);
}
```

**接口实现验证**：
```cpp
// 检查类型是否实现接口
void checkInterfaceConformance(
    StructDecl* structDecl,
    InterfaceDecl* iface
)
{
    for (auto req : iface->requirements)
    {
        // 查找实现
        auto impl = findMember(structDecl, req->name);
        
        // 检查签名匹配
        if (!signaturesMatch(impl, req))
            error("interface requirement not met");
        
        // 记录映射
        recordImplementation(structDecl, req, impl);
    }
}
```

### 2.5 IR 生成 (Lowering)

**位置**: `source/slang/lower-to-ir.{h,cpp}`

**输入**: 类型标注的 AST
**输出**: IR (Intermediate Representation)

**IR 结构**：
```cpp
// IR 指令类型
enum class IROp
{
    // 算术
    add, sub, mul, div,
    
    // 内存
    load, store,
    
    // 控制流
    branch, conditionalBranch,
    
    // 调用
    call,
    
    // 泛型特化
    specialize,
    
    // ...
};

// IR 基本块
class IRBlock
{
    List<IRInst*> instructions;
    IRBlock* next;
    IRBlock* branchTarget;
};

// IR 函数
class IRFunc
{
    IRBlock* entry;
    IRBlock* exit;
    List<IRParam*> params;
};
```

**Lowering 转换**：
```cpp
// AST → IR 转换

// 1. 成员函数 → 普通函数
struct Foo {
    void bar() { /* ... */ }
};
// →
void Foo_bar(Foo* this) { /* ... */ }

// 2. 嵌套类型 → 顶层类型
struct Outer {
    struct Inner { /* ... */ };
};
// →
struct Outer_Inner { /* ... */ };

// 3. 控制流 → CFG
if (cond) { A } else { B }
// →
// bb_entry: branch cond ? bb_A : bb_B
// bb_A: ...; branch bb_exit
// bb_B: ...; branch bb_exit
// bb_exit: ...
```

**名称修饰 (Name Mangling)**：
```cpp
// 为每个符号生成唯一名称
float foo<int>(int x);
// → _Z3fooIiEiT_  // 类似 Itanium ABI

// 好处：
// 1. 支持函数重载
// 2. 支持泛型特化
// 3. 链接时符号解析
```

### 2.6 强制优化 (Mandatory Optimizations)

**位置**: `source/slang/ir-optimize.{h,cpp}`

**目的**：不是为了性能，而是为了简化后续验证

**关键优化**：
```cpp
// 1. SSA 提升 (SSA Promotion)
// 将变量转换为 SSA 形式
int x = 0;
x = 1;
use(x);
// →
int x_0 = 0;
int x_1 = 1;
use(x_1);

// 2. 复制传播
int x = y;
int z = x;
// →
int z = y;

// 3. 死代码消除
if (false) { /* 死代码 */ }
// →
// (删除)

// 4. 常量折叠
int x = 2 + 3;
// →
int x = 5;
```

**IR 验证**：
```cpp
// 检查 AST 上难以检查的错误

// 1. 控制流验证
void checkControlFlow(IRFunc* func)
{
    // 检查非 void 函数是否所有路径都有返回
    if (func->returnType != voidType)
    {
        if (!allPathsReturn(func))
            error("not all code paths return a value");
    }
}

// 2. 资源类型使用验证
void checkResourceUsage(IRInst* inst)
{
    // 检查资源类型是否静态可解析
    // 例如：不能条件计算资源引用
}

// 3. 常量表达式验证
void checkConstExpr(IRInst* inst)
{
    // 检查需要编译时常量的参数
    // 例如：纹理采样的 texel offset
}
```

## 三、Parameter Binding 详细分析

### 3.1 类型布局 (Type Layout)

**位置**: `source/slang/parameter-binding.{h,cpp}`

**目的**：计算每个类型占用的寄存器/描述符/内存

```cpp
struct TypeLayout
{
    // Uniform 数据
    size_t uniformSize;
    size_t uniformAlignment;
    
    // 资源绑定
    struct ResourceInfo
    {
        ResourceKind kind;  // Texture, Sampler, UAV, ...
        size_t count;
        int space;          // D3D12 space / Vulkan set
        int index;          // 绑定索引
    };
    List<ResourceInfo> resources;
};
```

**布局规则**：

| 类型 | D3D12 | Vulkan | Metal |
|------|-------|--------|-------|
| float4 | 16 bytes (cbuffer) | 16 bytes (uniform) | 16 bytes |
| Texture2D | 1 descriptor (t#) | 1 binding (set, binding) | 1 texture |
| SamplerState | 1 descriptor (s#) | 1 binding | 1 sampler |
| RWTexture2D | 1 descriptor (u#) | 1 binding | 1 texture |

### 3.2 参数绑定算法

```cpp
void bindParameters(
    CompileRequest* request,
    TargetRequest* target
)
{
    // 1. 收集所有参数
    List<Parameter> params = collectParameters(request);
    
    // 2. 处理显式绑定
    for (auto param : params)
    {
        if (hasExplicitBinding(param))
        {
            reserveBinding(bindingInfo(param));
        }
    }
    
    // 3. 分配隐式绑定（首次适应）
    for (auto param : params)
    {
        if (!hasExplicitBinding(param))
        {
            auto layout = computeLayout(param->type);
            int binding = findAvailableSlot(layout);
            assignBinding(param, binding);
        }
    }
    
    // 4. 生成反射信息
    generateReflection(request);
}
```

### 3.3 ParameterBlock 布局

```slang
struct ViewParams
{
    float3 cameraPos;        // 12 bytes
    float4x4 viewProj;       // 64 bytes
    TextureCube envMap;      // 1 texture
}

ParameterBlock<ViewParams> gViewParams;
```

**生成的绑定**：
```
D3D12:
  - b0: cbuffer { float3 cameraPos; float4x4 viewProj; }
  - t0: TextureCube envMap
  → 同一个 Descriptor Table

Vulkan:
  - set = 0, binding = 0: uniform buffer
  - set = 0, binding = 1: texture
  → 同一个 Descriptor Set

Metal:
  - 同一个 Argument Buffer
```

### 3.4 反射 API

**位置**: `source/slang/reflection.{h,cpp}`

**功能**：查询着色器参数信息

```cpp
// C API
SLANG_API SlangReflection* slangGetReflection(
    SlangCompileRequest* request
);

// 查询参数
SLANG_API SlangReflectionParameter* slangReflectionGetParameter(
    SlangReflection* reflection,
    unsigned index
);

// 查询绑定
SLANG_API int slangReflectionParameterGetBindingIndex(
    SlangReflectionParameter* param
);

// 查询类型
SLANG_API SlangReflectionType* slangReflectionParameterGetType(
    SlangReflectionParameter* param
);
```

**使用示例**：
```cpp
auto reflection = slangGetReflection(request);

// 遍历参数
for (int i = 0; i < reflection->getParameterCount(); i++)
{
    auto param = reflection->getParameter(i);
    
    std::cout << param->getName() << std::endl;
    std::cout << "  Binding: " << param->getBindingIndex() << std::endl;
    std::cout << "  Type: " << param->getType()->getName() << std::endl;
}
```

## 四、Back-End 详细分析

### 4.1 目标选择

**支持的目标**：
```cpp
enum class CodeGenTarget
{
    // 图形 API
    HLSL,        // D3D11/D3D12
    GLSL,        // OpenGL
    SPIRV,       // Vulkan
    MSL,         // Metal
    
    // 计算
    CUDA,        // NVIDIA GPU
    CXX,         // CPU
    
    // Web
    WGSL,        // WebGPU
};
```

### 4.2 代码生成

**SPIR-V 生成**：
```cpp
class SPIRVCodegen
{
    void emitFunction(IRFunc* func)
    {
        // 生成 SPIR-V 指令
        
        // 函数声明
        emitOpFunction(func->returnType, func->name);
        
        // 参数
        for (auto param : func->params)
            emitOpFunctionParameter(param);
        
        // 基本块
        emitLabel(func->entry);
        for (auto block : func->blocks)
        {
            for (auto inst : block->instructions)
                emitInstruction(inst);
        }
        
        emitOpFunctionEnd();
    }
    
    void emitInstruction(IRInst* inst)
    {
        switch (inst->op)
        {
            case IROp::add:
                emitOpAdd(inst->type, inst->result, inst->args[0], inst->args[1]);
                break;
            case IROp::load:
                emitOpLoad(inst->type, inst->result, inst->args[0]);
                break;
            // ...
        }
    }
};
```

**Metal Shading Language 生成**：
```cpp
class MSLCodegen
{
    void emitStruct(StructDecl* decl)
    {
        out << "struct " << decl->name << "\n{\n";
        for (auto field : decl->fields)
        {
            out << "    " << field->type << " " << field->name << ";\n";
        }
        out << "};\n";
    }
    
    void emitFunction(FunctionDecl* decl)
    {
        // Metal 入口点标记
        if (decl->isEntryPoint)
        {
            out << "[[vertex]] ";  // 或 [[fragment]], [[kernel]]
        }
        
        out << decl->returnType << " " << decl->name << "(";
        // 参数...
        out << ")\n{\n";
        // 函数体...
        out << "}\n";
    }
};
```

### 4.3 代码可读性

**保留标识符名称**：
```slang
// Slang 源码
float computeLighting(Material mat, Light light)
{
    float3 N = mat.normal;
    float3 L = light.direction;
    return max(0, dot(N, L));
}
```

**生成的 MSL**：
```metal
// 保留原始名称，便于调试
float computeLighting(Material mat, Light light)
{
    float3 N = mat.normal;
    float3 L = light.direction;
    return max(0.0, dot(N, L));
}
```

**对比 SPIR-V（二进制）**：
```
; OpName 保留名称
OpName %computeLighting "computeLighting"
OpName %mat "mat"
OpName %light "light"
OpName %N "N"
OpName %L "L"
```

## 五、编译器 API

### 5.1 C API

**位置**: `source/slang/slang.h`

```cpp
// 创建编译请求
SlangCompileRequest* request = slangCreateCompileRequest();

// 设置目标
slangCompileRequest_setCodeGenTarget(request, SLANG_SPIRV);

// 添加源文件
slangCompileRequest_addFile(request, "shader.slang");

// 添加入口点
slangCompileRequest_addEntryPoint(
    request,
    0,  // translation unit index
    "main",
    SLANG_STAGE_VERTEX
);

// 编译
SlangResult result = slangCompileRequest_compile(request);

// 获取输出
void* spirvData = slangCompileRequest_getCompileRequestCode(
    request,
    0,  // target index
    &size
);

// 获取反射
SlangReflection* reflection = slangGetReflection(request);

// 清理
slangCompileRequest_release(request);
```

### 5.2 会话管理

```cpp
// 创建会话（缓存编译器状态）
SlangSession* session = slangCreateSession();

// 创建请求
SlangCompileRequest* request = slangCreateCompileRequest(session);

// 多次编译，复用会话
for (auto shader : shaders)
{
    compileShader(session, shader);
}

// 清理
slangSession_release(session);
```

### 5.3 链接模块

```cpp
// 独立编译模块
SlangCompileRequest* moduleRequest = slangCreateCompileRequest(session);
slangCompileRequest_addFile(moduleRequest, "material-module.slang");
slangCompileRequest_setOutputFormat(moduleRequest, SLANG_MODULE_IR);
slangCompileRequest_compile(moduleRequest);

// 获取模块 IR
void* moduleIR = slangCompileRequest_getModuleIR(moduleRequest);

// 主程序链接模块
SlangCompileRequest* mainRequest = slangCreateCompileRequest(session);
slangCompileRequest_addFile(mainRequest, "main.slang");
slangCompileRequest_link(mainRequest, moduleIR);
slangCompileRequest_compile(mainRequest);
```

## 六、性能特性

### 6.1 编译速度优化

| 优化技术 | 效果 |
|---------|------|
| 惰性词法分析 | 按需生成 Token |
| 延迟类型检查 | 只检查用到的代码 |
| 模块缓存 | 避免重复编译 |
| 增量编译 | 只重编修改的部分 |
| 并行编译 | 多核加速 |

### 6.2 运行时性能

| 特性 | 开销 |
|------|------|
| 泛型特化 | 零开销（编译时展开） |
| 接口调用 | 单次间接调用（vtable） |
| 参数块 | 零开销（编译时绑定） |
| 自动微分 | 2-3 倍计算开销（不可避免） |

## 七、总结

### 架构优势

1. **分层清晰**：前端/中端/后端分离
2. **目标无关**：中间 IR 与目标平台解耦
3. **可扩展性**：易于添加新目标
4. **可调试性**：保留源码信息

### 实现亮点

- **语法即声明**：关键字不是硬编码
- **延迟检查**：支持乱序声明
- **强制优化**：简化验证
- **反射 API**：运行时查询参数

### 改进空间

- **AST 类型系统**：当前使用 RTTI，可优化
- **作用域管理**：可更清晰地分离
- **错误诊断**：可提供更友好的错误信息

---

**源码位置**：
- 编译器核心: `source/slang/`
- 命令行工具: `source/slangc/`
- API 定义: `source/slang/slang.h`
- 文档: `docs/design/`
