# 描述符管理

## 概述

描述符管理是 RHI 层最复杂的部分之一，需要在 D3D12 的 Descriptor Heap 和 Vulkan 的 Descriptor Set 之间建立统一抽象。

## D3D12 vs Vulkan 描述符模型

### D3D12 模型

```
┌────────────────────────────────────────────────────────────┐
│                    Descriptor Heap                          │
│  (Shader Visible / Non-Shader Visible)                     │
├────────────────────────────────────────────────────────────┤
│  [0] CBV ──► Buffer A    [64 bytes each]                   │
│  [1] SRV ──► Texture B                                      │
│  [2] UAV ──► Buffer C                                       │
│  ...                                                        │
└────────────────────────────────────────────────────────────┘
        │
        ▼
  GPU 直接访问（通过 GPU Descriptor Handle）
```

### Vulkan 模型

```
┌────────────────────────────────────────────────────────────┐
│                    Descriptor Pool                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Descriptor Set 0:                                         │
│    [Binding 0] Uniform Buffer                              │
│    [Binding 1] Combined Image Sampler                      │
│                                                            │
│  Descriptor Set 1:                                         │
│    [Binding 0] Storage Buffer                              │
│                                                            │
└────────────────────────────────────────────────────────────┘
        │
        ▼
  通过 vkCmdBindDescriptorSets 绑定
```

## 统一抽象设计

### 描述符池

```cpp
// 描述符池
class RHIDescriptorPool {
public:
    // 分配描述符集
    virtual RHIDescriptorSet* Allocate(RHIDescriptorSetLayout* layout) = 0;
    
    // 释放描述符集
    virtual void Free(RHIDescriptorSet* set) = 0;
    
    // 重置（释放所有）
    virtual void Reset() = 0;
};

// 描述符集布局
class RHIDescriptorSetLayout {
public:
    struct Binding {
        uint32_t binding;
        DescriptorType type;
        uint32_t count;
        ShaderStage stages;
    };
    
    virtual const std::vector<Binding>& GetBindings() const = 0;
};

// 描述符集
class RHIDescriptorSet {
public:
    // 更新描述符
    virtual void Update(uint32_t binding, const DescriptorInfo& info) = 0;
    
    // 获取 GPU 地址（D3D12）
    virtual uint64_t GetGPUAddress() const = 0;
};
```

### 描述符类型

```cpp
enum class DescriptorType {
    Sampler,
    CombinedImageSampler,
    SampledImage,
    StorageImage,
    UniformTexelBuffer,
    StorageTexelBuffer,
    UniformBuffer,
    StorageBuffer,
    UniformBufferDynamic,
    StorageBufferDynamic,
};

// 描述符信息
struct DescriptorInfo {
    DescriptorType type;
    
    union {
        RHIBuffer* buffer;
        RHITexture* texture;
        RHISampler* sampler;
    };
    
    uint64_t offset;    // Buffer offset
    uint64_t range;     // Buffer range
    
    TextureSubresourceRange subresource;  // Texture subresource
};
```

## D3D12 实现

```cpp
class D3D12DescriptorPool : public RHIDescriptorPool {
    ID3D12Device* m_device;
    ID3D12DescriptorHeap* m_heap;
    uint64_t m_heapSize;
    uint32_t m_descriptorSize;
    uint32_t m_freeIndex;
    
public:
    D3D12DescriptorPool(ID3D12Device* device, uint32_t maxDescriptors) {
        m_device = device;
        m_descriptorSize = device->GetDescriptorHandleIncrementSize(
            D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
        
        D3D12_DESCRIPTOR_HEAP_DESC heapDesc = {};
        heapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
        heapDesc.NumDescriptors = maxDescriptors;
        heapDesc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;
        
        device->CreateDescriptorHeap(&heapDesc, IID_PPV_ARGS(&m_heap));
        m_heapSize = maxDescriptors;
        m_freeIndex = 0;
    }
    
    RHIDescriptorSet* Allocate(RHIDescriptorSetLayout* layout) override {
        auto set = new D3D12DescriptorSet();
        set->heap = m_heap;
        set->baseIndex = m_freeIndex;
        
        // 计算需要的描述符数量
        uint32_t descriptorCount = layout->GetTotalDescriptorCount();
        m_freeIndex += descriptorCount;
        
        return set;
    }
};

// 更新描述符
void D3D12DescriptorSet::Update(uint32_t binding, const DescriptorInfo& info) {
    CD3DX12_CPU_DESCRIPTOR_HANDLE handle(
        m_heap->GetCPUDescriptorHandleForHeapStart(),
        m_baseIndex + binding,
        m_descriptorSize
    );
    
    switch (info.type) {
        case DescriptorType::UniformBuffer: {
            D3D12_CONSTANT_BUFFER_VIEW_DESC cbvDesc = {};
            cbvDesc.BufferLocation = info.buffer->GetGPUAddress() + info.offset;
            cbvDesc.SizeInBytes = info.range;
            m_device->CreateConstantBufferView(&cbvDesc, handle);
            break;
        }
        case DescriptorType::SampledImage: {
            D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = {};
            srvDesc.Format = info.texture->GetDXGIFormat();
            srvDesc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
            srvDesc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
            m_device->CreateShaderResourceView(info.texture->GetNative(), &srvDesc, handle);
            break;
        }
        // ...
    }
}
```

## Vulkan 实现

```cpp
class VulkanDescriptorPool : public RHIDescriptorPool {
    VkDevice m_device;
    VkDescriptorPool m_pool;
    
public:
    VulkanDescriptorPool(VkDevice device, const VkDescriptorPoolSize* sizes, uint32_t sizeCount) {
        m_device = device;
        
        VkDescriptorPoolCreateInfo poolInfo = {};
        poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
        poolInfo.maxSets = 1000;
        poolInfo.poolSizeCount = sizeCount;
        poolInfo.pPoolSizes = sizes;
        
        vkCreateDescriptorPool(device, &poolInfo, nullptr, &m_pool);
    }
    
    RHIDescriptorSet* Allocate(RHIDescriptorSetLayout* layout) override {
        VkDescriptorSetAllocateInfo allocInfo = {};
        allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
        allocInfo.descriptorPool = m_pool;
        allocInfo.descriptorSetCount = 1;
        allocInfo.pSetLayouts = &layout->GetVkLayout();
        
        VkDescriptorSet set;
        vkAllocateDescriptorSets(m_device, &allocInfo, &set);
        
        return new VulkanDescriptorSet(set);
    }
};

// 更新描述符
void VulkanDescriptorSet::Update(uint32_t binding, const DescriptorInfo& info) {
    VkWriteDescriptorSet write = {};
    write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    write.dstSet = m_set;
    write.dstBinding = binding;
    write.descriptorCount = 1;
    
    switch (info.type) {
        case DescriptorType::UniformBuffer: {
            VkDescriptorBufferInfo bufferInfo = {};
            bufferInfo.buffer = info.buffer->GetVkBuffer();
            bufferInfo.offset = info.offset;
            bufferInfo.range = info.range;
            
            write.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
            write.pBufferInfo = &bufferInfo;
            break;
        }
        case DescriptorType::SampledImage: {
            VkDescriptorImageInfo imageInfo = {};
            imageInfo.imageView = info.texture->GetVkImageView();
            imageInfo.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
            
            write.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
            write.pImageInfo = &imageInfo;
            break;
        }
    }
    
    vkUpdateDescriptorSets(m_device, 1, &write, 0, nullptr);
}
```

## 绑定策略

### D3D12 Root Signature 绑定

```cpp
// 绑定描述符表
void BindDescriptorTable(RHICommandList* cmdList, uint32_t rootIndex, RHIDescriptorSet* set) {
    auto d3d12Set = static_cast<D3D12DescriptorSet*>(set);
    
    CD3DX12_GPU_DESCRIPTOR_HANDLE handle(
        d3d12Set->GetHeap()->GetGPUDescriptorHandleForHeapStart(),
        d3d12Set->GetBaseIndex(),
        d3d12Set->GetDescriptorSize()
    );
    
    cmdList->SetGraphicsRootDescriptorTable(rootIndex, handle);
}
```

### Vulkan Descriptor Set 绑定

```cpp
// 绑定描述符集
void BindDescriptorSet(RHICommandList* cmdList, uint32_t setIndex, RHIDescriptorSet* set) {
    auto vkSet = static_cast<VulkanDescriptorSet*>(set);
    
    vkCmdBindDescriptorSets(
        cmdList->GetVkCommandBuffer(),
        VK_PIPELINE_BIND_POINT_GRAPHICS,
        pipelineLayout,
        setIndex, 1,
        &vkSet->GetVkSet(),
        0, nullptr
    );
}
```

## 最佳实践

### ✅ 推荐

1. **分帧分配** - 每帧独立的描述符池
2. **预分配布局** - 编译期确定描述符布局
3. **批量更新** - 一次性更新多个描述符
4. **池化管理** - 避免频繁分配/释放

### ❌ 避免

1. **频繁更新** - 每帧重新创建描述符
2. **过度碎片化** - 描述符堆碎片
3. **忽略对齐** - D3D12 描述符对齐

## 相关文件

- [resource-pool.md](./resource-pool.md) - 资源池模式
- [../design/abstraction-layers.md](../design/abstraction-layers.md) - 抽象层设计
