# 状态追踪

## 概述

状态追踪用于自动管理资源状态转换，避免手动编写 Resource Barrier 带来的复杂性和错误。

## 问题背景

### 手动状态管理的困难

```cpp
// 错误示例：忘记状态转换
texture->SetData(data);  // 状态：CopyDst
// 缺少 Barrier！
shader->UseTexture(texture);  // 错误：状态不匹配

// 正确但繁琐的方式
texture->SetData(data);
cmdList->ResourceBarrier(texture, ResourceState::CopyDst, ResourceState::ShaderResource);
shader->UseTexture(texture);
```

## 自动状态追踪

### 状态追踪器

```cpp
class ResourceStateTracker {
    struct ResourceStateEntry {
        ResourceState state;
        uint32_t subresourceCount;
        std::vector<ResourceState> subresourceStates;
    };
    
    std::unordered_map<RHIResource*, ResourceStateEntry> m_states;
    
public:
    // 获取当前状态
    ResourceState GetState(RHIResource* resource, uint32_t subresource = 0) {
        auto it = m_states.find(resource);
        if (it == m_states.end()) {
            return ResourceState::Common;
        }
        
        if (subresource == ALL_SUBRESOURCES) {
            return it->second.state;
        }
        return it->second.subresourceStates[subresource];
    }
    
    // 设置目标状态
    void SetState(RHIResource* resource, ResourceState state, uint32_t subresource = 0) {
        auto& entry = m_states[resource];
        
        if (subresource == ALL_SUBRESOURCES) {
            entry.state = state;
            for (auto& s : entry.subresourceStates) {
                s = state;
            }
        } else {
            entry.subresourceStates[subresource] = state;
        }
    }
    
    // 需要转换吗？
    bool NeedsTransition(RHIResource* resource, ResourceState targetState, uint32_t subresource = 0) {
        return GetState(resource, subresource) != targetState;
    }
    
    // 生成 Barrier
    std::vector<ResourceBarrier> GetTransitionBarriers(
        RHIResource* resource, 
        ResourceState targetState
    ) {
        std::vector<ResourceBarrier> barriers;
        
        auto currentState = GetState(resource);
        if (currentState != targetState) {
            barriers.push_back({resource, currentState, targetState});
            SetState(resource, targetState);
        }
        
        return barriers;
    }
};
```

### 自动 Barrier 插入

```cpp
class AutoBarrierCommandList : public RHICommandList {
    RHICommandList* m_inner;
    ResourceStateTracker* m_tracker;
    
public:
    void SetRenderTarget(RHITexture* texture) override {
        // 自动插入 Barrier
        auto barriers = m_tracker->GetTransitionBarriers(
            texture, ResourceState::RenderTarget
        );
        
        if (!barriers.empty()) {
            m_inner->ResourceBarriers(barriers);
        }
        
        m_inner->SetRenderTarget(texture);
    }
    
    void SetShaderResource(RHITexture* texture, uint32_t slot) override {
        auto barriers = m_tracker->GetTransitionBarriers(
            texture, ResourceState::ShaderResource
        );
        
        if (!barriers.empty()) {
            m_inner->ResourceBarriers(barriers);
        }
        
        m_inner->SetShaderResource(texture, slot);
    }
    
    void CopyTexture(RHITexture* dst, RHITexture* src) override {
        auto barriers = m_tracker->GetTransitionBarriers(dst, ResourceState::CopyDst);
        auto srcBarriers = m_tracker->GetTransitionBarriers(src, ResourceState::CopySrc);
        
        barriers.insert(barriers.end(), srcBarriers.begin(), srcBarriers.end());
        
        if (!barriers.empty()) {
            m_inner->ResourceBarriers(barriers);
        }
        
        m_inner->CopyTexture(dst, src);
    }
};
```

## 状态缓存

```cpp
// 缓存资源状态，避免重复查询
class StateCache {
    struct CacheEntry {
        RHIResource* resource;
        ResourceState state;
        uint64_t frameIndex;
    };
    
    std::unordered_map<RHIResource*, CacheEntry> m_cache;
    uint64_t m_currentFrame = 0;
    
public:
    ResourceState GetCachedState(RHIResource* resource) {
        auto it = m_cache.find(resource);
        if (it != m_cache.end() && it->second.frameIndex == m_currentFrame) {
            return it->second.state;
        }
        return ResourceState::Unknown;
    }
    
    void UpdateCache(RHIResource* resource, ResourceState state) {
        m_cache[resource] = {resource, state, m_currentFrame};
    }
    
    void NewFrame() {
        m_currentFrame++;
        // 可选：清理旧缓存
    }
};
```

## D3D12 资源屏障

```cpp
// D3D12 三种 Barrier 类型
enum class BarrierType {
    Transition,    // 状态转换
    Aliasing,      // 资源别名
    UAV,           // UAV 屏障
};

// 批量 Barrier 提交
void FlushBarriers(RHICommandList* cmdList) {
    if (m_pendingBarriers.empty()) return;
    
    std::vector<D3D12_RESOURCE_BARRIER> d3d12Barriers;
    
    for (const auto& barrier : m_pendingBarriers) {
        if (barrier.type == BarrierType::Transition) {
            d3d12Barriers.push_back(CD3DX12_RESOURCE_BARRIER::Transition(
                barrier.resource->GetNative(),
                ConvertToD3D12State(barrier.from),
                ConvertToD3D12State(barrier.to)
            ));
        }
    }
    
    cmdList->GetD3D12CommandList()->ResourceBarrier(
        d3d12Barriers.size(), 
        d3d12Barriers.data()
    );
    
    m_pendingBarriers.clear();
}
```

## Vulkan Image Layout 转换

```cpp
// Vulkan 使用 Pipeline Barrier
void TransitionImageLayout(
    VkCommandBuffer cmdBuffer,
    VkImage image,
    VkImageLayout oldLayout,
    VkImageLayout newLayout,
    VkPipelineStageFlags srcStage,
    VkPipelineStageFlags dstStage
) {
    VkImageMemoryBarrier barrier = {};
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    barrier.oldLayout = oldLayout;
    barrier.newLayout = newLayout;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = image;
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseMipLevel = 0;
    barrier.subresourceRange.levelCount = 1;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;
    
    // 根据 Layout 设置 Access Mask
    switch (oldLayout) {
        case VK_IMAGE_LAYOUT_UNDEFINED:
            barrier.srcAccessMask = 0;
            break;
        case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:
            barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
            break;
        // ...
    }
    
    switch (newLayout) {
        case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:
            barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
            break;
        case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:
            barrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
            break;
        // ...
    }
    
    vkCmdPipelineBarrier(
        cmdBuffer,
        srcStage, dstStage,
        0, 0, nullptr, 0, nullptr, 1, &barrier
    );
}
```

## 最佳实践

### ✅ 推荐

1. **批量提交 Barrier** - 减少 API 调用
2. **缓存状态** - 避免重复计算
3. **自动追踪** - 减少 human error
4. **帧边界重置** - 确保状态一致

### ❌ 避免

1. **每操作后立即 Barrier** - 性能差
2. **忽略子资源** - 部分 mip/layer 可能状态不同
3. **跨帧缓存状态** - 状态可能已变化

## 相关文件

- [../design/command-model.md](../design/command-model.md) - 命令模型
- [render-graph.md](./render-graph.md) - 渲染图自动 Barrier
