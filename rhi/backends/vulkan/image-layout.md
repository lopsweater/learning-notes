# Vulkan 图像布局转换

## 图像布局类型

| 布局 | 用途 |
|------|------|
| UNDEFINED | 初始状态，无内容 |
| GENERAL | 通用，支持所有操作 |
| COLOR_ATTACHMENT_OPTIMAL | 颜色附件 |
| DEPTH_STENCIL_ATTACHMENT_OPTIMAL | 深度模板附件 |
| DEPTH_STENCIL_READ_ONLY_OPTIMAL | 深度模板只读 |
| SHADER_READ_ONLY_OPTIMAL | 着色器只读 |
| TRANSFER_SRC_OPTIMAL | 传输源 |
| TRANSFER_DST_OPTIMAL | 传输目标 |
| PRESENT_SRC_KHR | 呈现 |

## Pipeline Barrier

```cpp
VkImageMemoryBarrier barrier = {};
barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
barrier.image = image;
barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
barrier.subresourceRange.baseMipLevel = 0;
barrier.subresourceRange.levelCount = mipLevels;
barrier.subresourceRange.baseArrayLayer = 0;
barrier.subresourceRange.layerCount = 1;

// 根据布局设置访问标志
barrier.srcAccessMask = 0;
barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

vkCmdPipelineBarrier(
    commandBuffer,
    VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,   // srcStage
    VK_PIPELINE_STAGE_TRANSFER_BIT,       // dstStage
    0,
    0, nullptr,
    0, nullptr,
    1, &barrier
);
```

## 布局转换示例

### 上传纹理

```cpp
// 1. Undefined -> Transfer Dst
TransitionImageLayout(image, 
    VK_IMAGE_LAYOUT_UNDEFINED, 
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

// 2. 复制数据
vkCmdCopyBufferToImage(...);

// 3. Transfer Dst -> Shader Read Only
TransitionImageLayout(image,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
```

### 渲染目标

```cpp
// 渲染前：Shader Read Only -> Color Attachment
TransitionImageLayout(colorTarget,
    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
    VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL);

// 渲染...

// 渲染后：Color Attachment -> Shader Read Only
TransitionImageLayout(colorTarget,
    VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
```

## 访问标志和管线阶段

| 布局 | srcAccessMask | dstAccessMask | dstStage |
|------|---------------|---------------|----------|
| UNDEFINED -> TRANSFER_DST | 0 | TRANSFER_WRITE | TRANSFER |
| TRANSFER_DST -> SHADER_READ | TRANSFER_WRITE | SHADER_READ | FRAGMENT_SHADER |
| COLOR_ATTACHMENT | COLOR_ATTACHMENT_WRITE | SHADER_READ | FRAGMENT_SHADER |
| PRESENT | COLOR_ATTACHMENT_WRITE | 0 | BOTTOM_OF_PIPE |

## 相关文件

- [resources.md](./resources.md) - 资源管理
- [../patterns/state-tracking.md](../patterns/state-tracking.md) - 状态追踪
