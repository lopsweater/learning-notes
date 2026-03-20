# Vulkan 同步机制

## Fence

用于 CPU 等待 GPU 完成：

```cpp
// 创建 Fence
VkFenceCreateInfo fenceInfo = {};
fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;  // 初始为 signaled

VkFence fence;
vkCreateFence(device, &fenceInfo, nullptr, &fence);

// 提交时使用
vkQueueSubmit(queue, 1, &submitInfo, fence);

// CPU 等待
vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX);

// 重置
vkResetFences(device, 1, &fence);
```

## Semaphore

用于 GPU-GPU 同步：

```cpp
// 创建 Semaphore
VkSemaphoreCreateInfo semaphoreInfo = {};
semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

VkSemaphore semaphore;
vkCreateSemaphore(device, &semaphoreInfo, nullptr, &semaphore);

// 提交时等待和发送信号
VkSubmitInfo submitInfo = {};
submitInfo.waitSemaphoreCount = 1;
submitInfo.pWaitSemaphores = &waitSemaphore;
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = &signalSemaphore;
```

## 时间线 Semaphore (Vulkan 1.2+)

```cpp
VkSemaphoreTypeCreateInfo timelineInfo = {};
timelineInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO;
timelineInfo.semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE;
timelineInfo.initialValue = 0;

VkSemaphoreCreateInfo semaphoreInfo = {};
semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
semaphoreInfo.pNext = &timelineInfo;

VkSemaphore timelineSemaphore;
vkCreateSemaphore(device, &semaphoreInfo, nullptr, &timelineSemaphore);

// Signal
VkSemaphoreSignalInfo signalInfo = {};
signalInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SIGNAL_INFO;
signalInfo.semaphore = timelineSemaphore;
signalInfo.value = 1;
vkSignalSemaphore(device, &signalInfo);

// Wait
VkSemaphoreWaitInfo waitInfo = {};
waitInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
waitInfo.semaphoreCount = 1;
waitInfo.pSemaphores = &timelineSemaphore;
waitInfo.pValues = &(uint64_t){ 1 };
vkWaitSemaphores(device, &waitInfo, UINT64_MAX);
```

## 帧同步

```cpp
const int MAX_FRAMES_IN_FLIGHT = 2;

VkSemaphore imageAvailableSemaphores[MAX_FRAMES_IN_FLIGHT];
VkSemaphore renderFinishedSemaphores[MAX_FRAMES_IN_FLIGHT];
VkFence inFlightFences[MAX_FRAMES_IN_FLIGHT];
uint32_t currentFrame = 0;

void DrawFrame() {
    // 等待上一帧
    vkWaitForFences(device, 1, &inFlightFences[currentFrame], VK_TRUE, UINT64_MAX);
    vkResetFences(device, 1, &inFlightFences[currentFrame]);
    
    // 获取交换链图像
    uint32_t imageIndex;
    vkAcquireNextImageKHR(device, swapChain, UINT64_MAX,
        imageAvailableSemaphores[currentFrame], VK_NULL_HANDLE, &imageIndex);
    
    // 提交命令
    VkSubmitInfo submitInfo = {};
    submitInfo.waitSemaphoreCount = 1;
    submitInfo.pWaitSemaphores = &imageAvailableSemaphores[currentFrame];
    submitInfo.signalSemaphoreCount = 1;
    submitInfo.pSignalSemaphores = &renderFinishedSemaphores[currentFrame];
    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &commandBuffers[imageIndex];
    
    vkQueueSubmit(graphicsQueue, 1, &submitInfo, inFlightFences[currentFrame]);
    
    // 呈现
    VkPresentInfoKHR presentInfo = {};
    presentInfo.waitSemaphoreCount = 1;
    presentInfo.pWaitSemaphores = &renderFinishedSemaphores[currentFrame];
    presentInfo.swapchainCount = 1;
    presentInfo.pSwapchains = &swapChain;
    presentInfo.pImageIndices = &imageIndex;
    
    vkQueuePresentKHR(presentQueue, &presentInfo);
    
    currentFrame = (currentFrame + 1) % MAX_FRAMES_IN_FLIGHT;
}
```

## 相关文件

- [queue.md](./queue.md) - 命令队列
- [../design/synchronization-model.md](../design/synchronization-model.md) - 同步模型设计
