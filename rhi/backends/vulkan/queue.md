# Vulkan 命令队列

## 队列类型

```cpp
// 队列标志
VK_QUEUE_GRAPHICS_BIT    // 图形操作
VK_QUEUE_COMPUTE_BIT     // 计算操作
VK_QUEUE_TRANSFER_BIT    // 传输操作
VK_QUEUE_SPARSE_BINDING_BIT  // 稀疏绑定
```

## 获取队列

```cpp
VkQueue graphicsQueue;
vkGetDeviceQueue(device, graphicsFamilyIndex, 0, &graphicsQueue);

VkQueue computeQueue;
vkGetDeviceQueue(device, computeFamilyIndex, 0, &computeQueue);

VkQueue transferQueue;
vkGetDeviceQueue(device, transferFamilyIndex, 0, &transferQueue);
```

## 提交命令缓冲区

```cpp
VkSubmitInfo submitInfo = {};
submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

// 等待的信号量
VkSemaphore waitSemaphores[] = { imageAvailableSemaphore };
VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
submitInfo.waitSemaphoreCount = 1;
submitInfo.pWaitSemaphores = waitSemaphores;
submitInfo.pWaitDstStageMask = waitStages;

// 命令缓冲区
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffer;

// 发送的信号量
VkSemaphore signalSemaphores[] = { renderFinishedSemaphore };
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = signalSemaphores;

// 提交
vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFence);
```

## 等待队列空闲

```cpp
vkQueueWaitIdle(graphicsQueue);
```

## 多队列同步

```cpp
// 计算 Queue 完成后发送信号
VkSubmitInfo computeSubmit = {};
computeSubmit.signalSemaphoreCount = 1;
computeSubmit.pSignalSemaphores = &computeFinished;
vkQueueSubmit(computeQueue, 1, &computeSubmit, VK_NULL_HANDLE);

// 图形 Queue 等待计算完成
VkPipelineStageFlags waitStage = VK_PIPELINE_STAGE_VERTEX_INPUT_BIT;
VkSubmitInfo graphicsSubmit = {};
graphicsSubmit.waitSemaphoreCount = 1;
graphicsSubmit.pWaitSemaphores = &computeFinished;
graphicsSubmit.pWaitDstStageMask = &waitStage;
vkQueueSubmit(graphicsQueue, 1, &graphicsSubmit, VK_NULL_HANDLE);
```

## 队列优先级

```cpp
// 创建设备时设置优先级
float priorities[] = { 1.0f, 0.5f, 0.25f };  // 多个队列

VkDeviceQueueCreateInfo queueInfo = {};
queueInfo.queueFamilyIndex = familyIndex;
queueInfo.queueCount = 3;
queueInfo.pQueuePriorities = priorities;
```

## 相关文件

- [device.md](./device.md) - 逻辑设备
- [command-buffer.md](./command-buffer.md) - 命令缓冲区
- [synchronization.md](./synchronization.md) - 同步机制
