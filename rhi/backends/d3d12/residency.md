# D3D12 资源驻留管理

## 概述

D3D12 允许显式控制资源是否驻留在显存中，通过 MakeResident 和 Evict 管理显存使用。

## 基本操作

```cpp
// 使资源驻留
ID3D12Pageable* resources[] = { texture1, texture2, buffer };
device->MakeResident(3, resources);

// 驱逐资源
device->Evict(3, resources);
```

## 驻留优先级

```cpp
enum D3D12_RESIDENCY_PRIORITY {
    D3D12_RESIDENCY_PRIORITY_MINIMUM = 0x28000000,
    D3D12_RESIDENCY_PRIORITY_LOW = 0x50000000,
    D3D12_RESIDENCY_PRIORITY_NORMAL = 0x78000000,
    D3D12_RESIDENCY_PRIORITY_HIGH = 0xa0000000,
    D3D12_RESIDENCY_PRIORITY_MAXIMUM = 0xc8000000,
};

// 设置优先级
device->SetResidencyPriority(3, resources, priorities);
```

## 驻留管理器

```cpp
class ResidencyManager {
    struct ResidentResource {
        ID3D12Pageable* resource;
        UINT64 size;
        UINT64 lastUsedFrame;
        D3D12_RESIDENCY_PRIORITY priority;
    };
    
    ID3D12Device* m_device;
    UINT64 m_budget;
    UINT64 m_currentUsage;
    std::vector<ResidentResource> m_residentResources;
    std::mutex m_mutex;
    
public:
    void Init(ID3D12Device* device) {
        m_device = device;
        
        // 查询显存预算
        DXGI_QUERY_VIDEO_MEMORY_INFO info;
        // ... 获取预算 ...
        m_budget = info.Budget;
    }
    
    void MakeResident(ID3D12Pageable* resource, UINT64 size, 
                      D3D12_RESIDENCY_PRIORITY priority) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        // 检查是否需要驱逐
        while (m_currentUsage + size > m_budget * 0.9) {
            EvictLRU();
        }
        
        // 使资源驻留
        m_device->MakeResident(1, &resource);
        
        m_residentResources.push_back({resource, size, GetCurrentFrame(), priority});
        m_currentUsage += size;
    }
    
    void EvictLRU() {
        // 按最后使用时间和优先级排序
        std::sort(m_residentResources.begin(), m_residentResources.end(),
            [](const ResidentResource& a, const ResidentResource& b) {
                if (a.priority != b.priority) {
                    return a.priority < b.priority;  // 低优先级先驱逐
                }
                return a.lastUsedFrame < b.lastUsedFrame;  // 旧资源先驱逐
            });
        
        if (!m_residentResources.empty()) {
            auto& res = m_residentResources.back();
            m_device->Evict(1, &res.resource);
            m_currentUsage -= res.size;
            m_residentResources.pop_back();
        }
    }
    
    void TouchResource(ID3D12Pageable* resource) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        for (auto& res : m_residentResources) {
            if (res.resource == resource) {
                res.lastUsedFrame = GetCurrentFrame();
                break;
            }
        }
    }
};
```

## 预算查询

```cpp
void QueryBudget(IDXGIAdapter3* adapter, UINT nodeIndex) {
    DXGI_QUERY_VIDEO_MEMORY_INFO info;
    adapter->QueryVideoMemoryInfo(nodeIndex, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &info);
    
    UINT64 budget = info.Budget;          // 预算
    UINT64 currentUsage = info.CurrentUsage;  // 当前使用
    UINT64 available = info.AvailableForReservation;  // 可保留量
    
    // 如果当前使用接近预算，需要考虑驱逐资源
    if (currentUsage > budget * 0.9) {
        // 触发资源驱逐
    }
}
```

## 相关文件

- [memory-allocation.md](./memory-allocation.md) - 内存分配
- [resources.md](./resources.md) - 资源管理
