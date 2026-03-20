# 帧图模式

## 概述

帧图（Frame Graph）用于管理帧内资源生命周期，自动处理资源别名和内存复用。

## 设计目标

- ✅ 自动管理资源生命周期
- ✅ 资源内存别名（Memory Aliasing）
- ✅ Pass 依赖分析
- ✅ 资源状态自动转换

## 基本结构

```cpp
// Pass 节点
struct PassNode {
    std::string name;
    std::vector<ResourceHandle> reads;
    std::vector<ResourceHandle> writes;
    std::function<void(RHICommandList*)> execute;
};

// 资源节点
struct ResourceNode {
    std::string name;
    TextureDesc desc;
    uint32_t firstUsePass;
    uint32_t lastUsePass;
    RHITexture* texture;
    uint32_t aliasOf;  // 别名资源索引
};

// 帧图
class FrameGraph {
    std::vector<PassNode> m_passes;
    std::vector<ResourceNode> m_resources;
    
public:
    // 创建资源
    ResourceHandle CreateResource(const std::string& name, const TextureDesc& desc) {
        ResourceNode node;
        node.name = name;
        node.desc = desc;
        node.firstUsePass = UINT32_MAX;
        node.lastUsePass = 0;
        
        m_resources.push_back(node);
        return ResourceHandle(m_resources.size() - 1);
    }
    
    // 添加 Pass
    template<typename Setup, typename Execute>
    void AddPass(const std::string& name, Setup setup, Execute execute) {
        PassNode pass;
        pass.name = name;
        
        PassBuilder builder(pass);
        setup(builder);
        
        pass.execute = execute;
        m_passes.push_back(std::move(pass));
    }
    
    // 编译
    void Compile() {
        // 1. 分析资源生命周期
        for (uint32_t i = 0; i < m_passes.size(); i++) {
            for (auto handle : m_passes[i].reads) {
                m_resources[handle].firstUsePass = std::min(
                    m_resources[handle].firstUsePass, i);
            }
            for (auto handle : m_passes[i].writes) {
                m_resources[handle].lastUsePass = std::max(
                    m_resources[handle].lastUsePass, i);
            }
        }
        
        // 2. 资源别名分析
        AnalyzeAliasing();
        
        // 3. 分配实际资源
        AllocateResources();
    }
    
    // 执行
    void Execute(RHICommandList* cmdList) {
        for (auto& pass : m_passes) {
            pass.execute(cmdList);
        }
    }
};
```

## Pass Builder

```cpp
class PassBuilder {
    PassNode& m_pass;
    
public:
    // 读取资源
    ResourceHandle Read(ResourceHandle resource) {
        m_pass.reads.push_back(resource);
        return resource;
    }
    
    // 写入资源
    ResourceHandle Write(ResourceHandle resource) {
        m_pass.writes.push_back(resource);
        return resource;
    }
    
    // 创建临时资源
    ResourceHandle CreateTransient(const std::string& name, const TextureDesc& desc) {
        auto handle = m_frameGraph->CreateResource(name, desc);
        m_pass.writes.push_back(handle);
        return handle;
    }
};
```

## 资源别名

```cpp
void FrameGraph::AnalyzeAliasing() {
    // 按生命周期排序资源
    std::vector<size_t> sortedResources(m_resources.size());
    std::iota(sortedResources.begin(), sortedResources.end(), 0);
    
    std::sort(sortedResources.begin(), sortedResources.end(),
        [&](size_t a, size_t b) {
            return m_resources[a].firstUsePass < m_resources[b].firstUsePass;
        });
    
    // 检测不重叠的资源
    for (size_t i = 0; i < sortedResources.size(); i++) {
        for (size_t j = i + 1; j < sortedResources.size(); j++) {
            auto& resA = m_resources[sortedResources[i]];
            auto& resB = m_resources[sortedResources[j]];
            
            // 生命周期不重叠？
            if (resA.lastUsePass < resB.firstUsePass ||
                resB.lastUsePass < resA.firstUsePass) {
                // 可以别名
                resB.aliasOf = sortedResources[i];
                break;
            }
        }
    }
}

void FrameGraph::AllocateResources() {
    for (auto& res : m_resources) {
        if (res.aliasOf != UINT32_MAX) {
            // 使用别名资源
            res.texture = m_resources[res.aliasOf].texture;
        } else {
            // 创建新资源
            res.texture = m_device->CreateTexture(res.desc);
        }
    }
}
```

## 使用示例

```cpp
FrameGraph fg(device);

// Shadow Pass
fg.AddPass("ShadowPass",
    [&](PassBuilder& builder) {
        auto shadowMap = builder.CreateTransient("ShadowMap", 
            {TextureDimension::Texture2D, Format::D32Float, 2048, 2048, 1, 1, 1,
             TextureUsage::DepthStencil, ResourceState::DepthWrite});
        builder.Write(shadowMap);
    },
    [&](RHICommandList* cmdList) {
        // 渲染阴影
    }
);

// GBuffer Pass
fg.AddPass("GBufferPass",
    [&](PassBuilder& builder) {
        builder.Read(depthBuffer);
        builder.Write(albedoRT);
        builder.Write(normalRT);
    },
    [&](RHICommandList* cmdList) {
        // 渲染 GBuffer
    }
);

// Lighting Pass
fg.AddPass("LightingPass",
    [&](PassBuilder& builder) {
        builder.Read(shadowMap);
        builder.Read(albedoRT);
        builder.Read(normalRT);
        builder.Write(finalRT);
    },
    [&](RHICommandList* cmdList) {
        // 光照计算
    }
);

fg.Compile();
fg.Execute(cmdList);
```

## 相关文件

- [render-graph.md](./render-graph.md) - 渲染图（高级抽象）
- [resource-pool.md](./resource-pool.md) - 资源池模式
