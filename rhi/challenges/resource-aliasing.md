# 资源别名

## 概述

资源别名（Resource Aliasing）允许不同的资源在同一块内存上创建，前提是它们的生命周期不重叠。

## 为什么需要资源别名？

```
场景：渲染管线的中间资源

Pass 1: ShadowMap (2048x2048 D32F)   占用 16MB
Pass 2: GBuffer0 (1920x1080 RGBA16F) 占用 8MB
Pass 3: GBuffer1 (1920x1080 RGBA16F) 占用 8MB
Pass 4: FinalRT  (1920x1080 RGBA8)   占用 8MB

无别名：16 + 8 + 8 + 8 = 40MB
有别名：max(16, 8, 8, 8) = 16MB

节省：60% 内存
```

## 实现方式

### D3D12 Placed Resource

```cpp
// 创建堆
D3D12_HEAP_DESC heapDesc = {};
heapDesc.SizeInBytes = heapSize;
heapDesc.Properties.Type = D3D12_HEAP_TYPE_DEFAULT;
heapDesc.Flags = D3D12_HEAP_FLAG_ALLOW_ALL_BUFFERS_AND_TEXTURES;

ID3D12Heap* heap;
device->CreateHeap(&heapDesc, IID_PPV_ARGS(&heap));

// 在同一堆上放置不同资源
device->CreatePlacedResource(heap, 0, &descA, ..., &resourceA);
device->CreatePlacedResource(heap, 0, &descB, ..., &resourceB);

// 使用 Aliasing Barrier 切换
D3D12_RESOURCE_ALIASING_BARRIER barrier = {};
barrier.pResourceBefore = resourceA;
barrier.pResourceAfter = resourceB;
commandList->ResourceBarrier(1, &CD3DX12_RESOURCE_BARRIER::Aliasing(&barrier));
```

### Vulkan Memory Aliasing

```cpp
// 同一块 DeviceMemory 上绑定不同资源
vkBindImageMemory(device, imageA, memory, 0);
// ... 使用 imageA ...

// 切换前需要 Pipeline Barrier
vkBindImageMemory(device, imageB, memory, 0);
// ... 使用 imageB ...
```

## 别名屏障

当资源别名切换时，需要插入别名屏障：

```cpp
// D3D12
void AliasResource(ID3D12GraphicsCommandList* cmdList,
                   ID3D12Resource* before, ID3D12Resource* after) {
    CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Aliasing(
        before, after);
    cmdList->ResourceBarrier(1, &barrier);
}

// Vulkan
void AliasImage(VkCommandBuffer cmdBuffer, VkImage before, VkImage after) {
    VkImageMemoryBarrier barrier = {};
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = 0;
    barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    barrier.newLayout = VK_IMAGE_LAYOUT_GENERAL;
    barrier.image = after;
    // ...
    
    vkCmdPipelineBarrier(cmdBuffer, 
        VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
        VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
        0, 0, nullptr, 0, nullptr, 1, &barrier);
}
```

## 帧图中的资源别名

```cpp
// 自动分析资源别名
class FrameGraph {
    void AnalyzeAliasing() {
        for (auto& resA : m_resources) {
            for (auto& resB : m_resources) {
                if (resA.id == resB.id) continue;
                
                // 生命周期不重叠？
                if (resA.lastUsePass < resB.firstUsePass ||
                    resB.lastUsePass < resA.firstUsePass) {
                    // 可以别名
                    resB.aliasOf = resA.id;
                }
            }
        }
    }
};
```

## 注意事项

### ✅ 可以别名

- 渲染目标
- 深度缓冲
- 中间纹理
- 临时 Buffer

### ❌ 不应别名

- 交换链图像
- 长期存在的纹理
- 同时使用的资源

## 相关文件

- [memory-fragmentation.md](./memory-fragmentation.md) - 内存碎片
- [../patterns/frame-graph.md](../patterns/frame-graph.md) - 帧图模式
