# Vulkan 物理设备选择

## 枚举物理设备

```cpp
uint32_t deviceCount = 0;
vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);

std::vector<VkPhysicalDevice> devices(deviceCount);
vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());
```

## 查询设备属性

```cpp
// 基本属性
VkPhysicalDeviceProperties props;
vkGetPhysicalDeviceProperties(device, &props);

std::cout << "Device: " << props.deviceName << std::endl;
std::cout << "API Version: " << VK_VERSION_MAJOR(props.apiVersion) << "."
          << VK_VERSION_MINOR(props.apiVersion) << "."
          << VK_VERSION_PATCH(props.apiVersion) << std::endl;

// 设备类型
switch (props.deviceType) {
    case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:
        // 集成显卡
        break;
    case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:
        // 独立显卡
        break;
    case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU:
        // 虚拟 GPU
        break;
    case VK_PHYSICAL_DEVICE_TYPE_CPU:
        // CPU 实现
        break;
}

// 内存属性
VkPhysicalDeviceMemoryProperties memProps;
vkGetPhysicalDeviceMemoryProperties(device, &memProps);

for (uint32_t i = 0; i < memProps.memoryTypeCount; i++) {
    auto& type = memProps.memoryTypes[i];
    // 检查内存类型
    if (type.propertyFlags & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) {
        // GPU 本地内存
    }
    if (type.propertyFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
        // CPU 可见内存
    }
}
```

## 查询队列族

```cpp
uint32_t queueFamilyCount = 0;
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, nullptr);

std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.data());

int graphicsFamily = -1;
int presentFamily = -1;
int computeFamily = -1;
int transferFamily = -1;

for (int i = 0; i < queueFamilyCount; i++) {
    if (queueFamilies[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        graphicsFamily = i;
    }
    if (queueFamilies[i].queueFlags & VK_QUEUE_COMPUTE_BIT) {
        computeFamily = i;
    }
    if (queueFamilies[i].queueFlags & VK_QUEUE_TRANSFER_BIT) {
        transferFamily = i;
    }
    
    // 检查呈现支持
    VkBool32 presentSupport = false;
    vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);
    if (presentSupport) {
        presentFamily = i;
    }
}
```

## 检查扩展支持

```cpp
bool CheckDeviceExtensionSupport(VkPhysicalDevice device, 
                                  const char** required, 
                                  uint32_t count) {
    uint32_t extensionCount;
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, nullptr);
    
    std::vector<VkExtensionProperties> extensions(extensionCount);
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, extensions.data());
    
    for (uint32_t i = 0; i < count; i++) {
        bool found = false;
        for (const auto& ext : extensions) {
            if (strcmp(required[i], ext.extensionName) == 0) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return true;
}
```

## 选择最佳设备

```cpp
VkPhysicalDevice SelectPhysicalDevice(VkInstance instance) {
    uint32_t deviceCount;
    vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
    
    std::vector<VkPhysicalDevice> devices(deviceCount);
    vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());
    
    VkPhysicalDevice bestDevice = VK_NULL_HANDLE;
    int bestScore = 0;
    
    for (const auto& device : devices) {
        int score = 0;
        
        VkPhysicalDeviceProperties props;
        vkGetPhysicalDeviceProperties(device, &props);
        
        // 独立显卡优先
        if (props.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            score += 1000;
        }
        
        // 纹理大小限制
        score += props.limits.maxImageDimension2D;
        
        // 检查必要特性
        if (!CheckRequiredFeatures(device)) {
            continue;
        }
        
        if (score > bestScore) {
            bestScore = score;
            bestDevice = device;
        }
    }
    
    return bestDevice;
}
```

## 相关文件

- [instance.md](./instance.md) - 实例创建
- [device.md](./device.md) - 逻辑设备创建
