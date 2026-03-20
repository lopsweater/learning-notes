# 渲染图模式

## 概述

渲染图（Render Graph）是帧图的升级版，提供更高层次的抽象，自动处理资源屏障和状态转换。

## 与帧图的区别

| 特性 | Frame Graph | Render Graph |
|------|-------------|--------------|
| 资源管理 | 手动生命周期 | 自动推断 |
| Barrier | 手动插入 | 自动生成 |
| Pass 依赖 | 部分自动 | 完全自动 |
| 资源别名 | 手动分析 | 自动检测 |

## 设计

```cpp
// 渲染图
class RenderGraph {
    struct Pass {
        std::string name;
        std::vector<ResourceHandle> inputs;
        std::vector<ResourceHandle> outputs;
        std::function<void(RHICommandList*, const Resources&)> execute;
        
        // 自动生成
        std::vector<ResourceBarrier> barriers;
    };
    
    std::vector<Pass> m_passes;
    std::vector<Resource> m_resources;
    
public:
    // 声明资源
    ResourceHandle CreateTexture(const TextureDesc& desc) {
        m_resources.push_back({desc, ResourceState::Common, nullptr});
        return ResourceHandle(m_resources.size() - 1);
    }
    
    // 添加 Pass
    void AddPass(
        const std::string& name,
        const std::vector<ResourceHandle>& inputs,
        const std::vector<ResourceHandle>& outputs,
        std::function<void(RHICommandList*, const Resources&)> execute
    ) {
        Pass pass;
        pass.name = name;
        pass.inputs = inputs;
        pass.outputs = outputs;
        pass.execute = execute;
        m_passes.push_back(std::move(pass));
    }
    
    // 编译
    void Compile() {
        // 1. 构建依赖图
        BuildDependencyGraph();
        
        // 2. 拓扑排序
        TopologicalSort();
        
        // 3. 生成 Barrier
        GenerateBarriers();
        
        // 4. 资源别名分析
        AnalyzeAliasing();
    }
    
    // 执行
    void Execute(RHICommandList* cmdList) {
        for (auto& pass : m_passes) {
            // 插入 Barrier
            for (const auto& barrier : pass.barriers) {
                cmdList->ResourceBarrier(barrier.resource, barrier.from, barrier.to);
            }
            
            // 执行 Pass
            Resources res(m_resources);
            pass.execute(cmdList, res);
        }
    }
};
```

## 自动 Barrier 生成

```cpp
void RenderGraph::GenerateBarriers() {
    // 追踪资源状态
    std::vector<ResourceState> currentStates(m_resources.size(), ResourceState::Common);
    
    for (auto& pass : m_passes) {
        // 输入资源 Barrier
        for (auto handle : pass.inputs) {
            auto targetState = GetReadState(m_resources[handle].desc);
            
            if (currentStates[handle] != targetState) {
                pass.barriers.push_back({
                    m_resources[handle].texture,
                    currentStates[handle],
                    targetState
                });
                currentStates[handle] = targetState;
            }
        }
        
        // 输出资源 Barrier
        for (auto handle : pass.outputs) {
            auto targetState = GetWriteState(m_resources[handle].desc);
            
            if (currentStates[handle] != targetState) {
                pass.barriers.push_back({
                    m_resources[handle].texture,
                    currentStates[handle],
                    targetState
                });
                currentStates[handle] = targetState;
            }
        }
    }
}

ResourceState RenderGraph::GetReadState(const Resource& res) {
    if (res.desc.usage & TextureUsage::DepthStencil) {
        return ResourceState::DepthRead;
    }
    return ResourceState::ShaderResource;
}

ResourceState RenderGraph::GetWriteState(const Resource& res) {
    if (res.desc.usage & TextureUsage::RenderTarget) {
        return ResourceState::RenderTarget;
    }
    if (res.desc.usage & TextureUsage::DepthStencil) {
        return ResourceState::DepthWrite;
    }
    if (res.desc.usage & TextureUsage::UnorderedAccess) {
        return ResourceState::UnorderedAccess;
    }
    return ResourceState::Common;
}
```

## 使用示例

```cpp
RenderGraph rg(device);

// 创建资源
auto shadowMap = rg.CreateTexture({Format::D32Float, 2048, 2048, TextureUsage::DepthStencil});
auto albedoRT = rg.CreateTexture({Format::RGBA8, 1920, 1080, TextureUsage::RenderTarget});
auto normalRT = rg.CreateTexture({Format::RGBA16Float, 1920, 1080, TextureUsage::RenderTarget});
auto finalRT = rg.CreateTexture({Format::RGBA8, 1920, 1080, TextureUsage::RenderTarget});

// Shadow Pass
rg.AddPass("Shadow", {}, {shadowMap}, [&](RHICommandList* cmd, const Resources& res) {
    cmd->SetRenderTarget(nullptr, res.GetTexture(shadowMap));
    RenderShadow(cmd);
});

// GBuffer Pass
rg.AddPass("GBuffer", {}, {albedoRT, normalRT}, [&](RHICommandList* cmd, const Resources& res) {
    cmd->SetRenderTargets({res.GetTexture(albedoRT), res.GetTexture(normalRT)});
    RenderGBuffer(cmd);
});

// Lighting Pass
rg.AddPass("Lighting", {shadowMap, albedoRT, normalRT}, {finalRT}, 
    [&](RHICommandList* cmd, const Resources& res) {
        cmd->SetShaderResource(res.GetTexture(shadowMap), 0);
        cmd->SetShaderResource(res.GetTexture(albedoRT), 1);
        cmd->SetShaderResource(res.GetTexture(normalRT), 2);
        cmd->SetRenderTarget(res.GetTexture(finalRT));
        RenderLighting(cmd);
    }
);

rg.Compile();
rg.Execute(cmdList);
```

## 相关文件

- [frame-graph.md](./frame-graph.md) - 帧图模式
- [state-tracking.md](./state-tracking.md) - 状态追踪
