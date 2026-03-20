# Vulkan 实例创建

## 创建 Instance

```cpp
// 应用信息
VkApplicationInfo appInfo = {};
appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
appInfo.pApplicationName = "My App";
appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
appInfo.pEngineName = "My Engine";
appInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
appInfo.apiVersion = VK_API_VERSION_1_3;

// 启用层和扩展
const char* layers[] = { "VK_LAYER_KHRONOS_validation" };
const char* extensions[] = {
    VK_KHR_SURFACE_EXTENSION_NAME,
    VK_KHR_WIN32_SURFACE_EXTENSION_NAME,
};

VkInstanceCreateInfo createInfo = {};
createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
createInfo.pApplicationInfo = &appInfo;
createInfo.enabledLayerCount = 1;
createInfo.ppEnabledLayerNames = layers;
createInfo.enabledExtensionCount = 2;
createInfo.ppEnabledExtensionNames = extensions;

VkInstance instance;
VkResult result = vkCreateInstance(&createInfo, nullptr, &instance);
```

## 检查扩展支持

```cpp
bool CheckExtensionSupport(const char** required, uint32_t count) {
    uint32_t extensionCount;
    vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, nullptr);
    
    std::vector<VkExtensionProperties> extensions(extensionCount);
    vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, extensions.data());
    
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

## Debug Messenger

```cpp
VkDebugUtilsMessengerCreateInfoEXT debugInfo = {};
debugInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
debugInfo.messageSeverity = 
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
debugInfo.messageType = 
    VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
    VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
debugInfo.pfnUserCallback = DebugCallback;

VkDebugUtilsMessengerEXT debugMessenger;
auto func = (PFN_vkCreateDebugUtilsMessengerEXT)
    vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
func(instance, &debugInfo, nullptr, &debugMessenger);

// 回调函数
static VKAPI_ATTR VkBool32 VKAPI_CALL DebugCallback(
    VkDebugUtilsMessageSeverityFlagBitsEXT severity,
    VkDebugUtilsMessageTypeFlagsEXT type,
    const VkDebugUtilsMessengerCallbackDataEXT* data,
    void* userData
) {
    std::cerr << "Validation: " << data->pMessage << std::endl;
    return VK_FALSE;
}
```

## 相关文件

- [physical-device.md](./physical-device.md) - 物理设备选择
- [validation-layers.md](./validation-layers.md) - 验证层详解
