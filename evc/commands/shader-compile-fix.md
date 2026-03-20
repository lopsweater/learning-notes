---
description: Shader 编译修复。HLSL/GLSL 语法错误、常量缓冲区对齐、编译器警告。
---

# Shader 编译修复命令

此命令专门处理 Shader 编译问题，不处理 C++ 代码。

## 此命令的功能

1. 运行诊断 - DXC/FXC/glslang
2. 解析错误 - Shader 特有错误信息
3. 增量修复 - 一次修复一个错误
4. 验证每个修复 - 重新编译
5. 汇总报告 - 显示已修复和剩余问题

## 适用范围

- HLSL 编译（D3D12, DXC, FXC）
- GLSL 编译（Vulkan, glslang）
- 常量缓冲区对齐
- Shader 变体编译

## 不处理（使用其他命令）

- ❌ C++ 代码 → `/engine-cpu-build-fix` 或 `/engine-gpu-build-fix`
- ❌ 运行时 Shader 问题 → `/engine-render-debug`

## 诊断命令

```bash
# HLSL (DXC - D3D12)
dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl
dxc -T ps_6_0 -E PSMain shaders/pbr.hlsl

# HLSL (FXC - D3D11)
fxc /T vs_5_0 /E VSMain shaders/pbr.hlsl
fxc /T ps_5_0 /E PSMain shaders/pbr.hlsl

# GLSL (Vulkan)
glslangValidator -V shaders/pbr.vert
glslangValidator -V shaders/pbr.frag

# SPIR-V 交叉编译
glslangValidator -V shaders/pbr.vert -o pbr.vert.spv
```

## 常见错误修复表

| 错误 | 典型修复 |
|------|----------|
| `X3000: syntax error` | 检查分号、括号、大括号 |
| `X3004: undeclared identifier` | 添加变量声明或 include |
| `X3501: not all control paths return a value` | 添加 return 语句 |
| `X3512: sampler array not supported` | 使用 Bindless 或 Texture2DArray |
| `constant buffer alignment` | 16 字节对齐，添加 padding |
| `shader model not supported` | 更新目标 Shader Model |
| `resource register overlap` | 检查 register 绑定 |

## 常量缓冲区对齐规则

### HLSL 规则

1. **16 字节边界对齐**
2. **每个元素必须在 16 字节内**
3. **跨 16 字节边界需要 padding**

```hlsl
// 错误：未对齐
cbuffer SceneConstants : register(b0) {
    float3 CameraPosition;  // 12 字节
    float3 LightDirection;  // 12 字节 - 跨边界！
}

// 正确：添加 padding
cbuffer SceneConstants : register(b0) {
    float3 CameraPosition;  // 12 字节
    float  Padding1;        // 4 字节 - 补齐到 16
    float3 LightDirection;  // 12 字节
    float  Padding2;        // 4 字节
}

// 推荐：使用 float4
cbuffer SceneConstants : register(b0) {
    float4 CameraPosition;   // 16 字节
    float4 LightDirection;   // 16 字节
}
```

### 矩阵对齐

```hlsl
cbuffer TransformConstants : register(b0) {
    float4x4 WorldMatrix;      // 64 字节
    float4x4 ViewMatrix;       // 64 字节
    float4x4 ProjectionMatrix; // 64 字节
}
```

## 示例会话

用户: /shader-compile-fix

Agent:
# Shader 编译修复会话

## 初始诊断

```bash
$ dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl

shaders/pbr.hlsl:25:5: error: X3004: undeclared identifier 'WorldMatrix'
shaders/pbr.hlsl:42:9: error: X3000: syntax error: unexpected token '}'
shaders/pbr.hlsl:58:1: warning X3550: array reference cannot be used as an l-value
```

发现错误：2 个，警告：1 个

## 修复 1：未声明标识符

文件：shaders/pbr.hlsl:25
错误：undeclared identifier 'WorldMatrix'

```hlsl
// 添加常量缓冲区声明
cbuffer TransformConstants : register(b0) {
    float4x4 WorldMatrix;
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
};

// 或使用 include
#include "common/transform_constants.hlsl"
```

```bash
$ dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl
# 剩余 1 个错误
```

## 修复 2：语法错误

文件：shaders/pbr.hlsl:42
错误：unexpected token '}'

```hlsl
// 检查缺失的分号或括号

// 错误示例
float4 PSMain(PSInput input) : SV_TARGET {
    float3 color = input.color
}  // 缺少分号

// 修复
float4 PSMain(PSInput input) : SV_TARGET {
    float3 color = input.color;
    return float4(color, 1.0);
}
```

```bash
$ dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl
# 编译成功！
```

## 修复 3：警告处理

文件：shaders/pbr.hlsl:58
警告：array reference cannot be used as an l-value

```hlsl
// 警告代码
float values[4];
values[0] = 1.0;  // 警告

// 使用临时变量
float values[4] = { 1.0, 0.0, 0.0, 0.0 };
```

```bash
$ dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl
# 无警告！
```

## 最终验证

```bash
$ dxc -T vs_6_0 -E VSMain shaders/pbr.hlsl -Fo pbr.vs.cso
$ dxc -T ps_6_0 -E PSMain shaders/pbr.hlsl -Fo pbr.ps.cso

Compilation succeeded.
```

## 汇总

| 指标 | 数量 |
|------|------|
| 编译错误修复 | 2 |
| 编译警告修复 | 1 |
| 修改文件数 | 1 |
| 剩余问题 | 0 |

编译状态：✅ 成功

## Shader 目录结构建议

```
shaders/
├── common/
│   ├── transform_constants.hlsl
│   ├── lighting.hlsl
│   └── utils.hlsl
├── pbr/
│   ├── pbr.hlsl
│   ├── pbr.vs.hlsl
│   └── pbr.ps.hlsl
└── postprocess/
    ├── tonemapping.hlsl
    └── bloom.hlsl
```

## 相关命令

- `/engine-gpu-build-fix` - C++ GPU 代码构建
- `/engine-render-debug` - 渲染管线调试

## 相关 Skills

- `skills/engine-shader-development/`
