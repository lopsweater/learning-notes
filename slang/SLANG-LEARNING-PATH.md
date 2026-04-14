# Slang 学习路径指南

> 调研时间: 2026-04-14
> 目标: 提供系统性的学习路线

## 一、前置知识

### 1.1 必备基础

- ✅ C/C++ 基础语法
- ✅ 图形编程基础（OpenGL/Direct3D）
- ✅ 向量/矩阵运算
- ✅ GPU 渲染管线概念

### 1.2 推荐基础

- ⚪ HLSL 或 GLSL 经验（加速学习）
- ⚪ 泛型编程概念（C++ 模板、Java/C# 泛型）
- ⚪ 接口/协议概念（C++ 抽象类、Java 接口、Rust trait）

## 二、学习路径

### 阶段 1: 基础入门 (Week 1-2)

#### 目标
- 掌握 Slang 基本语法
- 学会使用编译器
- 理解模块系统

#### 学习内容

**Day 1-3: 环境搭建**
```bash
# 方式 1: 下载预编译版本
wget https://github.com/shader-slang/slang/releases/latest/download/slang-linux-x64.zip
unzip slang-linux-x64.zip
export PATH=$PWD/bin:$PATH

# 方式 2: 使用 Vulkan SDK (>= 1.3.296.0)
# Slang 已包含在 Vulkan SDK 中

# 验证安装
slangc --version
```

**Day 4-7: 基本语法**
```slang
// hello-world.slang
// 基础计算着色器

// Uniform 参数
struct Uniforms
{
    float time;
    float3 resolution;
}

// 输入输出
StructuredBuffer<float> inputBuffer;
RWStructuredBuffer<float> outputBuffer;

// 入口点
[shader("compute")]
[numthreads(256, 1, 1)]
void computeMain(
    uint3 threadId : SV_DispatchThreadID,
    Uniforms uniforms
)
{
    uint index = threadId.x;
    float value = inputBuffer[index];
    
    // 简单计算
    outputBuffer[index] = value * sin(uniforms.time);
}
```

编译运行：
```bash
# 编译为 SPIRV (Vulkan)
slangc hello-world.slang \
    -target spirv \
    -o hello-world.spv \
    -entry computeMain \
    -stage compute

# 编译为 DXIL (D3D12)
slangc hello-world.slang \
    -target dxil \
    -o hello-world.dxil \
    -entry computeMain \
    -stage compute

# 编译为 HLSL (调试用)
slangc hello-world.slang \
    -target hlsl \
    -o hello-world.hlsl \
    -entry computeMain \
    -stage compute
```

**Day 8-10: 模块系统**
```slang
// math-utils.slang
module math_utils;

export float PI = 3.14159265359;

export float3 rotate2D(float3 v, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(
        v.x * c - v.y * s,
        v.x * s + v.y * c,
        v.z
    );
}

// main.slang
import math_utils;

[shader("compute")]
[numthreads(256, 1, 1)]
void computeMain(uint3 tid : SV_DispatchThreadID)
{
    float3 v = float3(1.0, 0.0, 0.0);
    float3 rotated = rotate2D(v, PI / 4.0);  // 使用模块函数
}
```

**Day 11-14: 参数绑定**
```slang
// 参数块示例
struct ViewParams
{
    float4x4 viewProj;
    float3 cameraPos;
}

struct MaterialParams
{
    float4 albedo;
    float roughness;
    float metallic;
}

ParameterBlock<ViewParams> gView;
ParameterBlock<MaterialParams> gMaterial;

Texture2D baseColorMap;
SamplerState sampler0;

[shader("vertex")]
float4 VSMain(
    float3 pos : POSITION,
    float2 uv : TEXCOORD0
) : SV_POSITION
{
    return mul(gView.viewProj, float4(pos, 1.0));
}

[shader("fragment")]
float4 PSMain(float2 uv : TEXCOORD0) : SV_TARGET
{
    return baseColorMap.Sample(sampler0, uv) * gMaterial.albedo;
}
```

#### 实践项目
- [ ] 编写一个简单的顶点/片段着色器
- [ ] 创建自定义模块并导入使用
- [ ] 实现参数块并理解绑定机制

#### 推荐资源
- 官方 User Guide: https://shader-slang.com/slang/user-guide/
- 示例代码: `examples/hello-world/`
- Playground: https://shader-slang.com/slang-playground

---

### 阶段 2: 核心特性 (Week 3-4)

#### 目标
- 掌握泛型和接口
- 理解关联类型
- 实现多平台编译

#### 学习内容

**Week 3: 泛型与接口**

**接口定义**：
```slang
// 定义材质接口
interface IMaterial
{
    struct SurfaceInfo
    {
        float3 baseColor;
        float roughness;
        float metallic;
    };
    
    SurfaceInfo evaluate(float2 uv);
}

// 实现具体材质
struct SimpleMaterial : IMaterial
{
    Texture2D baseColorMap;
    SamplerState sampler0;
    float roughness;
    float metallic;
    
    SurfaceInfo evaluate(float2 uv)
    {
        SurfaceInfo info;
        info.baseColor = baseColorMap.Sample(sampler0, uv).rgb;
        info.roughness = roughness;
        info.metallic = metallic;
        return info;
    }
}

// 泛型函数
float4 shade<M : IMaterial>(
    float2 uv,
    float3 N,
    float3 L,
    M material
)
{
    auto surface = material.evaluate(uv);
    float NdotL = max(0.0, dot(N, L));
    return float4(surface.baseColor * NdotL, 1.0);
}
```

**关联类型**：
```slang
// 光源接口
interface ILight
{
    struct LightSample { float3 intensity; float3 direction; };
    LightSample sample(float3 pos);
}

// BRDF 接口
interface IBRDF
{
    float3 evaluate(float3 wi, float3 wo);
}

// 材质接口（使用关联类型）
interface IMaterial
{
    associatedtype B : IBRDF;  // 关联类型：每种材质的 BRDF 类型
    
    B getBRDF(float2 uv);
    float3 getBaseColor(float2 uv);
}

// Disney BRDF 实现
struct DisneyBRDF : IBRDF
{
    float roughness;
    float metallic;
    
    float3 evaluate(float3 wi, float3 wo)
    {
        // Disney BRDF 实现
        return float3(1.0);
    }
}

// Disney 材质
struct DisneyMaterial : IMaterial
{
    typedef DisneyBRDF B;  // 指定关联类型
    
    DisneyBRDF getBRDF(float2 uv) { /* ... */ }
    float3 getBaseColor(float2 uv) { /* ... */ }
}

// 使用
float4 shade<M : IMaterial>(
    float2 uv,
    float3 N,
    float3 V,
    M material
)
{
    auto brdf = material.getBRDF(uv);  // 类型为 M.B
    float3 baseColor = material.getBaseColor(uv);
    
    float3 Lo = 0.0;
    for (auto light : lights)
    {
        auto sample = light.sample(position);
        float3 Li = brdf.evaluate(sample.direction, V);
        Lo += Li * baseColor * sample.intensity;
    }
    return float4(Lo, 1.0);
}
```

**Week 4: 多平台编译**

**平台特性检测**：
```slang
// 条件编译
[shader("compute")]
[numthreads(256, 1, 1)]
void computeMain(uint3 tid : SV_DispatchThreadID)
{
#if defined(SLANG_SPIRV)
    // Vulkan 特有功能
    RaytracingAccelerationStructure accel;
    rayQueryEXT query;
    // ...
#elif defined(SLANG_HLSL)
    // D3D12 特有功能
    RaytracingAccelerationStructure accel;
    // ...
#endif
}

// Capability 系统
[require(spv_ray_tracing)]
void traceRay(RayDesc ray)
{
    // 仅在支持光线追踪的平台编译
}
```

**跨平台构建脚本**：
```bash
#!/bin/bash
# build.sh - 编译为多个平台

SHADER="pbr.slang"
ENTRY="main"
STAGE="fragment"

# D3D12 (DXIL)
slangc $SHADER -target dxil -entry $ENTRY -stage $STAGE -o output/d3d12/${ENTRY}.dxil

# Vulkan (SPIRV)
slangc $SHADER -target spirv -entry $ENTRY -stage $STAGE -o output/vulkan/${ENTRY}.spv

# Metal (MSL)
slangc $SHADER -target msl -entry $ENTRY -stage $STAGE -o output/metal/${ENTRY}.metal

# CPU (C++)
slangc $SHADER -target cxx -entry $ENTRY -stage $STAGE -o output/cpu/${ENTRY}.cpp

echo "✅ Cross-platform build complete!"
```

#### 实践项目
- [ ] 实现一个泛型光照系统
- [ ] 使用关联类型创建材质系统
- [ ] 编写跨平台构建脚本

#### 推荐资源
- 语言指南: `docs/language-guide.md`
- 接口与泛型: `docs/user-guide/06-interfaces-generics.md`
- 多平台示例: `examples/reflection-parameter-blocks/`

---

### 阶段 3: 高级特性 (Week 5-6)

#### 目标
- 掌握自动微分
- 理解 Neural Graphics 应用
- 学习 PyTorch 集成

#### 学习内容

**Week 5: 自动微分**

**前向模式**：
```slang
[Differentiable]
float quadratic(float x, float a, float b, float c)
{
    return a * x * x + b * x + c;
}

void testForward()
{
    // (值, 导数)
    DifferentialPair<float> dp_x = diffPair(2.0, 1.0);  // x=2, dx/dx=1
    DifferentialPair<float> dp_a = diffPair(1.0, 0.0);  // a=1, da/dx=0
    DifferentialPair<float> dp_b = diffPair(-3.0, 0.0); // b=-3
    DifferentialPair<float> dp_c = diffPair(2.0, 0.0);  // c=2
    
    auto result = fwd_diff(quadratic)(dp_x, dp_a, dp_b, dp_c);
    // result.p = 1*4 - 3*2 + 2 = 0 (函数值)
    // result.d = 2*1*2 - 3*1 = 1 (导数)
}
```

**反向模式（机器学习常用）**：
```slang
[Differentiable]
float3 renderScene(
    float3 rayOrigin,
    float3 rayDir,
    DifferentiableScene scene
)
{
    // 可微渲染
    float3 color = 0.0;
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float t = intersectScene(rayOrigin, rayDir, scene);
        float3 p = rayOrigin + rayDir * t;
        float3 normal = computeNormal(p, scene);
        color += shade(p, normal, scene);
    }
    return color;
}

// 训练循环（Python 端）
import slangtorch

module = slangtorch.loadModule("renderer.slang")
scene = module.DifferentiableScene()

# 前向渲染
image = module.renderScene(rayOrigin, rayDir, scene)

# 反向传播
loss = computeLoss(image, target)
loss.backward()  # 自动计算梯度

# 优化场景参数
optimizer.step()
```

**Week 6: Neural Graphics 应用**

**Neural Radiance Fields (NeRF)**：
```slang
// nerf.slang
module nerf;

[Differentiable]
struct NeRFNetwork
{
    Texture3D densityGrid;
    Texture3D colorGrid;
    
    [Differentiable]
    struct Sample
    {
        float density;
        float3 color;
    };
    
    [Differentiable]
    Sample evaluate(float3 position)
    {
        // 从网格采样（可微）
        float d = densityGrid.Sample(sampler, position).r;
        float3 c = colorGrid.Sample(sampler, position).rgb;
        return Sample(d, c);
    }
}

[Differentiable]
float3 renderNeRF(
    float3 rayOrigin,
    float3 rayDir,
    NeRFNetwork network
)
{
    float3 color = 0.0;
    float alpha = 0.0;
    
    for (int i = 0; i < STEPS; i++)
    {
        float t = i * STEP_SIZE;
        float3 p = rayOrigin + rayDir * t;
        
        auto sample = network.evaluate(p);
        
        // Alpha compositing (可微)
        float weight = sample.density * (1.0 - alpha);
        color += weight * sample.color;
        alpha += weight;
        
        if (alpha > 0.99) break;
    }
    
    return color;
}
```

**PyTorch 集成**：
```python
# train_nerf.py
import torch
import slangtorch

# 加载 Slang 模块
nerf_module = slangtorch.loadModule("nerf.slang")

# 初始化网络
network = nerf_module.NeRFNetwork()
optimizer = torch.optim.Adam(network.parameters(), lr=1e-4)

# 训练循环
for epoch in range(num_epochs):
    for rays, target in dataloader:
        # 前向渲染
        rendered = nerf_module.renderNeRF(
            rays.origin,
            rays.direction,
            network
        )
        
        # 计算损失
        loss = F.mse_loss(rendered, target)
        
        # 反向传播
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
    print(f"Epoch {epoch}, Loss: {loss.item()}")
```

#### 实践项目
- [ ] 实现一个简单的可微渲染器
- [ ] 使用 slangtorch 训练 NeRF
- [ ] 优化 3D 高斯参数

#### 推荐资源
- 自动微分指南: `docs/user-guide/07-autodiff.md`
- Neural Graphics 示例: `examples/mlp-training/`
- slangtorch 文档: https://shader-slang.com/slang/user-guide/a1-02-slangpy.html

---

### 阶段 4: 实战项目 (Week 7-8)

#### 目标
- 完成完整项目
- 性能优化
- 工程化部署

#### 项目建议

**项目 1: 跨平台 PBR 渲染器**
```
pbr-renderer/
├── shaders/
│   ├── common/
│   │   ├── math.slang
│   │   └── utils.slang
│   ├── materials/
│   │   ├── disney.slang
│   │   └── pbr.slang
│   ├── lights/
│   │   ├── point.slang
│   │   ├── directional.slang
│   │   └── area.slang
│   └── main.slang
├── build/
│   ├── d3d12/
│   ├── vulkan/
│   └── metal/
└── CMakeLists.txt
```

**项目 2: 可微路径追踪器**
```
differentiable-pathtracer/
├── kernels/
│   ├── intersection.slang
│   ├── shading.slang
│   └── integrator.slang
├── python/
│   ├── trainer.py
│   └── dataset.py
└── README.md
```

**项目 3: 材质编辑器**
```
material-editor/
├── nodes/
│   ├── texture_node.slang
│   ├── math_node.slang
│   └── output_node.slang
├── ui/
│   └── editor.cpp
└── preview/
    └── viewport.cpp
```

#### 性能优化技巧

**1. 减少寄存器压力**
```slang
// ❌ 过多临时变量
float a = ...;
float b = ...;
float c = ...;
float d = ...;
float e = ...;
// 寄存器压力过大，降低 occupancy

// ✅ 重用变量
float temp = ...;
temp = transform(temp);
temp = shade(temp);
```

**2. 特化泛型**
```slang
// ✅ 提前特化
float4 shadeDisney(float2 uv, float3 N, float3 V)
{
    DisneyMaterial mat;
    return shade(uv, N, V, mat);  // 编译时特化
}

// 避免：
// void main() { IMaterial mat = ...; shade(..., mat); }  // 运行时多态
```

**3. 参数块优化**
```slang
// ✅ 合并频繁更新的参数
struct PerFrameData { float4x4 viewProj; float3 cameraPos; }
ParameterBlock<PerFrameData> gPerFrame;  // 每帧更新一次

struct PerDrawData { float4x4 world; }
ParameterBlock<PerDrawData> gPerDraw;    // 每次绘制更新
```

#### 工程化部署

**CMake 集成**：
```cmake
# CMakeLists.txt
find_program(SLANGC slangc)

function(compile_slang target source entry stage)
    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/shaders/${target}.spv
        COMMAND ${SLANGC}
            ${CMAKE_SOURCE_DIR}/shaders/${source}
            -target spirv
            -entry ${entry}
            -stage ${stage}
            -o ${CMAKE_BINARY_DIR}/shaders/${target}.spv
        DEPENDS ${CMAKE_SOURCE_DIR}/shaders/${source}
        COMMENT "Compiling ${source} to SPIRV"
    )
endfunction()

compile_slang(vertex_main main.slang VSMain vertex)
compile_slang(fragment_main main.slang PSMain fragment)

add_custom_target(shaders ALL
    DEPENDS
        ${CMAKE_BINARY_DIR}/shaders/vertex_main.spv
        ${CMAKE_BINARY_DIR}/shaders/fragment_main.spv
)
```

## 三、学习资源汇总

### 官方资源
- 🌐 官网: https://shader-slang.com/
- 📖 User Guide: https://shader-slang.com/slang/user-guide/
- 📚 API Reference: https://shader-slang.com/stdlib-reference/
- 🎮 Playground: https://shader-slang.com/slang-playground
- 💻 GitHub: https://github.com/shader-slang/slang

### 社区资源
- 💬 Discord: https://discord.com/invite/lW7xkC (图形开发者社区)
- 📝 论文: "Slang: A Shader Compilation System for Extensible and Real-Time Shading" (SIGGRAPH 2018)

### 相关技术
- Vulkan Tutorial: https://vulkan-tutorial.com/
- Direct3D 12 Programming Guide: https://docs.microsoft.com/en-us/windows/win32/direct3d12
- PyTorch: https://pytorch.org/

## 四、常见问题

### Q1: Slang 和 HLSL 的最大区别是什么？
**A**: 模块系统和泛型。Slang 支持 import/export 和泛型编程，适合大型代码库。

### Q2: 自动微分的性能开销多大？
**A**: 前向模式约 2-3 倍，反向模式约 3-5 倍。这是自动微分的固有开销。

### Q3: Metal 支持完善吗？
**A**: 目前 Metal 支持仍为实验性，建议仅用于 D3D12 和 Vulkan。

### Q4: 如何调试 Slang 着色器？
**A**: 使用 RenderDoc 或 PIX。Slang 生成的代码保留原始标识符，便于调试。

### Q5: 可以和现有 HLSL 代码混用吗？
**A**: 可以。Slang 兼容大多数 HLSL 语法，可渐进迁移。

## 五、学习检查清单

### 阶段 1 检查
- [ ] 能编译运行简单着色器
- [ ] 理解模块系统
- [ ] 掌握参数绑定

### 阶段 2 检查
- [ ] 能编写泛型函数
- [ ] 理解接口和关联类型
- [ ] 能进行跨平台编译

### 阶段 3 检查
- [ ] 理解自动微分原理
- [ ] 能使用 slangtorch
- [ ] 实现简单 Neural Graphics 应用

### 阶段 4 检查
- [ ] 完成实战项目
- [ ] 掌握性能优化技巧
- [ ] 能工程化部署

---

**祝你学习愉快！🚀**
