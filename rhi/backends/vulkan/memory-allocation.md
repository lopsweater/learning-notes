# Vulkan 内存分配

## 内存类型

```cpp
VkPhysicalDeviceMemoryProperties memProperties;
vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);

// 内存属性标志
VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT          // GPU 本地
VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT          // CPU 可见
VK_MEMORY_PROPERTY_HOST_COHERENT_BIT         // CPU 一致
VK_MEMORY_PROPERTY_HOST_CACHED_BIT           // CPU 缓存
VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT      // 延迟分配
```

## 查找内存类型

```cpp
uint32_t FindMemoryType(VkPhysicalDevice physicalDevice, 
                        uint32_t typeFilter, 
                        VkMemoryPropertyFlags properties) {
    VkPhysicalDeviceMemoryProperties memProperties;
    vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);
    
    for (uint32_t i = 0; i < memProperties.memoryTypeCount; i++) {
        if ((typeFilter & (1 << i)) && 
            (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
            return i;
        }
    }
    
    throw std::runtime_error("Failed to find suitable memory type!");
}
```

## 分配内存

```cpp
VkMemoryRequirements memRequirements;
vkGetBufferMemoryRequirements(device, buffer, &memRequirements);

VkMemoryAllocateInfo allocInfo = {};
allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
allocInfo.allocationSize = memRequirements.size;
allocInfo.memoryTypeIndex = FindMemoryType(
    physicalDevice,
    memRequirements.memoryTypeBits,
    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
);

VkDeviceMemory memory;
vkAllocateMemory(device, &allocInfo, nullptr, &memory);

// 绑定
vkBindBufferMemory(device, buffer, memory, 0);
```

## 映射内存

```cpp
void* data;
vkMapMemory(device, memory, 0, bufferSize, 0, &data);
memcpy(data, srcData, bufferSize);
vkUnmapMemory(device, memory);

// 持久映射
void* mappedData;
vkMapMemory(device, memory, 0, bufferSize, 0, &mappedData);
// 后续直接写入
memcpy(mappedData, newData, bufferSize);
// 不需要 Unmap，依赖 COHERENT 属性自动同步
```

## 内存池

```cpp
class MemoryPool {
    VkDevice m_device;
    VkDeviceMemory m_memory;
    VkDeviceSize m_size;
    VkDeviceSize m_used;
    uint8_t* m_mapped;
    
public:
    void Init(VkDevice device, VkPhysicalDevice physicalDevice, VkDeviceSize size) {
        m_device = device;
        m_size = size;
        m_used = 0;
        
        VkMemoryAllocateInfo allocInfo = {};
        allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
        allocInfo.allocationSize = size;
        allocInfo.memoryTypeIndex = FindMemoryType(physicalDevice, 0xFFFFFFFF,
            VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
        
        vkAllocateMemory(device, &allocInfo, nullptr, &m_memory);
        vkMapMemory(device, m_memory, 0, size, 0, (void**)&m_mapped);
    }
    
    Allocation Allocate(VkDeviceSize size, VkDeviceSize alignment) {
        VkDeviceSize aligned = (m_used + alignment - 1) & ~(alignment - 1);
        
        if (aligned + size > m_size) {
            return {};  // 空间不足
        }
        
        m_used = aligned + size;
        return { m_memory, aligned, m_mapped + aligned };
    }
    
    void Reset() {
        m_used = 0;
    }
};
```

## 相关文件

- [resources.md](./resources.md) - 资源管理
- [../design/memory-model.md](../design/memory-model.md) - 内存模型设计
