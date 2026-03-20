# Vulkan 命令缓冲区

## 创建命令池

```cpp
VkCommandPoolCreateInfo poolInfo = {};
poolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
poolInfo.queueFamilyIndex = graphicsFamily;
poolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;

VkCommandPool commandPool;
vkCreateCommandPool(device, &poolInfo, nullptr, &commandPool);
```

## 分配命令缓冲区

```cpp
VkCommandBufferAllocateInfo allocInfo = {};
allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
allocInfo.commandPool = commandPool;
allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
allocInfo.commandBufferCount = 1;

VkCommandBuffer commandBuffer;
vkAllocateCommandBuffers(device, &allocInfo, &commandBuffer);
```

## 命令缓冲区级别

| 级别 | 用途 |
|------|------|
| PRIMARY | 主命令缓冲区，直接提交 |
| SECONDARY | 次级命令缓冲区，被主缓冲区调用 |

## 录制命令

```cpp
VkCommandBufferBeginInfo beginInfo = {};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

vkBeginCommandBuffer(commandBuffer, &beginInfo);

// 录制命令
vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
vkCmdBindVertexBuffers(commandBuffer, 0, 1, &vertexBuffer, &offset);
vkCmdDraw(commandBuffer, vertexCount, 1, 0, 0);

vkEndCommandBuffer(commandBuffer);
```

## 常用命令

```cpp
// 绑定管线
vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);

// 绑定描述符集
vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS,
    pipelineLayout, 0, 1, &descriptorSet, 0, nullptr);

// 绑定顶点缓冲
VkDeviceSize offset = 0;
vkCmdBindVertexBuffers(commandBuffer, 0, 1, &vertexBuffer, &offset);

// 绑定索引缓冲
vkCmdBindIndexBuffer(commandBuffer, indexBuffer, 0, VK_INDEX_TYPE_UINT32);

// 绘制
vkCmdDraw(commandBuffer, vertexCount, instanceCount, firstVertex, firstInstance);
vkCmdDrawIndexed(commandBuffer, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);

// 计算
vkCmdDispatch(commandBuffer, groupCountX, groupCountY, groupCountZ);

// 复制
vkCmdCopyBuffer(commandBuffer, srcBuffer, dstBuffer, 1, &copyRegion);
vkCmdCopyBufferToImage(commandBuffer, srcBuffer, dstImage, layout, 1, &copyRegion);
```

## Render Pass

```cpp
VkRenderPassBeginInfo renderPassInfo = {};
renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
renderPassInfo.renderPass = renderPass;
renderPassInfo.framebuffer = framebuffer;
renderPassInfo.renderArea.offset = { 0, 0 };
renderPassInfo.renderArea.extent = swapChainExtent;

VkClearValue clearValues[2] = {};
clearValues[0].color = { { 0.0f, 0.0f, 0.4f, 1.0f } };
clearValues[1].depthStencil = { 1.0f, 0 };
renderPassInfo.clearValueCount = 2;
renderPassInfo.pClearValues = clearValues;

vkCmdBeginRenderPass(commandBuffer, &renderPassInfo, VK_SUBPASS_CONTENTS_INLINE);

// 绘制命令...

vkCmdEndRenderPass(commandBuffer);
```

## 次级命令缓冲区

```cpp
VkCommandBufferAllocateInfo secondaryAlloc = {};
secondaryAlloc.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
secondaryAlloc.commandPool = commandPool;
secondaryAlloc.level = VK_COMMAND_BUFFER_LEVEL_SECONDARY;
secondaryAlloc.commandBufferCount = 1;

VkCommandBuffer secondaryCmdBuffer;
vkAllocateCommandBuffers(device, &secondaryAlloc, &secondaryCmdBuffer);

// 录制次级命令缓冲区
VkCommandBufferInheritanceInfo inheritanceInfo = {};
inheritanceInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
inheritanceInfo.renderPass = renderPass;
inheritanceInfo.subpass = 0;

VkCommandBufferBeginInfo beginInfo = {};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
beginInfo.flags = VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;
beginInfo.pInheritanceInfo = &inheritanceInfo;

vkBeginCommandBuffer(secondaryCmdBuffer, &beginInfo);
// 录制命令...
vkEndCommandBuffer(secondaryCmdBuffer);

// 在主命令缓冲区中执行
vkCmdExecuteCommands(primaryCmdBuffer, 1, &secondaryCmdBuffer);
```

## 重置和释放

```cpp
// 重置命令缓冲区
vkResetCommandBuffer(commandBuffer, 0);

// 重置命令池
vkResetCommandPool(device, commandPool, 0);

// 释放命令缓冲区
vkFreeCommandBuffers(device, commandPool, 1, &commandBuffer);
```

## 相关文件

- [queue.md](./queue.md) - 命令队列
- [pipeline.md](./pipeline.md) - 管线对象
