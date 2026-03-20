# Vulkan 逻辑设备创建

## 创建设备

```cpp
// 队列创建信息
float queuePriority = 1.0f;

VkDeviceQueueCreateInfo queueInfo = {};
queueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
queueInfo.queueFamilyIndex = graphicsFamily;
queueInfo.queueCount = 1;
queueInfo.pQueuePriorities = &queuePriority;

// 启用扩展
const char* extensions[] = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
};

// 启用特性
VkPhysicalDeviceFeatures features = {};
features.samplerAnisotropy = VK_TRUE;
features.fillModeNonSolid = VK_TRUE;

// 设备创建信息
VkDeviceCreateInfo deviceInfo = {};
deviceInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
deviceInfo.queueCreateInfoCount = 1;
deviceInfo.pQueueCreateInfos = &queueInfo;
deviceInfo.enabledExtensionCount = 1;
deviceInfo.ppEnabledExtensionNames = extensions;
deviceInfo.pEnabledFeatures = &features;

VkDevice device;
vkCreateDevice(physicalDevice, &deviceInfo, nullptr, &device);
```

## 多队列设备

```cpp
std::vector<VkDeviceQueueCreateInfo> queueInfos;
std::vector<float> priorities = { 1.0f };

// Graphics Queue
VkDeviceQueueCreateInfo graphicsQueueInfo = {};
graphicsQueueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
graphicsQueueInfo.queueFamilyIndex = graphicsFamily;
graphicsQueueInfo.queueCount = 1;
graphicsQueueInfo.pQueuePriorities = priorities.data();
queueInfos.push_back(graphicsQueueInfo);

// Compute Queue（如果不同）
if (computeFamily != graphicsFamily) {
    VkDeviceQueueCreateInfo computeQueueInfo = {};
    computeQueueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    computeQueueInfo.queueFamilyIndex = computeFamily;
    computeQueueInfo.queueCount = 1;
    computeQueueInfo.pQueuePriorities = priorities.data();
    queueInfos.push_back(computeQueueInfo);
}

VkDeviceCreateInfo deviceInfo = {};
deviceInfo.queueCreateInfoCount = queueInfos.size();
deviceInfo.pQueueCreateInfos = queueInfos.data();
```

## Vulkan 1.2+ 特性

```cpp
VkPhysicalDeviceVulkan12Features vulkan12Features = {};
vulkan12Features.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
vulkan12Features.descriptorIndexing = VK_TRUE;
vulkan12Features.timelineSemaphore = VK_TRUE;
vulkan12Features.bufferDeviceAddress = VK_TRUE;

VkDeviceCreateInfo deviceInfo = {};
deviceInfo.pNext = &vulkan12Features;
```

## 获取队列

```cpp
VkQueue graphicsQueue;
vkGetDeviceQueue(device, graphicsFamily, 0, &graphicsQueue);

VkQueue computeQueue;
vkGetDeviceQueue(device, computeFamily, 0, &computeQueue);

VkQueue presentQueue;
vkGetDeviceQueue(device, presentFamily, 0, &presentQueue);
```

## 销毁设备

```cpp
vkDestroyDevice(device, nullptr);
```

## 相关文件

- [physical-device.md](./physical-device.md) - 物理设备选择
- [queue.md](./queue.md) - 命令队列
