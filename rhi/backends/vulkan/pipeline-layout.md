# Vulkan 管线布局

## 概述

管线布局定义了着色器访问资源的方式，包括 Descriptor Set Layout 和 Push Constant Range。

## 创建 Pipeline Layout

```cpp
VkDescriptorSetLayout setLayouts[] = { 
    frameSetLayout, 
    materialSetLayout, 
    objectSetLayout 
};

VkPushConstantRange pushRange = {};
pushRange.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
pushRange.offset = 0;
pushRange.size = 64;  // 最大 128 bytes guaranteed

VkPipelineLayoutCreateInfo layoutInfo = {};
layoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
layoutInfo.setLayoutCount = 3;
layoutInfo.pSetLayouts = setLayouts;
layoutInfo.pushConstantRangeCount = 1;
layoutInfo.pPushConstantRanges = &pushRange;

VkPipelineLayout pipelineLayout;
vkCreatePipelineLayout(device, &layoutInfo, nullptr, &pipelineLayout);
```

## Push Constants

```cpp
// 更新 Push Constants
glm::mat4 modelMatrix;
vkCmdPushConstants(
    commandBuffer,
    pipelineLayout,
    VK_SHADER_STAGE_VERTEX_BIT,
    0,
    sizeof(modelMatrix),
    &modelMatrix
);

// 在着色器中使用
// GLSL:
// layout(push_constant) uniform PushConstants {
//     mat4 model;
// } pc;
```

## 多个 Descriptor Set

```cpp
// 绑定多个 Set
vkCmdBindDescriptorSets(
    commandBuffer,
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    pipelineLayout,
    0,  // firstSet
    3,  // descriptorSetCount
    descriptorSets,
    0, nullptr
);
```

## 相关文件

- [descriptor-set.md](./descriptor-set.md) - 描述符集
- [pipeline.md](./pipeline.md) - 管线对象
