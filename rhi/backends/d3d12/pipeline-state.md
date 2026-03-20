# D3D12 管线状态对象

## 概述

管线状态对象 (PSO) 将渲染管线的所有状态打包成一个不可变对象。

## 创建 Graphics PSO

```cpp
D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};

// 根签名
psoDesc.pRootSignature = rootSignature;

// 着色器
psoDesc.VS = { vsBytecode, vsSize };
psoDesc.PS = { psBytecode, psSize };
psoDesc.GS = { gsBytecode, gsSize };      // 可选
psoDesc.HS = { hsBytecode, hsSize };      // 可选
psoDesc.DS = { dsBytecode, dsSize };      // 可选

// 混合状态
CD3DX12_BLEND_DESC blendDesc(D3D12_DEFAULT);
psoDesc.BlendState = blendDesc;

// 光栅化状态
CD3DX12_RASTERIZER_DESC rasterizerDesc(D3D12_DEFAULT);
psoDesc.RasterizerState = rasterizerDesc;

// 深度模板状态
CD3DX12_DEPTH_STENCIL_DESC depthStencilDesc(D3D12_DEFAULT);
psoDesc.DepthStencilState = depthStencilDesc;

// 输入布局
D3D12_INPUT_ELEMENT_DESC inputLayout[] = {
    { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,
      D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
    { "NORMAL", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 12,
      D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
    { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 24,
      D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
};
psoDesc.InputLayout = { inputLayout, _countof(inputLayout) };

// 图元拓扑
psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;

// 渲染目标格式
psoDesc.NumRenderTargets = 1;
psoDesc.RTVFormats[0] = DXGI_FORMAT_R8G8B8A8_UNORM;
psoDesc.DSVFormat = DXGI_FORMAT_D32_FLOAT;

// 采样
psoDesc.SampleDesc = { 1, 0 };
psoDesc.SampleMask = UINT_MAX;

// 创建 PSO
ID3D12PipelineState* pso;
device->CreateGraphicsPipelineState(&psoDesc, IID_PPV_ARGS(&pso));
```

## 创建 Compute PSO

```cpp
D3D12_COMPUTE_PIPELINE_STATE_DESC computeDesc = {};
computeDesc.pRootSignature = rootSignature;
computeDesc.CS = { csBytecode, csSize };

ID3D12PipelineState* computePso;
device->CreateComputePipelineState(&computeDesc, IID_PPV_ARGS(&computePso));
```

## 常见混合状态

```cpp
// Alpha 混合
D3D12_BLEND_DESC alphaBlend = {};
alphaBlend.RenderTarget[0].BlendEnable = TRUE;
alphaBlend.RenderTarget[0].SrcBlend = D3D12_BLEND_SRC_ALPHA;
alphaBlend.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
alphaBlend.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
alphaBlend.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
alphaBlend.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
alphaBlend.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
alphaBlend.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;

// 加法混合
D3D12_BLEND_DESC additiveBlend = {};
additiveBlend.RenderTarget[0].BlendEnable = TRUE;
additiveBlend.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
additiveBlend.RenderTarget[0].DestBlend = D3D12_BLEND_ONE;
additiveBlend.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
```

## 常见光栅化状态

```cpp
// 线框模式
D3D12_RASTERIZER_DESC wireframe = {};
wireframe.FillMode = D3D12_FILL_MODE_WIREFRAME;
wireframe.CullMode = D3D12_CULL_MODE_NONE;
wireframe.FrontCounterClockwise = FALSE;
wireframe.DepthClipEnable = TRUE;

// 双面渲染
D3D12_RASTERIZER_DESC doubleSided = {};
doubleSided.FillMode = D3D12_FILL_MODE_SOLID;
doubleSided.CullMode = D3D12_CULL_MODE_NONE;
```

## 使用 PSO

```cpp
commandList->SetPipelineState(pso);
commandList->SetGraphicsRootSignature(rootSignature);
// ... 其他绑定和绘制
```

## 相关文件

- [root-signature.md](./root-signature.md) - 根签名
- [features.md](./features.md) - 核心特性
