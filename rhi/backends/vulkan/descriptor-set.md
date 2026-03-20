# Vulkan 描述符集

## Descriptor Set Layout

```cpp
VkDescriptorSetLayoutBinding bindings[] = {
    // Binding 0: Uniform Buffer
    {
        .binding = 0,
        .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = nullptr
    },
    // Binding 1: Combined Image Sampler
    {
        .binding = 1,
        .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 1,
        .stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT,
        .pImmutableSamplers = nullptr
    }
};

VkDescriptorSetLayoutCreateInfo layoutInfo = {};
layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
layoutInfo.bindingCount = 2;
layoutInfo.pBindings = bindings;

VkDescriptorSetLayout layout;
vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &layout);
```

## Descriptor Pool

```cpp
VkDescriptorPoolSize poolSizes[] = {
    { VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 100 },
    { VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 100 },
    { VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 50 }
};

VkDescriptorPoolCreateInfo poolInfo = {};
poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
poolInfo.poolSizeCount = 3;
poolInfo.pPoolSizes = poolSizes;
poolInfo.maxSets = 100;

VkDescriptorPool pool;
vkCreateDescriptorPool(device, &poolInfo, nullptr, &pool);
```

## 分配 Descriptor Set

```cpp
VkDescriptorSetAllocateInfo allocInfo = {};
allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
allocInfo.descriptorPool = pool;
allocInfo.descriptorSetCount = 1;
allocInfo.pSetLayouts = &layout;

VkDescriptorSet descriptorSet;
vkAllocateDescriptorSets(device, &allocInfo, &descriptorSet);
```

## 更新 Descriptor Set

```cpp
// Uniform Buffer
VkDescriptorBufferInfo bufferInfo = {};
bufferInfo.buffer = uniformBuffer;
bufferInfo.offset = 0;
bufferInfo.range = sizeof(UniformData);

// Image + Sampler
VkDescriptorImageInfo imageInfo = {};
imageInfo.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
imageInfo.imageView = textureImageView;
imageInfo.sampler = textureSampler;

VkWriteDescriptorSet descriptorWrites[2] = {};

descriptorWrites[0].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
descriptorWrites[0].dstSet = descriptorSet;
descriptorWrites[0].dstBinding = 0;
descriptorWrites[0].descriptorCount = 1;
descriptorWrites[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
descriptorWrites[0].pBufferInfo = &bufferInfo;

descriptorWrites[1].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
descriptorWrites[1].dstSet = descriptorSet;
descriptorWrites[1].dstBinding = 1;
descriptorWrites[1].descriptorCount = 1;
descriptorWrites[1].descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
descriptorWrites[1].pImageInfo = &imageInfo;

vkUpdateDescriptorSets(device, 2, descriptorWrites, 0, nullptr);
```

## 绑定 Descriptor Set

```cpp
vkCmdBindDescriptorSets(
    commandBuffer,
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    pipelineLayout,
    0,  // first set
    1,  // set count
    &descriptorSet,
    0, nullptr  // dynamic offsets
);
```

## 相关文件

- [pipeline-layout.md](./pipeline-layout.md) - 管线布局
- [pipeline.md](./pipeline.md) - 管线对象
