# Vulkan 核心特性

## 1. Descriptor Set (描述符集)

Vulkan 使用描述符集组织资源绑定：

```
┌────────────────────────────────────────────────────────────┐
│                    Pipeline Layout                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Set 0: Frame Data                                         │
│    ├── Binding 0: Uniform Buffer (Camera)                  │
│    └── Binding 1: Uniform Buffer (Light)                   │
│                                                            │
│  Set 1: Material Data                                      │
│    ├── Binding 0: Combined Image Sampler (Albedo)          │
│    ├── Binding 1: Combined Image Sampler (Normal)          │
│    └── Binding 2: Combined Image Sampler (Roughness)       │
│                                                            │
│  Set 2: Object Data                                        │
│    └── Binding 0: Uniform Buffer (Transform)               │
│                                                            │
│  Push Constants:                                           │
│    └── 64 bytes (Model Matrix)                             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

```cpp
// 创建 Descriptor Set Layout
VkDescriptorSetLayoutBinding bindings[] = {
    { 0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, VK_SHADER_STAGE_VERTEX_BIT },
    { 1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, VK_SHADER_STAGE_FRAGMENT_BIT }
};

VkDescriptorSetLayoutCreateInfo layoutInfo = {};
layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
layoutInfo.bindingCount = 2;
layoutInfo.pBindings = bindings;

VkDescriptorSetLayout layout;
vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &layout);
```

## 2. Push Constants

快速更新小块常量数据，无需描述符：

```cpp
// Pipeline Layout 中定义
VkPushConstantRange pushRange = {};
pushRange.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
pushRange.offset = 0;
pushRange.size = 64;  // 最大 128 bytes guaranteed

VkPipelineLayoutCreateInfo layoutInfo = {};
layoutInfo.pushConstantRangeCount = 1;
layoutInfo.pPushConstantRanges = &pushRange;

// 更新
glm::mat4 model;
vkCmdPushConstants(commandBuffer, pipelineLayout, 
    VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(model), &model);
```

## 3. Render Pass 和 Subpass

```cpp
// 创建 Render Pass
VkAttachmentDescription attachments[] = {
    // Color attachment
    {
        .format = VK_FORMAT_R8G8B8A8_UNORM,
        .samples = VK_SAMPLE_COUNT_1_BIT,
        .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = VK_ATTACHMENT_STORE_OP_STORE,
        .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    },
    // Depth attachment
    {
        .format = VK_FORMAT_D32_FLOAT,
        .samples = VK_SAMPLE_COUNT_1_BIT,
        .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    }
};

VkSubpassDescription subpass = {};
subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
subpass.colorAttachmentCount = 1;
subpass.pColorAttachments = &colorAttachmentRef;
subpass.pDepthStencilAttachment = &depthAttachmentRef;

VkRenderPassCreateInfo renderPassInfo = {};
renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
renderPassInfo.attachmentCount = 2;
renderPassInfo.pAttachments = attachments;
renderPassInfo.subpassCount = 1;
renderPassInfo.pSubpasses = &subpass;
```

## 4. Validation Layers

强大的调试验证支持：

```cpp
const char* layers[] = { "VK_LAYER_KHRONOS_validation" };

VkInstanceCreateInfo createInfo = {};
createInfo.enabledLayerCount = 1;
createInfo.ppEnabledLayerNames = layers;

// 检测内容：
// - 无效参数
// - 资源生命周期问题
// - 同步问题
// - 性能警告
```

## 5. 扩展机制

```cpp
// Instance Extensions
const char* instanceExtensions[] = {
    VK_KHR_SURFACE_EXTENSION_NAME,
    VK_KHR_WIN32_SURFACE_EXTENSION_NAME,
};

// Device Extensions
const char* deviceExtensions[] = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    VK_KHR_RAY_TRACING_PIPELINE_EXTENSION_NAME,
};

// 启用特性
VkPhysicalDeviceFeatures2 features2 = {};
features2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;

VkPhysicalDeviceVulkan12Features vulkan12Features = {};
vulkan12Features.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
vulkan12Features.descriptorIndexing = VK_TRUE;
vulkan12Features.timelineSemaphore = VK_TRUE;

features2.pNext = &vulkan12Features;
```

## 相关文件

- [overview.md](./overview.md) - 架构概览
- [descriptor-set.md](./descriptor-set.md) - 描述符集详解
