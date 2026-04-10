# AMD Radeon GPU Analyzer (RGA) 部署集成指南

> 更新时间: 2026-04-10
> 版本: RGA 2.14.1

---

## 一、RGA 简介

Radeon GPU Analyzer (RGA) 是 AMD 官方的离线编译器和代码分析工具，支持：

- **Vulkan** (GLSL/SPIR-V)
- **DirectX 12/11** (HLSL)
- **OpenGL** (GLSL)
- **OpenCL**

**核心输出**:
- RDNA/GCN ISA 反汇编
- 硬件资源统计（寄存器、内存）
- 编译后的二进制
- 性能周期预估
- 控制流图

---

## 二、快速部署

### 方案 A: 下载预编译版本 (推荐)

#### Windows

```bash
# 下载 MSI 安装包
wget https://github.com/GPUOpen-Tools/radeon_gpu_analyzer/releases/download/2.14.1/rga-windows-2.14.1.msi

# 或下载 ZIP 便携版
wget https://github.com/GPUOpen-Tools/radeon_gpu_analyzer/releases/download/2.14.1/rga-windows-x64-2.14.1.zip

# 安装后，CLI 位于：
# C:\Program Files\Radeon GPU Analyzer\rga.exe
```

#### Linux (Ubuntu 22.04/24.04)

```bash
# 下载
wget https://github.com/GPUOpen-Tools/radeon_gpu_analyzer/releases/download/2.14.1/rga-linux-2.14.1.tgz

# 解压
tar -xzf rga-linux-2.14.1.tgz
cd rga

# 验证
./rga -h
```

### 方案 B: 从源码编译

#### Linux 编译步骤

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y \
    libboost-all-dev \
    gcc-multilib g++-multilib \
    libglu1-mesa-dev mesa-common-dev \
    libgtk2.0-dev \
    zlib1g-dev libx11-dev:i386 \
    patchelf \
    cmake python3

# 2. 安装 Vulkan SDK (1.2.162.1+)
wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.xz
tar -xf vulkan-sdk.tar.xz
# 按照 SDK 说明安装

# 3. 克隆仓库
git clone https://github.com/GPUOpen-Tools/radeon_gpu_analyzer.git
cd radeon_gpu_analyzer

# 4. 构建前准备
cd build
python3 pre_build.py --qt 6.7.0 \
    --vk-include /path/to/vulkan-sdk/include \
    --vk-lib /path/to/vulkan-sdk/lib

# 5. 编译
cd build/linux/make
make -j$(nproc)

# CLI 输出位置:
# build/linux/make/rga
```

#### Windows 编译步骤

```powershell
# 1. 安装依赖
# - Visual Studio 2019/2022
# - CMake 3.21+
# - Python 3.10+
# - Qt 6.7.0 (可选，用于 GUI)

# 2. 克隆仓库
git clone https://github.com/GPUOpen-Tools/radeon_gpu_analyzer.git
cd radeon_gpu_analyzer

# 3. 构建前准备
cd build
python pre_build.py --qt 6.7.0 --vs 2022

# 4. 打开解决方案编译
# build\windows\vs2022\RGA.sln
# 编译 RadeonGPUAnalyzerCLI 项目
```

---

## 三、命令行使用

### 3.1 帮助信息

```bash
# 通用帮助
rga -h

# DirectX 12 模式
rga -s dx12 -h

# DirectX 11 模式
rga -s dx11 -h

# Vulkan 模式
rga -s vulkan -h

# OpenCL 离线模式
rga -s opencl -h
```

### 3.2 DirectX 12 / HLSL 分析

```bash
# 基础编译：HLSL → ISA
rga -s dx12 -c gfx1030 --isa output.isa shader.hlsl

# 完整分析报告 (JSON)
rga -s dx12 -c gfx1030 -a analysis.json shader.hlsl

# 指定着色器模型和入口点
rga -s dx12 -c gfx1030 \
    --shader-model ps_6_0 \
    --entry main \
    --isa output.isa \
    shader.hlsl

# 输出多种格式
rga -s dx12 -c gfx1030 \
    --isa output.isa \
    --amdil output.amdil \
    --dxil output.dxil \
    shader.hlsl

# 性能分析（包含周期预估）
rga -s dx12 -c gfx1030 \
    --analysis analysis.json \
    --livereg vgpr_report.txt \
    shader.hlsl
```

### 3.3 目标 GPU 架构

```bash
# 列出支持的 GPU 架构
rga -s dx12 --list-asics

# 常见架构:
# gfx1030  - RDNA 2 (RX 6800/6900)
# gfx1100  - RDNA 3 (RX 7900)
# gfx1153  - RDNA 3.5
# gfx950   - CDNA 4 (MI-350)
# gfx900   - GCN 5 (Vega)
# gfx803   - GCN 4 (Polaris)
```

### 3.4 输出分析

**JSON 分析报告结构**:

```json
{
  "pipeline": {
    "shaders": [{
      "type": "PS",
      "entry_point": "main",
      "hardware_stages": [{
        "asic": "gfx1030",
        "statistics": {
          "vgprs": 32,
          "sgprs": 48,
          "lds_size": 0,
          "isa_size": 1024,
          "instructions": {
            "total": 256,
            "salo": 64,
            "valu": 128,
            "mfma": 0
          },
          "performance": {
            "estimated_cycles": 1500,
            "bottleneck": "throughput"
          }
        }
      }]
    }]
  }
}
```

---

## 四、集成方案

### 4.1 作为 CLI 工具集成

```python
#!/usr/bin/env python3
"""RGA 集成示例"""

import subprocess
import json
from pathlib import Path

class RGAAnalyzer:
    def __init__(self, rga_path: str = "rga"):
        self.rga_path = rga_path
    
    def analyze_hlsl(
        self,
        hlsl_path: str,
        target_gpu: str = "gfx1030",
        shader_model: str = "ps_6_0",
        entry_point: str = "main"
    ) -> dict:
        """分析 HLSL 着色器"""
        
        output_json = Path(hlsl_path).with_suffix('.rga.json')
        output_isa = Path(hlsl_path).with_suffix('.isa')
        
        cmd = [
            self.rga_path,
            "-s", "dx12",
            "-c", target_gpu,
            "--shader-model", shader_model,
            "--entry", entry_point,
            "--isa", str(output_isa),
            "-a", str(output_json),
            hlsl_path
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            raise RuntimeError(f"RGA 分析失败: {result.stderr}")
        
        # 读取分析结果
        with open(output_json) as f:
            return json.load(f)
    
    def extract_stats(self, analysis: dict) -> dict:
        """提取关键统计数据"""
        shaders = analysis.get("pipeline", {}).get("shaders", [])
        if not shaders:
            return {}
        
        hw = shaders[0].get("hardware_stages", [{}])[0]
        stats = hw.get("statistics", {})
        
        return {
            "vgprs": stats.get("vgprs", 0),
            "sgprs": stats.get("sgprs", 0),
            "isa_size": stats.get("isa_size", 0),
            "total_instructions": stats.get("instructions", {}).get("total", 0),
            "estimated_cycles": stats.get("performance", {}).get("estimated_cycles", 0),
        }


# 使用示例
if __name__ == "__main__":
    analyzer = RGAAnalyzer("/path/to/rga")
    result = analyzer.analyze_hlsl("shader.hlsl")
    stats = analyzer.extract_stats(result)
    
    print(f"VGPR 使用: {stats['vgprs']}")
    print(f"指令总数: {stats['total_instructions']}")
    print(f"预估周期: {stats['estimated_cycles']}")
```

### 4.2 作为 CI/CD 集成

```yaml
# .github/workflows/shader-analysis.yml
name: Shader Analysis

on:
  push:
    paths: ['shaders/**']

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install RGA
        run: |
          wget https://github.com/GPUOpen-Tools/radeon_gpu_analyzer/releases/download/2.14.1/rga-linux-2.14.1.tgz
          tar -xzf rga-linux-2.14.1.tgz
          echo "$(pwd)/rga" >> $GITHUB_PATH
      
      - name: Analyze Shaders
        run: |
          for shader in shaders/*.hlsl; do
            rga -s dx12 -c gfx1030 -a "${shader}.json" "$shader"
          done
      
      - name: Upload Reports
        uses: actions/upload-artifact@v4
        with:
          name: shader-analysis
          path: shaders/*.json
```

### 4.3 作为服务部署

```python
#!/usr/bin/env python3
"""RGA HTTP 服务"""

from flask import Flask, request, jsonify
import subprocess
import tempfile
import json

app = Flask(__name__)

RGA_PATH = "/opt/rga/rga"

@app.route("/analyze", methods=["POST"])
def analyze():
    """分析 HLSL 着色器"""
    data = request.json
    
    hlsl_code = data.get("code")
    target_gpu = data.get("target", "gfx1030")
    shader_model = data.get("shader_model", "ps_6_0")
    entry = data.get("entry", "main")
    
    # 写入临时文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.hlsl', delete=False) as f:
        f.write(hlsl_code)
        hlsl_path = f.name
    
    output_json = hlsl_path.replace('.hlsl', '.json')
    
    # 调用 RGA
    cmd = [
        RGA_PATH, "-s", "dx12",
        "-c", target_gpu,
        "--shader-model", shader_model,
        "--entry", entry,
        "-a", output_json,
        hlsl_path
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        return jsonify({"error": result.stderr}), 400
    
    # 返回分析结果
    with open(output_json) as f:
        analysis = json.load(f)
    
    return jsonify(analysis)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

---

## 五、离线模式说明

RGA 支持 **离线模式**，无需 AMD GPU 或驱动：

| 模式 | 需要驱动/硬件 | 说明 |
|------|--------------|------|
| DX12 离线 | ❌ 不需要 | 使用静态编译器 |
| DX11 | ❌ 不需要 | 需要 D3DCompiler_47.dll |
| Vulkan 离线 | ❌ 不需要 | 使用静态编译器 |
| OpenCL 离线 | ❌ 不需要 | 使用 LLVM 编译器 |
| Vulkan 实时 | ✅ 需要 | 需要 AMD 驱动 |
| DX12 实时 | ✅ 需要 | 需要 AMD 驱动 |

---

## 六、注意事项

### 6.1 Linux 驱动变化

> 从 25.20 驱动开始，AMDVLK 驱动不再包含在 amdgpu-pro 中。RADV 成为默认 Vulkan 驱动。
> 
> RGA 仍支持离线 Vulkan 模式，但实时驱动编译需要额外配置。

### 6.2 性能预估变化

> RGA 2.14 开始，GUI 版本不再显示周期预估。
> 
> CLI 版本仍保留周期预估用于向后兼容。
> 
> AMD 正在开发新的性能预估机制。

### 6.3 DX11 模式

需要在 `utils/` 目录放置 `D3DCompiler_47.dll`:

```
rga/
├── rga.exe
├── utils/
│   └── D3DCompiler_47.dll
└── ...
```

---

## 七、参考资源

- **官方仓库**: https://github.com/GPUOpen-Tools/radeon_gpu_analyzer
- **最新版本**: 2.14.1 (2025-12-11)
- **文档**: https://gpuopen.com/radeon-gpu-analyzer/
- **Live VGPR 分析**: http://gpuopen.com/learn/live-vgpr-analysis-radeon-gpu-analyzer/

---

## 八、快速命令速查

```bash
# 查看帮助
rga -h
rga -s dx12 -h

# 列出支持的 GPU
rga -s dx12 --list-asics

# HLSL 基础分析
rga -s dx12 -c gfx1030 -a out.json shader.hlsl

# 完整分析
rga -s dx12 -c gfx1030 \
    --isa out.isa \
    --amdil out.amdil \
    --analysis out.json \
    --livereg vgpr.txt \
    shader.hlsl

# 指定着色器类型
rga -s dx12 -c gfx1030 \
    --shader-model vs_6_0 \
    --entry VSMain \
    shader.hlsl
```

---

*文档更新时间: 2026-04-10*
