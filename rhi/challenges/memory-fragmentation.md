# 内存碎片

## 问题概述

```
初始状态：[      64MB      ]

分配 A (16MB)：[AAAA|    48MB    ]
分配 B (8MB)： [AAAA|BB|  40MB   ]
分配 C (24MB)：[AAAA|BB|CCCC|16MB]
释放 A：       [    |BB|CCCC|16MB]  ← 碎片！
分配 D (20MB)：[    |BB|CCCC|16MB]  ← 失败！虽然总空闲 40MB

问题：虽然总空闲 40MB，但最大连续块只有 16MB
```

## 解决方案

### 1. 线性分配器

```cpp
class LinearAllocator {
    uint64_t m_offset = 0;
    uint64_t m_capacity;
    
public:
    Allocation Allocate(uint64_t size) {
        if (m_offset + size > m_capacity) {
            return {};  // 空间不足
        }
        
        uint64_t offset = m_offset;
        m_offset += size;
        return { offset };
    }
    
    void Reset() {
        m_offset = 0;  // 一次性重置，无碎片
    }
};

// 适合：每帧的临时资源
```

### 2. 池化分配器

```cpp
class PoolAllocator {
    std::vector<uint64_t> m_freeList;
    uint64_t m_blockSize;
    
public:
    PoolAllocator(uint64_t blockSize, uint64_t count) 
        : m_blockSize(blockSize) {
        for (uint64_t i = 0; i < count; i++) {
            m_freeList.push_back(i * blockSize);
        }
    }
    
    uint64_t Allocate() {
        if (m_freeList.empty()) return INVALID_OFFSET;
        uint64_t offset = m_freeList.back();
        m_freeList.pop_back();
        return offset;
    }
    
    void Free(uint64_t offset) {
        m_freeList.push_back(offset);
    }
};

// 适合：固定大小的资源
```

### 3. 伙伴分配器

```cpp
class BuddyAllocator {
    // 支持 2^n 大小的块
    std::array<std::vector<uint64_t>, MAX_ORDER> m_freeLists;
    
public:
    uint64_t Allocate(uint64_t size) {
        uint32_t order = GetOrder(size);
        
        // 找到可用的块
        for (uint32_t i = order; i < MAX_ORDER; i++) {
            if (!m_freeLists[i].empty()) {
                uint64_t block = m_freeLists[i].back();
                m_freeLists[i].pop_back();
                
                // 分裂到目标大小
                while (i > order) {
                    i--;
                    uint64_t buddy = block + (1ULL << i);
                    m_freeLists[i].push_back(buddy);
                }
                
                return block;
            }
        }
        
        return INVALID_OFFSET;
    }
    
    void Free(uint64_t offset, uint64_t size) {
        uint32_t order = GetOrder(size);
        
        // 尝试合并伙伴
        while (order < MAX_ORDER - 1) {
            uint64_t buddy = offset ^ (1ULL << order);
            
            // 检查伙伴是否在空闲列表中
            auto& list = m_freeLists[order];
            auto it = std::find(list.begin(), list.end(), buddy);
            
            if (it == list.end()) break;
            
            // 合并
            list.erase(it);
            offset = std::min(offset, buddy);
            order++;
        }
        
        m_freeLists[order].push_back(offset);
    }
};

// 适合：可变大小，自动合并
```

### 4. 分帧管理

```cpp
class FrameAllocator {
    static const uint32_t FRAME_COUNT = 3;
    
    LinearAllocator m_allocators[FRAME_COUNT];
    uint32_t m_currentFrame = 0;
    
public:
    void BeginFrame() {
        m_currentFrame = (m_currentFrame + 1) % FRAME_COUNT;
        m_allocators[m_currentFrame].Reset();  // 重置 2 帧前的分配
    }
    
    Allocation Allocate(uint64_t size) {
        return m_allocators[m_currentFrame].Allocate(size);
    }
};
```

## 最佳实践

### ✅ 推荐

1. **每帧资源用线性分配器** - 帧结束重置
2. **固定大小资源用池** - 无碎片
3. **大资源单独管理** - 避免 fragmentation
4. **定期整理** - 清理碎片

### ❌ 避免

1. **频繁分配释放** - 产生碎片
2. **混合大小资源** - 难以管理
3. **忽略碎片** - 内存泄漏

## 相关文件

- [resource-aliasing.md](./resource-aliasing.md) - 资源别名
- [../design/memory-model.md](../design/memory-model.md) - 内存模型设计
