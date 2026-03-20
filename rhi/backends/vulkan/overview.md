# Vulkan 架构概览

## 设计理念

Vulkan 是一个显式的、底层的跨平台图形 API，目标是最大化 GPU 利用率和最小化 CPU 开销。

## 对象层级

```
┌─────────────────────────────────────────────────────────────┐
│                       VkInstance                            │
│                    (应用实例)                               │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
┌───────────────────┐            ┌───────────────────┐
│ VkPhysicalDevice  │            │   VkSurfaceKHR    │
│   (物理设备)      │            │    (显示表面)     │
└─────────┬─────────┘            └───────────────────┘
          │
          ▼
┌───────────────────┐
│    VkDevice       │
│   (逻辑设备)      │
└─────────┬─────────┘
          │
    ┌─────┴─────┬─────────────┬─────────────┐
    ▼           ▼             ▼             ▼
┌───────┐  ┌─────────┐  ┌──────────┐  ┌──────────┐
│VkQueue│  │VkBuffer │  │VkCommand │  │VkPipeline│
│ (队列)│  │/VkImage │  │  Buffer  │  │          │
└───────┘  └─────────┘  └──────────┘  └──────────┘
```

## 核心概念

### 显式设计

Vulkan 将许多隐式操作变为显式：

| 隐式 (OpenGL) | 显式 (Vulkan) |
|---------------|---------------|
| 驱动管理内存 | 应用分配 DeviceMemory |
| 驱动管理同步 | 应用管理 Fence/Semaphore |
| 驱动管理状态 | 应用管理 Pipeline |
| 驱动验证 | Validation Layers |

### 对象类型

| 对象 | 用途 |
|------|------|
| VkInstance | 应用实例 |
| VkPhysicalDevice | 物理设备（GPU） |
| VkDevice | 逻辑设备 |
| VkQueue | 命令队列 |
| VkCommandBuffer | 命令缓冲区 |
| VkBuffer | 缓冲区 |
| VkImage | 图像 |
| VkDeviceMemory | 设备内存 |
| VkDescriptorSet | 描述符集 |
| VkPipeline | 管线对象 |
| VkRenderPass | 渲染通道 |
| VkFramebuffer | 帧缓冲 |

## 初始化流程

```
1. vkCreateInstance()
         │
         ▼
2. vkEnumeratePhysicalDevices()
         │
         ▼
3. vkGetPhysicalDeviceQueueFamilyProperties()
         │
         ▼
4. vkCreateDevice()
         │
         ▼
5. vkGetDeviceQueue()
         │
         ▼
6. 创建其他资源...
```

## 命令提交模型

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   分配      │ ──► │   录制      │ ──► │   提交      │
│ CommandPool │     │   命令      │     │   Queue     │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                       ┌─────────────┐
                                       │   等待      │
                                       │   Fence     │
                                       └─────────────┘
```

## 相关文件

- [features.md](./features.md) - 核心特性
- [instance.md](./instance.md) - 实例创建
