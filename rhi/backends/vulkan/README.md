# Vulkan 后端学习

> Vulkan 是 Khronos 推出的跨平台底层图形 API，支持 Windows/Linux/Android 等多平台。

## 目录文件

| 文件 | 内容 |
|------|------|
| `overview.md` | Vulkan 架构概览 |
| `features.md` | Vulkan 核心特性 |
| `instance.md` | 实例创建 |
| `physical-device.md` | 物理设备 |
| `device.md` | 逻辑设备 |
| `queue.md` | 命令队列 |
| `command-buffer.md` | 命令缓冲区 |
| `resources.md` | 资源管理 |
| `descriptor-set.md` | 描述符集 |
| `pipeline-layout.md` | 管线布局 |
| `pipeline.md` | 管线对象 |
| `synchronization.md` | 同步机制 |
| `memory-allocation.md` | 内存分配 |
| `image-layout.md` | 图像布局转换 |
| `validation-layers.md` | 验证层 |

## Vulkan 核心概念

### 对象层级

```
┌────────────────────────────────────────────────────────────┐
│                       VkInstance                           │
│                    (应用实例对象)                           │
└───────────────────────┬────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        ▼                               ▼
┌───────────────────┐          ┌───────────────────┐
│ VkPhysicalDevice  │          │   VkSurfaceKHR    │
│   (物理设备)      │          │    (显示表面)     │
└─────────┬─────────┘          └───────────────────┘
          │
          ▼
┌───────────────────┐
│    VkDevice       │
│   (逻辑设备)      │
└─────────┬─────────┘
          │
    ┌─────┴─────┬─────────────┐
    ▼           ▼             ▼
┌───────┐  ┌─────────┐  ┌──────────┐
│VkQueue│  │VkBuffer │  │VkCommand │
│ (队列)│  │/VkImage │  │  Buffer  │
└───────┘  └─────────┘  └──────────┘
```

### 1. 绑定模型 (Binding Model)

Vulkan 的绑定模型基于 **Descriptor Set** 和 **Pipeline Layout**：

```
┌─────────────────────────────────────────────────────────────────┐
│                     Pipeline Layout                              │
├─────────────────────────────────────────────────────────────────┤
│  Set 0: Per-Frame Data                                          │
│    ├── Binding 0: Uniform Buffer (Camera)                       │
│    └── Binding 1: Uniform Buffer (Light)                        │
│                                                                 │
│  Set 1: Per-Material Data                                       │
│    ├── Binding 0: Combined Image Sampler (Albedo)               │
│    ├── Binding 1: Combined Image Sampler (Normal)               │
│    └── Binding 2: Combined Image Sampler (MetallicRoughness)    │
│                                                                 │
│  Set 2: Per-Object Data                                         │
│    └── Binding 0: Uniform Buffer (Transform)                    │
└─────────────────────────────────────────────────────────────────┘
```

### 2. 描述符集 (Descriptor Set)

```cpp
// Descriptor Set Layout
VkDescriptorSetLayoutBinding bindings[] = {
    { 0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, VK_SHADER_STAGE_VERTEX_BIT },
    { 1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, VK_SHADER_STAGE_FRAGMENT_BIT }
};

VkDescriptorSetLayoutCreateInfo layoutInfo = {};
layoutInfo.bindingCount = 2;
layoutInfo.pBindings = bindings;

VkDescriptorSetLayout layout;
vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &layout);

// Allocate Descriptor Set
VkDescriptorSetAllocateInfo allocInfo = {};
allocInfo.descriptorPool = descriptorPool;
allocInfo.descriptorSetCount = 1;
allocInfo.pSetLayouts = &layout;

VkDescriptorSet descriptorSet;
vkAllocateDescriptorSets(device, &allocInfo, &descriptorSet);
```

### 3. 图像布局 (Image Layout)

Vulkan 要求显式管理图像布局：

```cpp
VkImageMemoryBarrier barrier = {};
barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
barrier.srcAccessMask = 0;
barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
barrier.image = image;
barrier.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };

vkCmdPipelineBarrier(
    commandBuffer,
    VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
    VK_PIPELINE_STAGE_TRANSFER_BIT,
    0, 0, nullptr, 0, nullptr, 1, &barrier
);
```

### 4. 命令缓冲区类型

| 类型 | 用途 |
|------|------|
| `VK_COMMAND_BUFFER_LEVEL_PRIMARY` | 主命令缓冲，直接提交 |
| `VK_COMMAND_BUFFER_LEVEL_SECONDARY` | 次级命令缓冲，被主缓冲调用 |

## Vulkan 特有功能

### Push Constants
快速更新小块常量数据，无需描述符：

```cpp
// Pipeline Layout 中定义
VkPushConstantRange pushRange = {};
pushRange.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
pushRange.offset = 0;
pushRange.size = 64;  // 最大 128 bytes guaranteed

// 更新 Push Constants
glm::mat4 model;
vkCmdPushConstants(commandBuffer, pipelineLayout, 
    VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(model), &model);
```

### Subpasses
RenderPass 内的子通道，支持片上内存复用：

```cpp
VkSubpassDescription subpasses[2] = {};
subpasses[0].pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
subpasses[0].colorAttachmentCount = 1;
subpasses[0].pColorAttachments = &colorAttachmentRef;

subpasses[1].pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
subpasses[1].inputAttachmentCount = 1;
subpasses[1].pInputAttachments = &inputAttachmentRef;  // 读取上一个 subpass 的输出

// Subpass Dependency
VkSubpassDependency dependency = {};
dependency.srcSubpass = 0;
dependency.dstSubpass = 1;
dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
dependency.dstStageMask = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
```

### Validation Layers
强大的调试验证支持：

```cpp
const char* layers[] = { "VK_LAYER_KHRONOS_validation" };

VkInstanceCreateInfo createInfo = {};
createInfo.enabledLayerCount = 1;
createInfo.ppEnabledLayerNames = layers;

// 启用后，Vulkan 会检测:
// - 无效参数
// - 资源生命周期问题
// - 同步问题
// - 性能警告
```

### 扩展机制

```cpp
// Instance Extensions
const char* instanceExtensions[] = {
    VK_KHR_SURFACE_EXTENSION_NAME,
    VK_KHR_WIN32_SURFACE_EXTENSION_NAME
};

// Device Extensions
const char* deviceExtensions[] = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    VK_KHR_RAY_TRACING_PIPELINE_EXTENSION_NAME
};
```

## 内存类型

Vulkan 要求显式选择内存类型：

```cpp
VkPhysicalDeviceMemoryProperties memProps;
vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProps);

// 查找合适的内存类型
uint32_t FindMemoryType(uint32_t typeFilter, VkMemoryPropertyFlags properties) {
    for (uint32_t i = 0; i < memProps.memoryTypeCount; i++) {
        if ((typeFilter & (1 << i)) && 
            (memProps.memoryTypes[i].propertyFlags & properties) == properties) {
            return i;
        }
    }
    return -1;
}
```

## 学习路径

1. `instance.md` - 创建 Vulkan 实例
2. `physical-device.md` - 选择物理设备
3. `device.md` - 创建逻辑设备
4. `queue.md` - 获取命令队列
5. `command-buffer.md` - 学习命令缓冲区
6. `descriptor-set.md` - 学习描述符集
7. `synchronization.md` - 学习同步机制

## 官方资源

- [Vulkan 官方文档](https://www.vulkan.org/)
- [Vulkan Tutorial](https://vulkan-tutorial.com/)
- [Vulkan Spec](https://registry.khronos.org/vulkan/specs/1.3/html/)
