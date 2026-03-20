---
name: rhi-vulkan
description: Use this skill when implementing Vulkan backend, debugging Vulkan issues, optimizing Vulkan performance, or learning Vulkan API.
origin: EVC
---

# Vulkan Backend Implementation

This skill provides implementation details for Vulkan RHI backend.

## When to Activate

- Implementing Vulkan backend
- Debugging Vulkan issues
- Optimizing Vulkan performance
- Learning Vulkan API

## 核心对象

### Instance

```cpp
class VulkanInstance {
public:
    bool Initialize(const InstanceCreateInfo& createInfo) {
        // 1. 应用信息
        VkApplicationInfo appInfo = {};
        appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
        appInfo.pApplicationName = createInfo.appName;
        appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
        appInfo.pEngineName = "Engine";
        appInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
        appInfo.apiVersion = VK_API_VERSION_1_3;
        
        // 2. 实例创建信息
        VkInstanceCreateInfo instanceInfo = {};
        instanceInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
        instanceInfo.pApplicationInfo = &appInfo;
        
        // 3. 启用层（调试）
        const char* layers[] = {
            "VK_LAYER_KHRONOS_validation",
        };
        #ifdef _DEBUG
        instanceInfo.enabledLayerCount = 1;
        instanceInfo.ppEnabledLayerNames = layers;
        #endif
        
        // 4. 启用扩展
        std::vector<const char*> extensions;
        extensions.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
        extensions.push_back(VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
        #ifdef _DEBUG
        extensions.push_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
        #endif
        
        instanceInfo.enabledExtensionCount = extensions.size();
        instanceInfo.ppEnabledExtensionNames = extensions.data();
        
        // 5. 创建实例
        VkResult result = vkCreateInstance(&instanceInfo, nullptr, &instance_);
        return result == VK_SUCCESS;
    }
    
private:
    VkInstance instance_;
};
```

### Physical Device 选择

```cpp
VkPhysicalDevice SelectPhysicalDevice(VkInstance instance) {
    uint32_t deviceCount = 0;
    vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
    
    std::vector<VkPhysicalDevice> devices(deviceCount);
    vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());
    
    // 选择第一个独立 GPU
    for (auto device : devices) {
        VkPhysicalDeviceProperties props;
        vkGetPhysicalDeviceProperties(device, &props);
        
        if (props.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            return device;
        }
    }
    
    // 回退到第一个设备
    return devices.empty() ? VK_NULL_HANDLE : devices[0];
}
```

### Device

```cpp
class VulkanDevice : public RHIDevice {
public:
    bool Initialize(VkPhysicalDevice physicalDevice) {
        // 1. 队列族索引
        uint32_t queueFamilyCount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, nullptr);
        
        std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
        vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, queueFamilies.data());
        
        graphicsQueueFamily_ = FindGraphicsQueueFamily(queueFamilies);
        
        // 2. 队列创建信息
        float priority = 1.0f;
        VkDeviceQueueCreateInfo queueInfo = {};
        queueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        queueInfo.queueFamilyIndex = graphicsQueueFamily_;
        queueInfo.queueCount = 1;
        queueInfo.pQueuePriorities = &priority;
        
        // 3. 设备创建信息
        VkDeviceCreateInfo deviceInfo = {};
        deviceInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
        deviceInfo.queueCreateInfoCount = 1;
        deviceInfo.pQueueCreateInfos = &queueInfo;
        
        // 4. 启用扩展
        const char* extensions[] = {
            VK_KHR_SWAPCHAIN_EXTENSION_NAME,
            VK_KHR_TIMELINE_SEMAPHORE_EXTENSION_NAME,
            VK_KHR_SYNCHRONIZATION_2_EXTENSION_NAME,
        };
        deviceInfo.enabledExtensionCount = 3;
        deviceInfo.ppEnabledExtensionNames = extensions;
        
        // 5. 启用特性
        VkPhysicalDeviceFeatures features = {};
        features.samplerAnisotropy = VK_TRUE;
        features.fillModeNonSolid = VK_TRUE;
        deviceInfo.pEnabledFeatures = &features;
        
        // 6. 创建设备
        VkResult result = vkCreateDevice(physicalDevice, &deviceInfo, nullptr, &device_);
        if (result != VK_SUCCESS) return false;
        
        // 7. 获取队列
        vkGetDeviceQueue(device_, graphicsQueueFamily_, 0, &graphicsQueue_);
        
        return true;
    }
    
private:
    VkDevice device_;
    VkQueue graphicsQueue_;
    uint32_t graphicsQueueFamily_;
};
```

### Buffer

```cpp
class VulkanBuffer : public RHIBuffer {
public:
    static VulkanBuffer* Create(VkDevice device, const BufferDesc& desc,
                                VkPhysicalDeviceMemoryProperties memProps) {
        // 1. 创建 Buffer
        VkBufferCreateInfo bufferInfo = {};
        bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
        bufferInfo.size = AlignUp(desc.size, desc.alignment);
        bufferInfo.usage = ConvertBufferUsage(desc.usage);
        bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
        
        VkBuffer buffer;
        VkResult result = vkCreateBuffer(device, &bufferInfo, nullptr, &buffer);
        if (result != VK_SUCCESS) return nullptr;
        
        // 2. 查询内存需求
        VkMemoryRequirements memReqs;
        vkGetBufferMemoryRequirements(device, buffer, &memReqs);
        
        // 3. 分配内存
        VkMemoryAllocateInfo allocInfo = {};
        allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
        allocInfo.allocationSize = memReqs.size;
        allocInfo.memoryTypeIndex = FindMemoryType(
            memProps,
            memReqs.memoryTypeBits,
            ConvertMemoryType(desc.memoryType)
        );
        
        VkDeviceMemory memory;
        result = vkAllocateMemory(device, &allocInfo, nullptr, &memory);
        if (result != VK_SUCCESS) {
            vkDestroyBuffer(device, buffer, nullptr);
            return nullptr;
        }
        
        // 4. 绑定内存
        vkBindBufferMemory(device, buffer, memory, 0);
        
        // 5. 设置调试名称
        if (desc.debugName) {
            SetDebugName(device, VK_OBJECT_TYPE_BUFFER, (uint64_t)buffer, desc.debugName);
        }
        
        return new VulkanBuffer(buffer, memory, desc);
    }
    
    // GPU 地址（需要设备地址扩展）
    uint64_t GetGPUAddress() const override {
        VkBufferDeviceAddressInfo info = {};
        info.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO;
        info.buffer = buffer_;
        return vkGetBufferDeviceAddress(device_, &info);
    }
    
    // 映射
    void* Map() override {
        if (mappedPtr_) return mappedPtr_;
        
        vkMapMemory(device_, memory_, 0, desc_.size, 0, &mappedPtr_);
        return mappedPtr_;
    }
    
    void Unmap() override {
        if (mappedPtr_) {
            vkUnmapMemory(device_, memory_);
            mappedPtr_ = nullptr;
        }
    }
    
private:
    VkDevice device_;
    VkBuffer buffer_;
    VkDeviceMemory memory_;
    BufferDesc desc_;
    void* mappedPtr_ = nullptr;
};
```

### Image

```cpp
class VulkanTexture : public RHITexture {
public:
    static VulkanTexture* Create(VkDevice device, const TextureDesc& desc,
                                  VkPhysicalDeviceMemoryProperties memProps) {
        // 1. 创建 Image
        VkImageCreateInfo imageInfo = {};
        imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
        imageInfo.imageType = ConvertImageType(desc.dimension);
        imageInfo.format = ConvertFormat(desc.format);
        imageInfo.extent.width = desc.width;
        imageInfo.extent.height = desc.height;
        imageInfo.extent.depth = desc.depth;
        imageInfo.mipLevels = desc.mipLevels;
        imageInfo.arrayLayers = desc.arraySize;
        imageInfo.samples = static_cast<VkSampleCountFlagBits>(desc.sampleCount);
        imageInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
        imageInfo.usage = ConvertImageUsage(desc.usage);
        imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
        imageInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        
        VkImage image;
        VkResult result = vkCreateImage(device, &imageInfo, nullptr, &image);
        if (result != VK_SUCCESS) return nullptr;
        
        // 2. 分配内存
        VkMemoryRequirements memReqs;
        vkGetImageMemoryRequirements(device, image, &memReqs);
        
        VkMemoryAllocateInfo allocInfo = {};
        allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
        allocInfo.allocationSize = memReqs.size;
        allocInfo.memoryTypeIndex = FindMemoryType(
            memProps,
            memReqs.memoryTypeBits,
            VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
        );
        
        VkDeviceMemory memory;
        result = vkAllocateMemory(device, &allocInfo, nullptr, &memory);
        if (result != VK_SUCCESS) {
            vkDestroyImage(device, image, nullptr);
            return nullptr;
        }
        
        // 3. 绑定内存
        vkBindImageMemory(device, image, memory, 0);
        
        return new VulkanTexture(image, memory, desc);
    }
    
private:
    VkImage image_;
    VkDeviceMemory memory_;
    TextureDesc desc_;
};
```

### Command Buffer

```cpp
class VulkanCommandList : public RHICommandList {
public:
    void Begin() override {
        // 重置命令池
        vkResetCommandPool(device_, commandPool_, 0);
        
        // 开始命令缓冲
        VkCommandBufferBeginInfo beginInfo = {};
        beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        
        vkBeginCommandBuffer(commandBuffer_, &beginInfo);
    }
    
    void End() override {
        vkEndCommandBuffer(commandBuffer_);
    }
    
    // 资源屏障
    void Barrier(const BarrierDesc& desc) override {
        if (desc.texture) {
            VkImageMemoryBarrier barrier = {};
            barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
            barrier.image = static_cast<VulkanTexture*>(desc.texture)->GetImage();
            barrier.oldLayout = ConvertImageLayout(desc.stateBefore);
            barrier.newLayout = ConvertImageLayout(desc.stateAfter);
            barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
            barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
            barrier.subresourceRange = {
                ConvertImageAspect(desc.format),
                0, VK_REMAINING_MIP_LEVELS,
                0, VK_REMAINING_ARRAY_LAYERS
            };
            
            VkPipelineStageFlags srcStage = GetPipelineStage(desc.stateBefore);
            VkPipelineStageFlags dstStage = GetPipelineStage(desc.stateAfter);
            
            vkCmdPipelineBarrier(
                commandBuffer_,
                srcStage, dstStage,
                0,
                0, nullptr,
                0, nullptr,
                1, &barrier
            );
        }
    }
    
private:
    VkDevice device_;
    VkCommandPool commandPool_;
    VkCommandBuffer commandBuffer_;
};
```

## 转换函数

### Buffer Usage

```cpp
VkBufferUsageFlags ConvertBufferUsage(BufferUsage usage) {
    VkBufferUsageFlags flags = 0;
    
    if (HasFlag(usage, BufferUsage::VertexBuffer))
        flags |= VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    if (HasFlag(usage, BufferUsage::IndexBuffer))
        flags |= VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
    if (HasFlag(usage, BufferUsage::ConstantBuffer))
        flags |= VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
    if (HasFlag(usage, BufferUsage::ShaderResource))
        flags |= VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
    if (HasFlag(usage, BufferUsage::UnorderedAccess))
        flags |= VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
    if (HasFlag(usage, BufferUsage::TransferSrc))
        flags |= VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
    if (HasFlag(usage, BufferUsage::TransferDst))
        flags |= VK_BUFFER_USAGE_TRANSFER_DST_BIT;
    
    // 设备地址（加速结构）
    flags |= VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
    
    return flags;
}
```

### Image Layout

```cpp
VkImageLayout ConvertImageLayout(ResourceState state) {
    switch (state) {
        case ResourceState::Common:          return VK_IMAGE_LAYOUT_UNDEFINED;
        case ResourceState::ShaderResource:  return VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
        case ResourceState::UnorderedAccess: return VK_IMAGE_LAYOUT_GENERAL;
        case ResourceState::RenderTarget:    return VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
        case ResourceState::DepthWrite:      return VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
        case ResourceState::DepthRead:       return VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
        case ResourceState::Present:         return VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
        case ResourceState::CopySrc:         return VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        case ResourceState::CopyDst:         return VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    }
    return VK_IMAGE_LAYOUT_UNDEFINED;
}
```

### Format

```cpp
VkFormat ConvertFormat(Format format) {
    static const VkFormat mapping[] = {
        [Format::Unknown]        = VK_FORMAT_UNDEFINED,
        [Format::R8G8B8A8_UNORM] = VK_FORMAT_R8G8B8A8_UNORM,
        [Format::R8G8B8A8_SRGB]  = VK_FORMAT_R8G8B8A8_SRGB,
        [Format::B8G8R8A8_UNORM] = VK_FORMAT_B8G8R8A8_UNORM,
        [Format::B8G8R8A8_SRGB]  = VK_FORMAT_B8G8R8A8_SRGB,
        [Format::R32G32B32A32_FLOAT] = VK_FORMAT_R32G32B32A32_SFLOAT,
        [Format::R16G16B16A16_FLOAT] = VK_FORMAT_R16G16B16A16_SFLOAT,
        [Format::D32_FLOAT]      = VK_FORMAT_D32_SFLOAT,
        [Format::D24_UNORM_S8_UINT] = VK_FORMAT_D24_UNORM_S8_UINT,
        [Format::BC1_UNORM]      = VK_FORMAT_BC1_RGB_UNORM_BLOCK,
        [Format::BC3_UNORM]      = VK_FORMAT_BC3_UNORM_BLOCK,
        [Format::BC5_UNORM]      = VK_FORMAT_BC5_UNORM_BLOCK,
        [Format::BC7_UNORM]      = VK_FORMAT_BC7_UNORM_BLOCK,
    };
    return mapping[static_cast<int>(format)];
}
```

## 同步

### Timeline Semaphore

```cpp
class VulkanFence {
public:
    VulkanFence(VkDevice device) : device_(device) {
        VkSemaphoreTypeCreateInfo timelineInfo = {};
        timelineInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO;
        timelineInfo.semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE;
        timelineInfo.initialValue = 0;
        
        VkSemaphoreCreateInfo semInfo = {};
        semInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
        semInfo.pNext = &timelineInfo;
        
        vkCreateSemaphore(device, &semInfo, nullptr, &semaphore_);
    }
    
    uint64_t GetCompletedValue() {
        uint64_t value;
        vkGetSemaphoreCounterValue(device_, semaphore_, &value);
        return value;
    }
    
    void Signal(uint64_t value) {
        VkSemaphoreSignalInfo signalInfo = {};
        signalInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SIGNAL_INFO;
        signalInfo.semaphore = semaphore_;
        signalInfo.value = value;
        vkSignalSemaphore(device_, &signalInfo);
    }
    
    void Wait(uint64_t value) {
        VkSemaphoreWaitInfo waitInfo = {};
        waitInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
        waitInfo.semaphoreCount = 1;
        waitInfo.pSemaphores = &semaphore_;
        waitInfo.pValues = &value;
        vkWaitSemaphores(device_, &waitInfo, UINT64_MAX);
    }
    
private:
    VkDevice device_;
    VkSemaphore semaphore_;
};
```

## 调试

### 验证层

```cpp
void SetupDebugMessenger(VkInstance instance) {
    VkDebugUtilsMessengerCreateInfoEXT createInfo = {};
    createInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    createInfo.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                                  VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
                                  VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    createInfo.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
                             VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
                             VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    createInfo.pfnUserCallback = DebugCallback;
    
    auto func = (PFN_vkCreateDebugUtilsMessengerEXT)vkGetInstanceProcAddr(
        instance, "vkCreateDebugUtilsMessengerEXT");
    if (func) {
        func(instance, &createInfo, nullptr, &debugMessenger_);
    }
}

static VKAPI_ATTR VkBool32 VKAPI_CALL DebugCallback(
    VkDebugUtilsMessageSeverityFlagBitsEXT severity,
    VkDebugUtilsMessageTypeFlagsEXT type,
    const VkDebugUtilsMessengerCallbackDataEXT* data,
    void* userData) {
    
    printf("[Vulkan] %s\n", data->pMessage);
    return VK_FALSE;
}
```

### 调试名称

```cpp
void SetDebugName(VkDevice device, VkObjectType type, uint64_t handle, const char* name) {
    VkDebugUtilsObjectNameInfoEXT nameInfo = {};
    nameInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
    nameInfo.objectType = type;
    nameInfo.objectHandle = handle;
    nameInfo.pObjectName = name;
    
    auto func = (PFN_vkSetDebugUtilsObjectNameEXT)vkGetDeviceProcAddr(
        device, "vkSetDebugUtilsObjectNameEXT");
    if (func) {
        func(device, &nameInfo);
    }
}
```

## 相关 Skills

- `rhi-patterns` - RHI 设计模式
- `rhi-d3d12` - D3D12 后端实现
