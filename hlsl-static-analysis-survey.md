# HLSL 静态指令分析与性能预估工具调研

> 调研时间: 2026-04-10  
> 目标: 寻找 GitHub 上用于 HLSL 静态指令数量计算和耗时预估的高星项目

---

## 一、核心发现

### 🎯 直接相关项目

| 项目 | Stars | 描述 | 链接 |
|------|-------|------|------|
| **microsoft/DirectXShaderCompiler** | 3.5K ⭐ | DXC 官方编译器，基于 LLVM/Clang，可输出 DXIL 进行分析 | [GitHub](https://github.com/microsoft/DirectXShaderCompiler) |
| **GPUOpen-Tools/radeon_gpu_analyzer** | 468 ⭐ | **AMD RGA** - 离线编译和代码分析工具，支持 Vulkan/DirectX/OpenGL/OpenCL | [GitHub](https://github.com/GPUOpen-Tools/radeon_gpu_analyzer) |
| **KhronosGroup/SPIRV-Reflect** | 831 ⭐ | SPIR-V 反射 API，可提取着色器信息和统计 | [GitHub](https://github.com/KhronosGroup/SPIRV-Reflect) |
| **gfx-rs/naga** | 1.6K ⭐ | Rust 实现的通用着色器翻译器，WGSL↔SPIR-V↔HLSL↔MSL↔GLSL | [GitHub](https://github.com/gfx-rs/naga) |

---

## 二、详细项目分析

### 2.1 官方编译器工具链

#### Microsoft DirectX Shader Compiler (DXC)

```
⭐ 3,531 stars
```

- **仓库**: https://github.com/microsoft/DirectXShaderCompiler
- **核心能力**:
  - 基于 LLVM/Clang 的官方 HLSL 编译器
  - 输出 DXIL（DirectX Intermediate Language）
  - 支持 `-Fc` 输出汇编代码
  - 支持 `-Qi` 输出指令统计信息
  - 可集成到自定义工具链

- **关键命令**:
```bash
# 编译 HLSL 并输出汇编
dxc -T ps_6_0 -E main shader.hlsl -Fc shader.asm

# 输出指令统计
dxc -T ps_6_0 -E main shader.hlsl -Qi
```

- **DXIL 分析**:
  - 可通过 DXIL 反汇编获取指令列表
  - 指令类型统计（算术、内存、控制流）
  - 资源绑定信息

#### Microsoft ShaderConductor

```
⭐ 1,833 stars
```

- **仓库**: https://github.com/microsoft/ShaderConductor
- **描述**: 跨平台 HLSL 编译工具
- **支持格式**: HLSL → GLSL / MSL / SPIR-V
- **特点**:
  - 跨着色器语言编译
  - 支持反射信息提取

---

### 2.2 GPU 厂商分析工具

#### AMD Radeon GPU Analyzer (RGA)

```
⭐ 468 stars | AMD 官方
```

- **仓库**: https://github.com/GPUOpen-Tools/radeon_gpu_analyzer
- **核心能力**:
  - 离线编译 AMD GPU ISA
  - 指令级分析
  - 寄存器使用统计
  - 性能预估

- **支持的 API**:
  - Vulkan (SPIR-V)
  - DirectX 11/12 (HLSL → DXIL)
  - OpenGL (GLSL)
  - OpenCL

- **输出信息**:
  - ISA 汇编代码
  - 指令计数
  - 寄存器使用
  - VGPR/SGPR 统计
  - 预估执行周期

- **典型用法**:
```bash
# 分析 HLSL 着色器
rga -s hlsl -c gfx1030 -a analysis.json shader.hlsl
```

#### ARM Mali Offline Compiler Bridge (Unity)

```
⭐ 32 stars
```

- **仓库**: https://github.com/arcsearoc/UnityMaliCompilerBridge
- **描述**: Unity 编辑器集成 ARM Mali 离线编译器
- **能力**:
  - Mali GPU 指令分析
  - 性能报告生成
  - 优化建议

---

### 2.3 通用着色器工具

#### gfx-rs/naga

```
⭐ 1,569 stars | Rust
```

- **仓库**: https://github.com/gfx-rs/naga
- **描述**: 通用着色器翻译器
- **支持格式转换**:
  - WGSL ↔ SPIR-V ↔ HLSL ↔ MSL ↔ GLSL

- **分析能力**:
  - IR（中间表示）分析
  - 指令类型统计
  - 控制流分析
  - 资源使用分析

- **优势**:
  - 纯 Rust 实现，易于集成
  - 可作为库嵌入
  - 无外部依赖

#### KhronosGroup/SPIRV-Reflect

```
⭐ 831 stars | C/C++
```

- **仓库**: https://github.com/KhronosGroup/SPIRV-Reflect
- **描述**: SPIR-V 字节码反射 API
- **能力**:
  - 着色器入口点分析
  - 资源绑定信息
  - 推送常量布局
  - 输入/输出变量

- **用途**:
  - 运行时资源绑定
  - 着色器验证
  - 统计分析

#### KhronosGroup/SPIRV-Guide

```
⭐ 240 stars
```

- **仓库**: https://github.com/KhronosGroup/SPIRV-Guide
- **描述**: SPIR-V 入门指南
- **内容**:
  - SPIR-V 结构解析
  - 优化技巧
  - 工具链使用

---

### 2.4 DXIL/字节码分析工具

#### HansKristian-Work/dxil-spirv

```
⭐ 222 stars
```

- **仓库**: https://github.com/HansKristian-Work/dxil-spirv
- **描述**: DXIL 到 SPIR-V 转换
- **用途**: D3D12 翻译层

#### gongminmin/Dilithium

```
⭐ 166 stars
```

- **仓库**: https://github.com/gongminmin/Dilithium
- **描述**: DXIL ↔ SPIR-V 双向转换器
- **作者**: 龚敏敏（资深图形开发者）

#### YYadorigi/HLSL-Decompiler

```
⭐ 75 stars
```

- **仓库**: https://github.com/YYadorigi/HLSL-Decompiler
- **描述**: DXBC/DXIL/SPIR-V → HLSL 反编译
- **用途**: RenderDoc 插件

#### crossous/DXIL2HLSL

```
⭐ 42 stars
```

- **仓库**: https://github.com/crossous/DXIL2HLSL
- **描述**: DXIL 反编译工具
- **用途**: RenderDoc DXIL 着色器分析

---

### 2.5 性能分析与 Benchmark

#### renderdoc-profiler-counters

```
⭐ 7 stars
```

- **仓库**: https://github.com/wellmorq/renderdoc-profiler-counters
- **描述**: RenderDoc 性能计数器可视化工具
- **能力**:
  - GPU 性能计数器分析
  - 着色器停顿检测
  - 瓶颈识别

#### shader-translation-benchmark

```
⭐ 10 stars
```

- **仓库**: https://github.com/kvark/shader-translation-benchmark
- **描述**: 着色器翻译性能基准测试

#### shader-perf-metrics (Unity)

```
⭐ 15 stars
```

- **仓库**: https://github.com/eldnach/shader-perf-metrics
- **描述**: Unity 着色器离线编译和性能分析
- **输出**:
  - 指令计数
  - 寄存器使用
  - 纹理采样次数

---

### 2.6 优化工具

#### Google shaderc

```
⭐ 2,131 stars
```

- **仓库**: https://github.com/google/shaderc
- **描述**: Vulkan 着色器编译工具集
- **包含**:
  - glslang（GLSL → SPIR-V）
  - SPIRV-Tools（优化器）
  - SPIRV-Cross（反射）

#### SPIRV-Tools 优化器

```
⭐ 23 stars (Python API)
```

- **仓库**: https://github.com/kristerw/spirv-tools
- **描述**: SPIR-V 操作和优化 Python API
- **能力**:
  - 死代码消除
  - 常量传播
  - 内联优化

---

### 2.7 着色器反汇编工具

#### smeaLum/aemstro

```
⭐ 47 stars
```

- **仓库**: https://github.com/smealum/aemstro
- **描述**: 3DS PICA200 GPU 着色器反汇编器

#### Panfrost/ShaderProgramDisassembler

```
⭐ 3 stars
```

- **仓库**: https://github.com/Panfrost/ShaderProgramDisassembler
- **描述**: Mali Bifrost GPU 着色器反汇编器

---

## 三、技术方案对比

### 3.1 静态指令分析方案

| 方案 | 精度 | 难度 | GPU 支持 | 推荐度 |
|------|------|------|----------|--------|
| **DXC + DXIL 分析** | 高 | 中 | 仅 DX12 | ⭐⭐⭐⭐ |
| **AMD RGA** | 高 | 低 | AMD GPU | ⭐⭐⭐⭐⭐ |
| **naga IR 分析** | 中 | 低 | 通用 | ⭐⭐⭐⭐ |
| **SPIRV-Reflect** | 中 | 低 | 通用 | ⭐⭐⭐ |
| **Mali Compiler** | 高 | 低 | ARM GPU | ⭐⭐⭐⭐ |

### 3.2 耗时预估方案

| 方案 | 精度 | 难度 | 说明 |
|------|------|------|------|
| **GPU ISA 分析** | 高 | 高 | 需要厂商编译器 |
| **指令计数×权重** | 中 | 低 | 粗略估算 |
| **历史数据回归** | 中 | 中 | 需要样本数据 |
| **实测 Profiling** | 高 | 中 | 需要实际 GPU |

---

## 四、推荐技术路线

### 方案 A: DXC + 自定义 DXIL 分析器

```
HLSL → DXC → DXIL → 自定义分析器 → 指令统计
```

**优点**:
- 官方工具，稳定可靠
- DXIL 格式公开，易于解析
- 可获取精确指令列表

**缺点**:
- 仅支持 DirectX 12
- 需要自己实现分析逻辑
- 无 GPU 特定优化信息

**实现要点**:
1. 使用 DXC 编译 HLSL → DXIL
2. 使用 DXIL 反汇编获取指令
3. 统计各类指令数量
4. 根据指令类型估算性能

### 方案 B: AMD RGA 集成

```
HLSL → RGA → AMD ISA → 性能报告
```

**优点**:
- 官方工具，精度高
- 提供完整 ISA 分析
- 包含寄存器和周期信息

**缺点**:
- 仅支持 AMD GPU
- 需要安装 RGA
- 输出格式需要解析

**实现要点**:
1. 命令行调用 RGA
2. 解析 JSON 输出
3. 提取指令统计和周期预估

### 方案 C: naga 库集成

```
HLSL → naga → IR → 自定义分析 → 统计
```

**优点**:
- 纯 Rust，易于嵌入
- 支持多平台
- 可作为库使用

**缺点**:
- 精度较低
- 无 GPU 特定信息
- IR 与实际 ISA 有差异

---

## 五、快速开始指南

### 5.1 使用 DXC 分析 HLSL

```bash
# 安装 DXC
# Windows: 包含在 Windows SDK
# Linux: 从 GitHub Releases 下载

# 编译并输出汇编
dxc -T ps_6_0 -E main shader.hlsl -Fc output.asm

# 输出统计信息
dxc -T ps_6_0 -E main shader.hlsl -Qi stats.json
```

### 5.2 使用 AMD RGA

```bash
# 下载安装 RGA
# https://github.com/GPUOpen-Tools/radeon_gpu_analyzer

# 分析 HLSL
rga -s hlsl -c gfx1030 -a analysis.json shader.hlsl

# 输出 ISA
rga -s hlsl -c gfx1030 --isa output.isa shader.hlsl
```

### 5.3 使用 naga (Rust)

```rust
use naga::{front::hlsl, valid::{Capabilities, Validation}};

// 解析 HLSL
let module = hlsl::Frontend::new().parse(
    &hlsl::Options::default(),
    &hlsl_shader_source
).unwrap();

// 验证并分析
let mut validator = Validation::new(Capabilities::all());
let info = validator.validate(&module).unwrap();

// 遍历指令
for (handle, function) in module.functions.iter() {
    for block in &function.body {
        for stmt in block {
            // 分析语句...
        }
    }
}
```

---

## 六、参考资源

### 官方文档

- [DirectX Shader Compiler](https://github.com/microsoft/DirectXShaderCompiler)
- [AMD RGA Documentation](https://gpuopen.com/radeon-gpu-analyzer/)
- [SPIR-V Specification](https://www.khronos.org/registry/SPIR-V/)
- [DXIL Specification](https://github.com/microsoft/DirectXShaderCompiler/blob/main/docs/DXIL.rst)

### 工具下载

- [DXC Releases](https://github.com/microsoft/DirectXShaderCompiler/releases)
- [AMD RGA Downloads](https://github.com/GPUOpen-Tools/radeon_gpu_analyzer/releases)
- [naga crate](https://crates.io/crates/naga)

### 学习资源

- [SPIRV-Guide](https://github.com/KhronosGroup/SPIRV-Guide)
- [HLSL to DXIL 编译流程](https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-part1)

---

## 七、下一步建议

1. **快速验证**: 先用 DXC 的 `-Qi` 选项获取基础指令统计
2. **深度分析**: 集成 AMD RGA 获取 GPU 特定信息
3. **自定义工具**: 基于 naga 或 DXIL 构建专用分析器
4. **性能模型**: 结合实测数据建立指令耗时权重表

---

*调研完成时间: 2026-04-10*
