# Vulkan 验证层

## 启用验证层

```cpp
const char* validationLayers[] = {
    "VK_LAYER_KHRONOS_validation"
};

VkInstanceCreateInfo createInfo = {};
createInfo.enabledLayerCount = 1;
createInfo.ppEnabledLayerNames = validationLayers;
```

## Debug Messenger

```cpp
VkDebugUtilsMessengerCreateInfoEXT debugInfo = {};
debugInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
debugInfo.messageSeverity = 
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
debugInfo.messageType = 
    VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
debugInfo.pfnUserCallback = DebugCallback;

// 创建
auto func = (PFN_vkCreateDebugUtilsMessengerEXT)
    vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
func(instance, &debugInfo, nullptr, &debugMessenger);

// 回调
static VKAPI_ATTR VkBool32 VKAPI_CALL DebugCallback(
    VkDebugUtilsMessageSeverityFlagBitsEXT severity,
    VkDebugUtilsMessageTypeFlagsEXT type,
    const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData,
    void* pUserData
) {
    std::cerr << "Validation: " << pCallbackData->pMessage << std::endl;
    return VK_FALSE;
}
```

## 消息类型

| 严重性 | 说明 |
|--------|------|
| VERBOSE | 详细信息 |
| INFO | 信息 |
| WARNING | 警告 |
| ERROR | 错误 |

| 类型 | 说明 |
|------|------|
| GENERAL | 一般事件 |
| VALIDATION | 验证错误 |
| PERFORMANCE | 性能警告 |

## 常见验证错误

### 资源生命周期
```
VUID-vkDestroyBuffer-buffer-00922
Buffer 正在被使用时销毁
```

### 同步问题
```
VUID-vkCmdDraw-None-02686
资源状态不正确
```

### 描述符问题
```
VUID-vkCmdDraw-None-02699
描述符未更新
```

## 性能优化

```cpp
// 仅启用需要的严重性
debugInfo.messageSeverity = 
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;

// 仅启用需要的类型
debugInfo.messageType = 
    VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT;
```

## 相关文件

- [instance.md](./instance.md) - 实例创建
