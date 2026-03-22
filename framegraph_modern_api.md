# FrameGraph 设计与 DX12/Vulkan 适配指南

## 目录

1. [FrameGraph 核心设计](#1-framegraph-核心设计)
2. [资源生命周期管理](#2-资源生命周期管理)
3. [DX12/Vulkan 资源屏障自动推导](#3-dx12vulkan-资源屏障自动推导)
4. [完整 FrameGraph 实现](#4-完整-framegraph-实现)
5. [与现有 RHI 集成](#5-与现有-rhi-集成)

---

## 1. FrameGraph 核心设计

### 1.1 设计理念

FrameGraph 是一个**声明式渲染架构**，解决现代图形 API 的复杂性：

```
传统渲染循环：
  - 手动管理资源生命周期
  - 手动插入资源屏障
  - 难以优化（资源复用、并行）
  - 难以调试

FrameGraph：
  - 声明渲染 Pass 和资源依赖
  - 自动推导资源屏障
  - 自动管理资源生命周期
  - 自动别名（内存复用）
```

### 1.2 核心概念

```cpp
// ============================================
// FrameGraph 核心概念
// ============================================

/**
 * FrameGraph 的三个核心抽象：
 *
 * 1. Resource（资源）- 虚拟资源，延迟创建
 * 2. Pass（通道）- 渲染操作，声明读写资源
 * 3. Builder（构建器）- Pass 注册资源的接口
 *
 * 执行流程：
 * 1. Compile（编译）- 分析依赖，分配物理资源，推导屏障
 * 2. Execute（执行）- 按拓扑序执行 Pass，插入屏障
 */

// 资源描述
struct TextureDesc {
    std::string name;
    uint32_t width = 0;
    uint32_t height = 0;
    Format format = Format::Unknown;
    TextureUsage usage = TextureUsage::None;

    // 0 表示使用交换链尺寸
    uint32_t widthScale = 1;   // 相对于屏幕的宽度比例
    uint32_t heightScale = 1;  // 相对于屏幕的高度比例
};

// 缓冲区描述
struct BufferDesc {
    std::string name;
    uint64_t size = 0;
    BufferUsage usage = BufferUsage::None;
};

// Pass 执行回调
using PassExecuteFunc = std::function<void(const FrameGraph&, PassExecutionContext&)>;

// Pass 描述
struct PassDesc {
    std::string name;
    PassExecuteFunc execute;

    // 资源读写声明
    std::vector<ResourceHandle> reads;
    std::vector<ResourceHandle> writes;
    std::vector<ResourceHandle> creates;  // 创建的资源
};
```

### 1.3 FrameGraph 架构

```
┌─────────────────────────────────────────────────────────────┐
│                     FrameGraph                               │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Setup     │→ │   Compile   │→ │   Execute   │        │
│  │   Phase     │  │   Phase     │  │   Phase     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│        ↓                ↓                ↓                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Pass 注册   │  │ 依赖分析    │  │ 执行 Pass   │        │
│  │ 资源声明    │  │ 资源分配    │  │ 插入屏障    │        │
│  │             │  │ 屏障推导    │  │ 资源别名    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 资源生命周期管理

### 2.1 虚拟资源与物理资源

```cpp
// ============================================
// 资源抽象层
// ============================================

class FrameGraph;

// 资源句柄（虚拟资源）
struct ResourceHandle {
    uint32_t index : 20;     // 资源索引
    uint32_t version : 12;   // 版本号（写操作递增）

    bool isValid() const { return index != 0xFFFFF; }
    static ResourceHandle invalid() { return {0xFFFFF, 0xFFF}; }
};

// 资源类型
enum class ResourceType : uint8_t {
    Texture,
    Buffer,
};

// 虚拟资源描述
struct VirtualResource {
    std::string name;
    ResourceType type;
    TextureDesc textureDesc;
    BufferDesc bufferDesc;

    // 生命周期
    uint32_t firstUsePass = UINT32_MAX;  // 首次使用的 Pass
    uint32_t lastUsePass = 0;             // 最后使用的 Pass

    // 引用计数
    uint32_t refCount = 0;

    // 物理资源索引（编译后填充）
    uint32_t physicalIndex = UINT32_MAX;

    // 是否需要别名（内存复用）
    bool needsAliasing = false;
};

// 物理资源（实际 GPU 资源）
struct PhysicalResource {
    RHI::ITexture* texture = nullptr;
    RHI::IBuffer* buffer = nullptr;

    // 资源状态
    RHI::ResourceState currentState = RHI::ResourceState::Undefined;

    // 生命周期
    uint32_t firstUseFrame = 0;
    uint32_t lastUseFrame = 0;

    // 别名组（共享内存的资源）
    uint32_t aliasGroup = 0;
};

// 资源池
class ResourcePool {
private:
    std::vector<PhysicalResource> resources;
    std::vector<std::vector<uint32_t>> aliasGroups;  // 别名组

public:
    // 分配物理资源
    uint32_t allocateTexture(const TextureDesc& desc, uint32_t frameIndex) {
        // 尝试复用已有资源
        for (size_t i = 0; i < resources.size(); ++i) {
            if (canAlias(resources[i], desc, frameIndex)) {
                resources[i].lastUseFrame = frameIndex;
                return i;
            }
        }

        // 创建新资源
        PhysicalResource res;
        res.texture = createTexture(desc);
        res.firstUseFrame = frameIndex;
        res.lastUseFrame = frameIndex;
        resources.push_back(res);
        return resources.size() - 1;
    }

    // 帧结束清理
    void endFrame(uint32_t frameIndex) {
        // 释放不再使用的资源
        for (auto it = resources.begin(); it != resources.end();) {
            if (it->lastUseFrame < frameIndex - 2) {  // 保留 2 帧
                destroyResource(*it);
                it = resources.erase(it);
            } else {
                ++it;
            }
        }
    }

private:
    bool canAlias(const PhysicalResource& res, const TextureDesc& desc, uint32_t frame) {
        if (!res.texture) return false;
        if (res.lastUseFrame >= frame - 1) return false;  // 仍在使用

        // 检查尺寸和格式是否兼容
        const auto& info = res.texture->GetDesc();
        return info.width == desc.width &&
               info.height == desc.height &&
               info.format == desc.format;
    }
};
```

### 2.2 资源别名（内存复用）

```cpp
// ============================================
// 资源别名分析
// ============================================

class ResourceAliaser {
public:
    // 分析资源生命周期，建立别名关系
    void analyzeAliasing(std::vector<VirtualResource>& resources,
                         const std::vector<PassDesc>& passes) {

        // 1. 计算每个资源的生命周期
        for (size_t i = 0; i < resources.size(); ++i) {
            auto& res = resources[i];
            for (size_t passIdx = 0; passIdx < passes.size(); ++passIdx) {
                const auto& pass = passes[passIdx];

                // 检查是否使用此资源
                if (usesResource(pass, i)) {
                    res.firstUsePass = std::min(res.firstUsePass, (uint32_t)passIdx);
                    res.lastUsePass = std::max(res.lastUsePass, (uint32_t)passIdx);
                }
            }
        }

        // 2. 检查生命周期不重叠的资源，可以别名
        for (size_t i = 0; i < resources.size(); ++i) {
            for (size_t j = i + 1; j < resources.size(); ++j) {
                if (!lifetimesOverlap(resources[i], resources[j])) {
                    // 可以共享物理资源
                    resources[i].needsAliasing = true;
                    resources[j].needsAliasing = true;

                    // 建立别名关系
                    aliasGroups.push_back({(uint32_t)i, (uint32_t)j});
                }
            }
        }
    }

private:
    std::vector<std::vector<uint32_t>> aliasGroups;

    bool usesResource(const PassDesc& pass, uint32_t resIdx) {
        for (auto h : pass.reads) {
            if (h.index == resIdx) return true;
        }
        for (auto h : pass.writes) {
            if (h.index == resIdx) return true;
        }
        return false;
    }

    bool lifetimesOverlap(const VirtualResource& a, const VirtualResource& b) {
        return !(a.lastUsePass < b.firstUsePass || b.lastUsePass < a.firstUsePass);
    }
};
```

---

## 3. DX12/Vulkan 资源屏障自动推导

### 3.1 资源状态追踪

```cpp
// ============================================
// 资源状态追踪器
// ============================================

class ResourceStateTracker {
private:
    // 资源 → 当前状态
    std::unordered_map<ResourceHandle, RHI::ResourceState> resourceStates;

    // 资源 → 写入 Pass（用于依赖分析）
    std::unordered_map<ResourceHandle, uint32_t> lastWritePass;

public:
    // 记录 Pass 的资源访问
    void recordPassAccess(const PassDesc& pass, uint32_t passIndex) {
        // 记录读操作
        for (auto handle : pass.reads) {
            // 读操作需要等待上一个写操作完成
            // 依赖关系在编译阶段处理
        }

        // 记录写操作
        for (auto handle : pass.writes) {
            lastWritePass[handle] = passIndex;
        }
    }

    // 推导两个 Pass 之间需要的屏障
    std::vector<ResourceBarrier> deriveBarriers(
        const PassDesc& fromPass,
        const PassDesc& toPass,
        const std::vector<VirtualResource>& resources) {

        std::vector<ResourceBarrier> barriers;

        // 检查 toPass 读取的资源
        for (auto handle : toPass.reads) {
            auto lastWrite = lastWritePass.find(handle);
            if (lastWrite != lastWritePass.end() &&
                lastWrite->second < toPass.index) {

                // 需要 UAV 屏障或状态转换
                barriers.push_back({
                    handle,
                    RHI::ResourceState::UnorderedAccess,
                    RHI::ResourceState::ShaderResource
                });
            }
        }

        // 检查 toPass 写入的资源
        for (auto handle : toPass.writes) {
            auto lastWrite = lastWritePass.find(handle);
            if (lastWrite != lastWritePass.end() &&
                lastWrite->second < toPass.index) {

                // 需要状态转换
                barriers.push_back({
                    handle,
                    RHI::ResourceState::RenderTarget,
                    RHI::ResourceState::UnorderedAccess
                });
            }
        }

        return barriers;
    }
};
```

### 3.2 DX12 屏障批量处理

```cpp
// ============================================
// DX12 增强屏障（Enhanced Barriers）
// ============================================

class D3D12BarrierBatcher {
private:
    std::vector<D3D12_TEXTURE_BARRIER> textureBarriers;
    std::vector<D3D12_BUFFER_BARRIER> bufferBarriers;
    std::vector<D3D12_GLOBAL_BARRIER> globalBarriers;

    ID3D12GraphicsCommandList* commandList = nullptr;

public:
    void setCommandList(ID3D12GraphicsCommandList* cmdList) {
        commandList = cmdList;
    }

    // 添加纹理屏障
    void addTextureBarrier(
        ID3D12Resource* resource,
        D3D12_BARRIER_SYNC syncBefore,
        D3D12_BARRIER_SYNC syncAfter,
        D3D12_BARRIER_ACCESS accessBefore,
        D3D12_BARRIER_ACCESS accessAfter,
        D3D12_BARRIER_LAYOUT layoutBefore,
        D3D12_BARRIER_LAYOUT layoutAfter) {

        D3D12_TEXTURE_BARRIER barrier = {};
        barrier.SyncBefore = syncBefore;
        barrier.SyncAfter = syncAfter;
        barrier.AccessBefore = accessBefore;
        barrier.AccessAfter = accessAfter;
        barrier.LayoutBefore = layoutBefore;
        barrier.LayoutAfter = layoutAfter;
        barrier.pResource = resource;
        barrier.Subresources = D3D12_TEXTURE_BARRIER_ALL_SUBRESOURCES;

        textureBarriers.push_back(barrier);
    }

    // 提交所有屏障
    void flush() {
        if (textureBarriers.empty() && bufferBarriers.empty() && globalBarriers.empty()) {
            return;
        }

        D3D12_BARRIER_GROUP groups[3] = {};
        uint32_t numGroups = 0;

        if (!textureBarriers.empty()) {
            groups[numGroups].Type = D3D12_BARRIER_TYPE_TEXTURE;
            groups[numGroups].NumBarriers = textureBarriers.size();
            groups[numGroups].pTextureBarriers = textureBarriers.data();
            numGroups++;
        }

        if (!bufferBarriers.empty()) {
            groups[numGroups].Type = D3D12_BARRIER_TYPE_BUFFER;
            groups[numGroups].NumBarriers = bufferBarriers.size();
            groups[numGroups].pBufferBarriers = bufferBarriers.data();
            numGroups++;
        }

        if (!globalBarriers.empty()) {
            groups[numGroups].Type = D3D12_BARRIER_TYPE_GLOBAL;
            groups[numGroups].NumBarriers = globalBarriers.size();
            groups[numGroups].pGlobalBarriers = globalBarriers.data();
            numGroups++;
        }

        commandList->Barrier(numGroups, groups);

        textureBarriers.clear();
        bufferBarriers.clear();
        globalBarriers.clear();
    }
};

// 使用示例：自动推导并插入屏障
void executePassWithBarriers(
    const PassDesc& pass,
    const std::vector<ResourceBarrier>& barriers,
    ID3D12GraphicsCommandList* cmdList) {

    D3D12BarrierBatcher batcher;
    batcher.setCommandList(cmdList);

    // 插入前置屏障
    for (const auto& barrier : barriers) {
        if (barrier.resourceType == ResourceType::Texture) {
            batcher.addTextureBarrier(
                getD3D12Texture(barrier.handle),
                D3D12_BARRIER_SYNC_ALL,              // syncBefore
                D3D12_BARRIER_SYNC_DRAW,             // syncAfter (假设是绘制)
                D3D12_BARRIER_ACCESS_COMMON,         // accessBefore
                D3D12_BARRIER_ACCESS_RENDER_TARGET,  // accessAfter
                D3D12_BARRIER_LAYOUT_COMMON,         // layoutBefore
                D3D12_BARRIER_LAYOUT_RENDER_TARGET   // layoutAfter
            );
        }
    }

    batcher.flush();

    // 执行 Pass
    pass.execute();

    // 插入后置屏障（如果需要）
    // ...
}
```

### 3.3 Vulkan 屏障处理

```cpp
// ============================================
// Vulkan 屏障处理
// ============================================

class VulkanBarrierBatcher {
private:
    std::vector<VkImageMemoryBarrier2> imageBarriers;
    std::vector<VkBufferMemoryBarrier2> bufferBarriers;
    std::vector<VkMemoryBarrier2> memoryBarriers;

    VkCommandBuffer commandBuffer = VK_NULL_HANDLE;

public:
    void setCommandBuffer(VkCommandBuffer cmdBuffer) {
        commandBuffer = cmdBuffer;
    }

    // 添加图像屏障
    void addImageBarrier(
        VkImage image,
        VkPipelineStageFlags2 stageBefore,
        VkPipelineStageFlags2 stageAfter,
        VkAccessFlags2 accessBefore,
        VkAccessFlags2 accessAfter,
        VkImageLayout layoutBefore,
        VkImageLayout layoutAfter,
        VkImageAspectFlags aspectMask = VK_IMAGE_ASPECT_COLOR_BIT) {

        VkImageMemoryBarrier2 barrier = {};
        barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2;
        barrier.srcStageMask = stageBefore;
        barrier.dstStageMask = stageAfter;
        barrier.srcAccessMask = accessBefore;
        barrier.dstAccessMask = accessAfter;
        barrier.oldLayout = layoutBefore;
        barrier.newLayout = layoutAfter;
        barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
        barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
        barrier.image = image;
        barrier.subresourceRange.aspectMask = aspectMask;
        barrier.subresourceRange.baseMipLevel = 0;
        barrier.subresourceRange.levelCount = VK_REMAINING_MIP_LEVELS;
        barrier.subresourceRange.baseArrayLayer = 0;
        barrier.subresourceRange.layerCount = VK_REMAINING_ARRAY_LAYERS;

        imageBarriers.push_back(barrier);
    }

    // 提交所有屏障
    void flush(VkDependencyFlags flags = 0) {
        if (imageBarriers.empty() && bufferBarriers.empty() && memoryBarriers.empty()) {
            return;
        }

        VkDependencyInfo depInfo = {};
        depInfo.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO;
        depInfo.dependencyFlags = flags;
        depInfo.imageMemoryBarrierCount = imageBarriers.size();
        depInfo.pImageMemoryBarriers = imageBarriers.data();
        depInfo.bufferMemoryBarrierCount = bufferBarriers.size();
        depInfo.pBufferMemoryBarriers = bufferBarriers.data();
        depInfo.memoryBarrierCount = memoryBarriers.size();
        depInfo.pMemoryBarriers = memoryBarriers.data();

        vkCmdPipelineBarrier2(commandBuffer, &depInfo);

        imageBarriers.clear();
        bufferBarriers.clear();
        memoryBarriers.clear();
    }
};

// Vulkan 状态映射
namespace VulkanStateMapping {
    VkImageLayout toImageLayout(RHI::ResourceState state) {
        switch (state) {
            case RHI::ResourceState::Undefined:
                return VK_IMAGE_LAYOUT_UNDEFINED;
            case RHI::ResourceState::RenderTarget:
                return VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
            case RHI::ResourceState::DepthWrite:
                return VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
            case RHI::ResourceState::ShaderResource:
                return VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
            case RHI::ResourceState::UnorderedAccess:
                return VK_IMAGE_LAYOUT_GENERAL;
            case RHI::ResourceState::CopyDest:
                return VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
            case RHI::ResourceState::CopySource:
                return VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
            case RHI::ResourceState::Present:
                return VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
            default:
                return VK_IMAGE_LAYOUT_GENERAL;
        }
    }

    VkPipelineStageFlags2 toPipelineStage(RHI::ResourceState state) {
        switch (state) {
            case RHI::ResourceState::RenderTarget:
                return VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT;
            case RHI::ResourceState::DepthWrite:
            case RHI::ResourceState::DepthRead:
                return VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
                       VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT;
            case RHI::ResourceState::ShaderResource:
            case RHI::ResourceState::UnorderedAccess:
                return VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT |
                       VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
                       VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
            case RHI::ResourceState::CopyDest:
            case RHI::ResourceState::CopySource:
                return VK_PIPELINE_STAGE_2_TRANSFER_BIT;
            default:
                return VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
        }
    }
}
```

---

## 4. 完整 FrameGraph 实现

### 4.1 FrameGraph 类

```cpp
// ============================================
// FrameGraph 完整实现
// ============================================

#include <memory>
#include <vector>
#include <unordered_map>
#include <string>
#include <functional>

class FrameGraph {
public:
    // ==================== 构建阶段 ====================

    // 创建纹理资源
    ResourceHandle createTexture(const std::string& name, const TextureDesc& desc) {
        VirtualResource res;
        res.name = name;
        res.type = ResourceType::Texture;
        res.textureDesc = desc;

        resources.push_back(std::move(res));
        return {static_cast<uint32_t>(resources.size() - 1), 0};
    }

    // 创建缓冲区资源
    ResourceHandle createBuffer(const std::string& name, const BufferDesc& desc) {
        VirtualResource res;
        res.name = name;
        res.type = ResourceType::Buffer;
        res.bufferDesc = desc;

        resources.push_back(std::move(res));
        return {static_cast<uint32_t>(resources.size() - 1), 0};
    }

    // 添加 Pass
    template<typename Data>
    PassHandle addPass(
        const std::string& name,
        std::function<void(Data&, PassBuilder&)> setup,
        std::function<void(const Data&, PassExecutionContext&)> execute) {

        // 创建 Pass 数据
        Data data;
        PassBuilder builder(this, passes.size());

        // 调用 setup 函数，让用户声明资源依赖
        setup(data, builder);

        // 保存 Pass
        PassDesc pass;
        pass.name = name;
        pass.reads = builder.getReads();
        pass.writes = builder.getWrites();
        pass.creates = builder.getCreates();
        pass.userData = std::make_shared<Data>(std::move(data));
        pass.executeFunc = [execute, name](const FrameGraph& fg, PassExecutionContext& ctx) {
            const Data* d = static_cast<const Data*>(ctx.passData);
            execute(*d, ctx);
        };

        passes.push_back(std::move(pass));
        return {static_cast<uint32_t>(passes.size() - 1)};
    }

    // ==================== 编译阶段 ====================

    void compile() {
        // 1. 计算资源生命周期
        computeResourceLifetimes();

        // 2. 剔除未使用的 Pass
        cullUnusedPasses();

        // 3. 计算拓扑排序
        computeTopologicalOrder();

        // 4. 分配物理资源
        allocatePhysicalResources();

        // 5. 推导资源屏障
        deriveResourceBarriers();
    }

    // ==================== 执行阶段 ====================

    void execute(RHI::ICommandList* commandList) {
        PassExecutionContext ctx;
        ctx.commandList = commandList;
        ctx.frameGraph = this;

        for (uint32_t passIndex : executionOrder) {
            const auto& pass = passes[passIndex];
            ctx.passIndex = passIndex;
            ctx.passData = pass.userData.get();

            // 插入前置屏障
            insertPrePassBarriers(passIndex, commandList);

            // 执行 Pass
            pass.executeFunc(*this, ctx);

            // 插入后置屏障
            insertPostPassBarriers(passIndex, commandList);
        }
    }

    // ==================== 资源访问 ====================

    RHI::ITexture* getTexture(ResourceHandle handle) const {
        const auto& vRes = resources[handle.index];
        if (vRes.physicalIndex == UINT32_MAX) return nullptr;
        return physicalResources[vRes.physicalIndex].texture;
    }

    RHI::IBuffer* getBuffer(ResourceHandle handle) const {
        const auto& vRes = resources[handle.index];
        if (vRes.physicalIndex == UINT32_MAX) return nullptr;
        return physicalResources[vRes.physicalIndex].buffer;
    }

private:
    // ==================== 内部数据结构 ====================

    std::vector<VirtualResource> resources;
    std::vector<PassDesc> passes;
    std::vector<PhysicalResource> physicalResources;
    std::vector<uint32_t> executionOrder;

    // ==================== 编译辅助方法 ====================

    void computeResourceLifetimes() {
        for (size_t i = 0; i < resources.size(); ++i) {
            auto& res = resources[i];
            res.firstUsePass = UINT32_MAX;
            res.lastUsePass = 0;
            res.refCount = 0;
        }

        for (size_t passIdx = 0; passIdx < passes.size(); ++passIdx) {
            const auto& pass = passes[passIdx];

            for (auto handle : pass.reads) {
                auto& res = resources[handle.index];
                res.firstUsePass = std::min(res.firstUsePass, (uint32_t)passIdx);
                res.lastUsePass = std::max(res.lastUsePass, (uint32_t)passIdx);
                res.refCount++;
            }

            for (auto handle : pass.writes) {
                auto& res = resources[handle.index];
                res.firstUsePass = std::min(res.firstUsePass, (uint32_t)passIdx);
                res.lastUsePass = std::max(res.lastUsePass, (uint32_t)passIdx);
                res.refCount++;
            }
        }
    }

    void cullUnusedPasses() {
        // 标记未使用的 Pass
        std::vector<bool> passUsed(passes.size(), false);

        // 从输出资源反向追踪
        for (const auto& res : resources) {
            if (res.refCount > 0 && res.lastUsePass != UINT32_MAX) {
                // 标记所有使用此资源的 Pass
                for (size_t i = res.firstUsePass; i <= res.lastUsePass; ++i) {
                    passUsed[i] = true;
                }
            }
        }

        // 剔除未使用的 Pass
        for (size_t i = 0; i < passes.size(); ++i) {
            if (!passUsed[i]) {
                passes[i].culled = true;
            }
        }
    }

    void computeTopologicalOrder() {
        // Kahn's 算法
        std::vector<int> inDegree(passes.size(), 0);
        std::vector<std::vector<uint32_t>> edges(passes.size());

        // 建立依赖图
        std::unordered_map<uint32_t, uint32_t> resourceLastWriter;
        for (size_t i = 0; i < passes.size(); ++i) {
            const auto& pass = passes[i];

            for (auto handle : pass.reads) {
                auto it = resourceLastWriter.find(handle.index);
                if (it != resourceLastWriter.end()) {
                    edges[it->second].push_back(i);
                    inDegree[i]++;
                }
            }

            for (auto handle : pass.writes) {
                resourceLastWriter[handle.index] = i;
            }
        }

        // 拓扑排序
        std::vector<uint32_t> queue;
        for (size_t i = 0; i < inDegree.size(); ++i) {
            if (inDegree[i] == 0) {
                queue.push_back(i);
            }
        }

        while (!queue.empty()) {
            uint32_t passIdx = queue.back();
            queue.pop_back();
            executionOrder.push_back(passIdx);

            for (uint32_t next : edges[passIdx]) {
                if (--inDegree[next] == 0) {
                    queue.push_back(next);
                }
            }
        }
    }

    void allocatePhysicalResources() {
        ResourceAliaser aliaser;
        aliaser.analyzeAliasing(resources, passes);

        for (size_t i = 0; i < resources.size(); ++i) {
            auto& res = resources[i];
            if (res.refCount == 0) continue;

            // 分配物理资源
            if (res.type == ResourceType::Texture) {
                res.physicalIndex = allocatePhysicalTexture(res.textureDesc);
            } else {
                res.physicalIndex = allocatePhysicalBuffer(res.bufferDesc);
            }
        }
    }

    void deriveResourceBarriers() {
        // 为每个 Pass 推导需要的屏障
        passBarriers.resize(passes.size());

        std::unordered_map<uint32_t, RHI::ResourceState> resourceStates;

        for (uint32_t passIdx : executionOrder) {
            const auto& pass = passes[passIdx];
            auto& barriers = passBarriers[passIdx];

            // 读操作需要的屏障
            for (auto handle : pass.reads) {
                auto it = resourceStates.find(handle.index);
                if (it != resourceStates.end()) {
                    RHI::ResourceState requiredState = RHI::ResourceState::ShaderResource;
                    if (it->second != requiredState) {
                        barriers.prePass.push_back({handle, it->second, requiredState});
                    }
                }
            }

            // 写操作需要的屏障
            for (auto handle : pass.writes) {
                auto it = resourceStates.find(handle.index);
                RHI::ResourceState oldState = it != resourceStates.end()
                    ? it->second
                    : RHI::ResourceState::Undefined;
                RHI::ResourceState newState = RHI::ResourceState::RenderTarget;  // 假设

                barriers.prePass.push_back({handle, oldState, newState});
                resourceStates[handle.index] = newState;
            }
        }
    }

    void insertPrePassBarriers(uint32_t passIndex, RHI::ICommandList* cmdList) {
        const auto& barriers = passBarriers[passIndex];

        for (const auto& barrier : barriers.prePass) {
            const auto& vRes = resources[barrier.handle.index];
            if (vRes.physicalIndex == UINT32_MAX) continue;

            if (vRes.type == ResourceType::Texture) {
                auto texture = physicalResources[vRes.physicalIndex].texture;
                cmdList->ResourceBarrier(texture, barrier.newState);
            }
        }
    }

    void insertPostPassBarriers(uint32_t passIndex, RHI::ICommandList* cmdList) {
        // 类似 prePass
    }

    uint32_t allocatePhysicalTexture(const TextureDesc& desc);
    uint32_t allocatePhysicalBuffer(const BufferDesc& desc);

    std::vector<PassBarriers> passBarriers;
};

// ==================== PassBuilder ====================

class PassBuilder {
public:
    PassBuilder(FrameGraph* fg, uint32_t passIndex)
        : frameGraph(fg), passIndex(passIndex) {}

    // 声明读取资源
    ResourceHandle read(ResourceHandle handle) {
        reads.push_back(handle);
        return handle;
    }

    // 声明写入资源
    ResourceHandle write(ResourceHandle handle) {
        writes.push_back(handle);
        return handle;
    }

    // 声明创建资源
    ResourceHandle create(ResourceHandle handle) {
        creates.push_back(handle);
        return handle;
    }

    const std::vector<ResourceHandle>& getReads() const { return reads; }
    const std::vector<ResourceHandle>& getWrites() const { return writes; }
    const std::vector<ResourceHandle>& getCreates() const { return creates; }

private:
    FrameGraph* frameGraph;
    uint32_t passIndex;
    std::vector<ResourceHandle> reads;
    std::vector<ResourceHandle> writes;
    std::vector<ResourceHandle> creates;
};

// ==================== PassExecutionContext ====================

struct PassExecutionContext {
    RHI::ICommandList* commandList = nullptr;
    const FrameGraph* frameGraph = nullptr;
    uint32_t passIndex = 0;
    const void* passData = nullptr;

    // 获取资源
    RHI::ITexture* getTexture(ResourceHandle handle) const {
        return frameGraph->getTexture(handle);
    }

    RHI::IBuffer* getBuffer(ResourceHandle handle) const {
        return frameGraph->getBuffer(handle);
    }
};
```

### 4.2 使用示例：延迟渲染

```cpp
// ============================================
// 延迟渲染 FrameGraph 示例
// ============================================

struct GBufferPassData {
    ResourceHandle depthTexture;
    ResourceHandle albedoTexture;
    ResourceHandle normalTexture;
    ResourceHandle metallicRoughnessTexture;
};

struct LightingPassData {
    ResourceHandle depthTexture;
    ResourceHandle albedoTexture;
    ResourceHandle normalTexture;
    ResourceHandle metallicRoughnessTexture;
    ResourceHandle lightingOutput;
};

struct PostProcessPassData {
    ResourceHandle lightingOutput;
    ResourceHandle finalOutput;
};

void renderFrame(FrameGraph& fg, RHI::ICommandList* cmdList) {
    // ==================== 1. GBuffer Pass ====================

    auto gbufferPass = fg.addPass<GBufferPassData>(
        "GBuffer",
        [&](GBufferPassData& data, PassBuilder& builder) {
            // 创建资源
            data.depthTexture = fg.createTexture("GBufferDepth", {
                .width = 1920, .height = 1080,
                .format = Format::D32_Float,
                .usage = TextureUsage::DepthStencil
            });

            data.albedoTexture = fg.createTexture("GBufferAlbedo", {
                .width = 1920, .height = 1080,
                .format = Format::R8G8B8A8_UNorm,
                .usage = TextureUsage::RenderTarget
            });

            data.normalTexture = fg.createTexture("GBufferNormal", {
                .width = 1920, .height = 1080,
                .format = Format::R16G16B16A16_Float,
                .usage = TextureUsage::RenderTarget
            });

            data.metallicRoughnessTexture = fg.createTexture("GBufferMetallicRoughness", {
                .width = 1920, .height = 1080,
                .format = Format::R8G8_UNorm,
                .usage = TextureUsage::RenderTarget
            });

            // 声明写入
            builder.write(data.depthTexture);
            builder.write(data.albedoTexture);
            builder.write(data.normalTexture);
            builder.write(data.metallicRoughnessTexture);
        },
        [](const GBufferPassData& data, PassExecutionContext& ctx) {
            auto* cmdList = ctx.commandList;

            // 获取资源
            auto* depth = ctx.getTexture(data.depthTexture);
            auto* albedo = ctx.getTexture(data.albedoTexture);
            auto* normal = ctx.getTexture(data.normalTexture);
            auto* metallicRoughness = ctx.getTexture(data.metallicRoughnessTexture);

            // 清除
            float clearColor[4] = {0, 0, 0, 1};
            cmdList->ClearRenderTarget(albedo, clearColor);
            cmdList->ClearRenderTarget(normal, clearColor);
            cmdList->ClearDepthStencil(depth, true, false, 1.0f, 0);

            // 设置渲染目标
            RHI::ITexture* renderTargets[] = {albedo, normal, metallicRoughness};
            cmdList->SetRenderTargets(renderTargets, 3, depth);

            // 绘制场景几何体
            drawSceneGeometry(cmdList);
        }
    );

    // ==================== 2. Lighting Pass ====================

    auto lightingPass = fg.addPass<LightingPassData>(
        "Lighting",
        [&](LightingPassData& data, PassBuilder& builder) {
            // 读取 GBuffer
            data.depthTexture = builder.read(fg.getTextureByName("GBufferDepth"));
            data.albedoTexture = builder.read(fg.getTextureByName("GBufferAlbedo"));
            data.normalTexture = builder.read(fg.getTextureByName("GBufferNormal"));
            data.metallicRoughnessTexture = builder.read(fg.getTextureByName("GBufferMetallicRoughness"));

            // 创建输出
            data.lightingOutput = fg.createTexture("LightingOutput", {
                .width = 1920, .height = 1080,
                .format = Format::R16G16B16A16_Float,
                .usage = TextureUsage::RenderTarget | TextureUsage::ShaderResource
            });

            builder.write(data.lightingOutput);
        },
        [](const LightingPassData& data, PassExecutionContext& ctx) {
            auto* cmdList = ctx.commandList;

            auto* lightingOutput = ctx.getTexture(data.lightingOutput);

            // 清除
            float clearColor[4] = {0, 0, 0, 1};
            cmdList->ClearRenderTarget(lightingOutput, clearColor);
            cmdList->SetRenderTargets(&lightingOutput, 1);

            // 设置 GBuffer 纹理作为 shader resource
            setGBufferTextures(
                ctx.getTexture(data.albedoTexture),
                ctx.getTexture(data.normalTexture),
                ctx.getTexture(data.metallicRoughnessTexture),
                ctx.getTexture(data.depthTexture)
            );

            // 绘制全屏四边形进行光照计算
            drawFullScreenQuad(cmdList);
        }
    );

    // ==================== 3. Post-Process Pass ====================

    auto postProcessPass = fg.addPass<PostProcessPassData>(
        "PostProcess",
        [&](PostProcessPassData& data, PassBuilder& builder) {
            // 读取光照结果
            data.lightingOutput = builder.read(fg.getTextureByName("LightingOutput"));

            // 写入最终输出（通常是 backbuffer）
            data.finalOutput = builder.write(getBackBuffer());
        },
        [](const PostProcessPassData& data, PassExecutionContext& ctx) {
            auto* cmdList = ctx.commandList;

            auto* finalOutput = ctx.getTexture(data.finalOutput);
            cmdList->SetRenderTargets(&finalOutput, 1);

            // 后处理（色调映射、抗锯齿等）
            applyPostProcess(ctx.getTexture(data.lightingOutput), cmdList);
        }
    );

    // ==================== 4. 编译和执行 ====================

    fg.compile();
    fg.execute(cmdList);
}
```

---

## 5. 与现有 RHI 集成

### 5.1 扩展现有接口

```cpp
// ============================================
// 扩展 IFrameResourceManager
// ============================================

class IFrameResourceManager {
public:
    // ... 现有接口 ...

    // 新增：FrameGraph 支持
    virtual FrameGraph* createFrameGraph() = 0;
    virtual void destroyFrameGraph(FrameGraph* fg) = 0;

    // 新增：资源别名支持
    virtual bool supportsAliasing() const = 0;
    virtual uint64_t getResourceMemoryUsage() const = 0;

    // 新增：增强屏障支持（DX12）
    virtual bool supportsEnhancedBarriers() const = 0;
};

// ============================================
// D3D12 实现
// ============================================

class D3D12FrameResourceManager : public IFrameResourceManager {
public:
    FrameGraph* createFrameGraph() override {
        return new D3D12FrameGraph(m_device);
    }

    bool supportsAliasing() const override { return true; }
    bool supportsEnhancedBarriers() const override {
        // 检查 DX12 Agility SDK 版本
        return m_device->SupportsEnhancedBarriers();
    }
};

// ============================================
// Vulkan 实现
// ============================================

class VulkanFrameResourceManager : public IFrameResourceManager {
public:
    FrameGraph* createFrameGraph() override {
        return new VulkanFrameGraph(m_device);
    }

    bool supportsAliasing() const override { return true; }
    bool supportsEnhancedBarriers() const override { return false; }
};
```

### 5.2 ICommandList 扩展

```cpp
// ============================================
// 扩展 ICommandList
// ============================================

class ICommandList {
public:
    // ... 现有接口 ...

    // 新增：批量屏障
    virtual void ResourceBarriers(
        const ResourceBarrierDesc* barriers,
        uint32_t count) = 0;

    // 新增：增强屏障（DX12 专用）
    virtual void EnhancedBarriers(
        const void* barrierGroups,
        uint32_t groupCount) = 0;

    // 新增：UAV 屏障
    virtual void UAVBarrier(ITexture* texture) = 0;
    virtual void UAVBarrier(IBuffer* buffer) = 0;

    // 新增：全局内存屏障
    virtual void GlobalMemoryBarrier() = 0;
};

// 资源屏障描述
struct ResourceBarrierDesc {
    ResourceHandle resource;
    ResourceState oldState;
    ResourceState newState;
    bool isUAVBarrier = false;  // UAV 屏障标志
};

// ============================================
// D3D12 实现
// ============================================

class D3D12CommandList : public ICommandList {
public:
    void ResourceBarriers(
        const ResourceBarrierDesc* barriers,
        uint32_t count) override {

        std::vector<D3D12_RESOURCE_BARRIER> d3dBarriers(count);

        for (uint32_t i = 0; i < count; ++i) {
            const auto& desc = barriers[i];

            if (desc.isUAVBarrier) {
                // UAV 屏障
                d3dBarriers[i].Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
                d3dBarriers[i].UAV.pResource = getD3D12Resource(desc.resource);
            } else {
                // 状态转换屏障
                d3dBarriers[i].Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
                d3dBarriers[i].Transition.pResource = getD3D12Resource(desc.resource);
                d3dBarriers[i].Transition.StateBefore = toD3D12State(desc.oldState);
                d3dBarriers[i].Transition.StateAfter = toD3D12State(desc.newState);
                d3dBarriers[i].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
            }
        }

        m_commandList->ResourceBarrier(count, d3dBarriers.data());
    }

    void EnhancedBarriers(
        const void* barrierGroups,
        uint32_t groupCount) override {

        m_commandList->Barrier(groupCount,
            static_cast<const D3D12_BARRIER_GROUP*>(barrierGroups));
    }

private:
    ID3D12GraphicsCommandList* m_commandList;
};

// ============================================
// Vulkan 实现
// ============================================

class VulkanCommandList : public ICommandList {
public:
    void ResourceBarriers(
        const ResourceBarrierDesc* barriers,
        uint32_t count) override {

        std::vector<VkImageMemoryBarrier2> imageBarriers;
        std::vector<VkBufferMemoryBarrier2> bufferBarriers;

        for (uint32_t i = 0; i < count; ++i) {
            const auto& desc = barriers[i];

            if (isTexture(desc.resource)) {
                VkImageMemoryBarrier2 barrier = {};
                barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2;
                barrier.oldLayout = toVulkanLayout(desc.oldState);
                barrier.newLayout = toVulkanLayout(desc.newState);
                barrier.srcStageMask = toPipelineStage(desc.oldState);
                barrier.dstStageMask = toPipelineStage(desc.newState);
                barrier.image = getVulkanImage(desc.resource);
                // ... 其他字段 ...

                imageBarriers.push_back(barrier);
            } else {
                // Buffer 屏障
                // ...
            }
        }

        VkDependencyInfo depInfo = {};
        depInfo.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO;
        depInfo.imageMemoryBarrierCount = imageBarriers.size();
        depInfo.pImageMemoryBarriers = imageBarriers.data();

        vkCmdPipelineBarrier2(m_commandBuffer, &depInfo);
    }

private:
    VkCommandBuffer m_commandBuffer;
};
```

### 5.3 完整集成示例

```cpp
// ============================================
// 游戏引擎集成
// ============================================

class Renderer {
private:
    RHI::IDevice* device;
    RHI::IFrameResourceManager* frameResourceManager;
    FrameGraph* frameGraph;

public:
    void initialize() {
        // 创建 RHI 设备
        RHI::RHIConfig config;
        config.backend = RHI::Backend::D3D12;
        RHI::Initialize(config);

        device = RHI::GetMainDevice();
        frameResourceManager = RHI::GetFrameResourceManager();

        // 创建 FrameGraph
        frameGraph = frameResourceManager->createFrameGraph();
    }

    void renderFrame() {
        // 开始帧
        frameResourceManager->BeginFrame();

        // 获取命令列表
        auto* cmdList = device->CreateCommandList();

        // 构建 FrameGraph
        buildFrameGraph();

        // 编译
        frameGraph->compile();

        // 执行
        cmdList->Begin();
        frameGraph->execute(cmdList);
        cmdList->End();

        // 提交
        device->ExecuteCommandLists(&cmdList, 1);

        // 结束帧
        frameResourceManager->EndFrame();
    }

    void buildFrameGraph() {
        // 清空上一帧
        frameGraph->reset();

        // 添加渲染 Pass
        // ...
    }
};
```

---

## 总结

### FrameGraph 核心优势

| 特性 | 传统方式 | FrameGraph |
|------|---------|-----------|
| 资源管理 | 手动创建/销毁 | 自动生命周期 |
| 资源屏障 | 手动插入，容易遗漏 | 自动推导 |
| 内存复用 | 困难 | 自动别名分析 |
| 调试 | 难以追踪 | 可视化工具支持 |
| 性能优化 | 依赖经验 | 编译器优化 |

### DX12/Vulkan 适配要点

1. **资源状态追踪**：记录每个资源的状态变化
2. **批量屏障**：使用增强屏障 API 减少开销
3. **内存别名**：生命周期不重叠的资源共享内存
4. **多线程命令**：FrameGraph 支持并行 Pass 执行

### 参考实现

- **Frostbite (EA)**: Frame Graph 原始论文
- **Unreal Engine**: RDG (Render Dependency Graph)
- **Unity**: Scriptable Render Pipeline
- **The Forge**: 跨平台渲染框架
