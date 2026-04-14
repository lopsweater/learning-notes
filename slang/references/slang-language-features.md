# Slang 语言特性深度分析

> 调研时间: 2026-04-14
> 目标: 深入理解 Slang 的核心语言特性

## 一、模块系统 (Module System)

### 1.1 设计动机

传统着色器语言的痛点：
```hlsl
// ❌ 传统方式：#include 文本替换
#include "lighting.hlsli"
#include "shadow.hlsli"

// 问题：
// 1. 宏定义污染全局命名空间
// 2. 重复包含需要 #pragma once
// 3. 无法实现真正的封装
// 4. 缺乏依赖管理
```

Slang 的解决方案：
```slang
// ✅ Slang 方式：模块化导入
import lighting;
import shadow;

// 优势：
// 1. 独立的命名空间
// 2. 编译时检查依赖
// 3. 支持独立编译
// 4. 运行时链接
```

### 1.2 模块定义语法

**主模块文件** (`scene.slang`):
```slang
// scene.slang
module scene;

import math_utils;

// 公开 API
public struct SceneData
{
    float3 cameraPos;
    float4x4 viewProj;
}

public float3 transformPosition(float3 pos)
{
    return mul(scene.viewProj, float4(pos, 1.0)).xyz;
}
```

**辅助文件** (`scene-helpers.slang`):
```slang
// scene-helpers.slang
implementing scene;

// 仅模块内部可见
internal float computeDistance(float3 a, float3 b)
{
    return length(a - b);
}
```

### 1.3 模块语义细节

| 特性 | import | __include | #include |
|------|--------|-----------|----------|
| 预处理器隔离 | ✅ 是 | ✅ 是 | ❌ 否 |
| 命名空间 | ✅ 创建新命名空间 | ❌ 同模块 | ❌ 全局 |
| 循环依赖 | ✅ 支持 | ✅ 支持 | ❌ 不支持 |
| 编译单元 | ✅ 独立编译 | ❌ 同模块 | ❌ 文本合并 |

### 1.4 文件名映射规则

```slang
import my_module;      // → my-module.slang
import my_module.sub;  // → my-module/sub.slang
import my_module;      // → "my-module.slang" (字符串形式)
```

**关键规则**：
- `_` 转换为 `-`
- `.` 转换为 `/`
- 自动追加 `.slang` 后缀

## 二、泛型系统 (Generics)

### 2.1 与 C++ 模板的区别

| 特性 | Slang 泛型 | C++ 模板 |
|------|-----------|----------|
| 类型检查时机 | 定义时 | 实例化时 |
| 错误信息 | 清晰、定点 | 级联、难懂 |
| 代码膨胀 | 可控 | 每次实例化生成代码 |
| 约束机制 | 显式 where 子句 | 隐式鸭子类型 |
| 编译速度 | 快（预检查） | 慢（重复解析） |

### 2.2 泛型函数示例

```slang
// 定义接口
interface ILight
{
    struct LightSample { float3 intensity; float3 direction; };
    LightSample sample(float3 position);
}

// 泛型函数
float4 computeDiffuse<L : ILight>(
    float4 albedo,
    float3 P,
    float3 N,
    L light  // 类型 T 必须实现 ILight
)
{
    auto sample = light.sample(P);
    float nDotL = max(0, dot(N, sample.direction));
    return albedo * nDotL;
}

// 使用
struct PointLight : ILight { /* ... */ };
PointLight pl;
float4 result = computeDiffuse(albedo, pos, normal, pl);
```

### 2.3 关联类型 (Associated Types)

**问题场景**：材质返回不同类型的 BRDF

```slang
interface IBRDF
{
    float3 eval(float3 wi, float3 wo);
}

// Disney BRDF
struct DisneyBRDF : IBRDF { /* ... */ };

// Kajiya-Kay BRDF
struct KajiyaKay : IBRDF { /* ... */ };

// 材质接口
interface IMaterial
{
    // 问题：返回什么类型？
    // DisneyBRDF? KajiyaKay?
    ??? evalPattern(float3 pos, float2 uv);
}

// ✅ 解决方案：关联类型
interface IMaterial
{
    associatedtype B : IBRDF;  // 关联类型约束
    B evalPattern(float3 pos, float2 uv);
}

// 实现
struct MyMaterial : IMaterial
{
    typedef DisneyBRDF B;  // 指定具体类型
    B evalPattern(float3 pos, float2 uv) { /* ... */ }
}

struct AnotherMaterial : IMaterial
{
    typedef KajiyaKay B;  // 可以是不同的 BRDF
    B evalPattern(float3 pos, float2 uv) { /* ... */ }
}
```

### 2.4 全局泛型参数

```slang
// 传统 HLSL 风格：全局变量
// Material gMaterial;  // 类型固定

// Slang 泛型风格
type_param M : IMaterial;  // 全局泛型参数
M gMaterial;                // 类型由调用方指定

// 等价于整个着色器被包裹在泛型中：
// shader<M : IMaterial> { ... }
```

## 三、接口系统 (Interfaces)

### 3.1 接口定义

```slang
interface IShape
{
    float getArea();
    float3 getNormal(float3 hitPos);
}

// 多接口实现
interface ITransformable
{
    void translate(float3 delta);
    void rotate(float3 axis, float angle);
}

struct Sphere : IShape, ITransformable
{
    float3 center;
    float radius;

    // IShape 实现
    float getArea() { return 4.0 * 3.14159 * radius * radius; }
    float3 getNormal(float3 hitPos) { return normalize(hitPos - center); }

    // ITransformable 实现
    void translate(float3 delta) { center += delta; }
    void rotate(float3 axis, float angle) { /* ... */ }
}
```

### 3.2 默认实现

```slang
interface ILogger
{
    void log(string msg) { print(msg); }  // 默认实现

    void logError(string msg)  // 必须实现
    {
        log("ERROR: " + msg);
    }
}

struct MyLogger : ILogger
{
    // 使用默认实现，无需重写 log()
    
    // 或者自定义实现（需要 override）
    override void log(string msg)
    {
        print("[MyLogger] " + msg);
    }
}
```

### 3.3 接口方法表 (vtable)

编译器为接口类型生成方法表：
```
IShape vtable:
+-----------------+
| getArea ptr     |
| getNormal ptr   |
+-----------------+

运行时：
Sphere s = ...;
IShape shape = s;  // 编译器自动插入 vtable 指针
shape.getArea();   // 通过 vtable 调用
```

**性能特性**：
- ✅ 编译时可确定具体类型 → 内联、特化
- ✅ 运行时多态 → vtable（类似 C++ 虚函数）
- ❌ 比 C++ 模板稍慢（有间接调用开销）

## 四、自动微分 (Automatic Differentiation)

### 4.1 数学基础

**Jacobian 矩阵**：
```
f(x) = x³ + x² - y

Df(x, y) = [∂f/∂x, ∂f/∂y]
         = [3x² + 2x, -1]
```

**前向模式 (Forward Mode)**：
```
输入：x, ∂x/∂θ（输入对 θ 的导数）
输出：∂f/∂θ（输出对 θ 的导数）

Jacobian-vector product: <Df(x), v>
```

**反向模式 (Reverse Mode)**：
```
输入：x, ∂L/∂f（损失对输出的导数）
输出：∂L/∂x（损失对输入的导数）

Vector-Jacobian product: <vᵀ, Df(x)>
```

### 4.2 Slang 实现

```slang
[Differentiable]  // 必须标记
float2 foo(float a, float b)
{
    return float2(a * b * b, a * a);
}

// 前向模式
void testForward()
{
    DifferentialPair<float> dp_a = diffPair(1.0, 1.0);  // (值, 导数)
    DifferentialPair<float> dp_b = diffPair(2.0, 0.0);
    
    auto result = fwd_diff(foo)(dp_a, dp_b);
    // result.p   = (1 * 2², 1²) = (4.0, 1.0)    ← 函数值
    // result.d   = 导数向量
}

// 反向模式（机器学习常用）
void testBackward()
{
    DifferentialPair<float> dp_a = diffPair(1.0, 0.0);
    DifferentialPair<float> dp_b = diffPair(2.0, 0.0);
    
    auto grad = bwd_diff(foo)(dp_a, dp_b);
    // grad.d = ∂L/∂a, ∂L/∂b
}
```

### 4.3 应用场景

**Neural Radiance Fields (NeRF)**:
```slang
[Differentiable]
float3 renderNeRF(
    float3 rayOrigin,
    float3 rayDir,
    MLP network  // 神经网络
)
{
    float3 color = 0.0;
    for (int i = 0; i < STEPS; i++)
    {
        float3 p = rayOrigin + rayDir * t;
        auto [density, radiance] = network(p);
        color += alphaCompositing(density, radiance);
    }
    return color;
}

// 训练循环（Python/PyTorch 端）
for epoch in range(epochs):
    pred = renderNeRF(rays)
    loss = mseLoss(pred, gt)
    loss.backward()  # Slang 自动生成反向传播
```

**Gaussian Splatting**:
```slang
[Differentiable]
float4 renderGaussian(
    float3 pos,
    GaussianSplat splat  // 3D 高斯参数
)
{
    // 可微的 Alpha blending
    // 自动计算梯度用于优化高斯参数
}
```

### 4.4 性能特性

| 特性 | 前向模式 | 反向模式 |
|------|---------|----------|
| 适用场景 | 输入少、输出多 | 输入多、输出少 |
| 计算复杂度 | O(n) | O(1) |
| 内存占用 | 低 | 高（需保存中间状态） |
| 典型应用 | Jacobian 计算 | 神经网络训练 |

## 五、参数块系统 (Parameter Blocks)

### 5.1 设计动机

**问题**：现代图形 API 的参数绑定复杂

```hlsl
// ❌ 手动管理绑定
cbuffer ViewCB : register(b0) { float4x4 viewProj; }
Texture2D tex0 : register(t0);
Texture2D tex1 : register(t1);
SamplerState samp0 : register(s0);

// D3D12: Descriptor Table 管理复杂
// Vulkan: Descriptor Set 编号混乱
```

**解决方案**：
```slang
// ✅ 显式参数块
struct ViewParams
{
    float3 cameraPos;
    float4x4 viewProj;
    TextureCube envMap;
}

ParameterBlock<ViewParams> gViewParams;

// 编译器自动映射到：
// D3D12 → 一个 Descriptor Table
// Vulkan → 一个 Descriptor Set
// Metal → 一个 Argument Buffer
```

### 5.2 嵌套参数块

```slang
struct MaterialParams { /* ... */ };
struct LightParams { /* ... */ };

ParameterBlock<MaterialParams> gMaterial;
ParameterBlock<LightParams> gLights;

// 生成的绑定：
// gMaterial → set 0
// gLights → set 1
```

### 5.3 动态索引

```slang
struct Light { float3 position; float3 color; };

ParameterBlock<Light> gLights[10];  // 光源数组

// 编译为：
// D3D12: Descriptor Table with 10 ranges
// Vulkan: Descriptor Set array
```

## 六、能力系统 (Capability System)

### 6.1 平台特性管理

```slang
// 条件编译
#if defined(SLANG_SPIRV)
    // Vulkan 特有功能
    RaytracingAccelerationStructure accel;
    float4 result = traceray(accel, ray);
#elif defined(SLANG_HLSL)
    // D3D12 特有功能
    RaytracingAccelerationStructure accel;
    float4 result = TraceRay(accel, ...);
#endif

// Capability 系统
[require(spv_ray_tracing)]  // 声明依赖
float4 traceRay(...)
{
    // 编译器检查目标平台是否支持
}
```

### 6.2 特性检测

```slang
// 编译时检查
static if (hasCapability(spv_ray_query))
{
    // 使用光线查询
}
else
{
    // 回退方案
}
```

## 七、指针支持

### 7.1 Vulkan SPIR-V 指针

```slang
// Slang 中使用指针（Vulkan 目标）
void modifyValue(int* ptr, int value)
{
    *ptr = value;
}

// 编译为 SPIR-V:
// %ptr = OpVariable %_ptr_Function_int Function
// OpStore %ptr %value
```

**优势**：
- ✅ 支持复杂数据结构
- ✅ 避免值复制的开销
- ✅ 实现高级算法（如就地修改）

**限制**：
- ❌ 仅限 Vulkan SPIR-V 目标
- ❌ 不能跨线程共享指针
- ❌ 指针运算受限

## 八、总结

### 核心创新点

1. **模块系统**：解决大规模代码库维护难题
2. **泛型 + 接口**：类型安全的代码复用
3. **自动微分**：Neural Graphics 原生支持
4. **跨平台编译**：一次编写，多平台部署

### 设计哲学

- **渐进式采用**：HLSL 代码无需大改
- **零开销抽象**：编译时特化，无运行时成本
- **类型安全**：编译时捕获错误
- **可扩展性**：模块化、接口、泛型

### 适用场景

| 场景 | 推荐度 | 理由 |
|------|--------|------|
| 大型游戏项目 | ★★★★★ | 模块化、可维护性强 |
| Neural Graphics 研究 | ★★★★★ | 自动微分、PyTorch 集成 |
| 多平台渲染器 | ★★★★☆ | 跨平台编译，但有 Metal 限制 |
| 学习/原型 | ★★★☆☆ | 学习曲线较陡 |
| 简单着色器 | ★★☆☆☆ | 杀鸡用牛刀 |

### 未来展望

- **隐式泛型语法**：`void foo(ILight light)` 替代 `void foo<L : ILight>(L light)`
- **接口返回类型**：`ILight getLight(...)` （当前不支持）
- **更完善的 Metal/CUDA 支持**
- **更强大的编译器优化**

---

**参考资源**：
- 官方文档: https://shader-slang.com/slang/user-guide/
- 语言参考: docs/language-guide.md
- 设计文档: docs/design/
- 示例代码: examples/
