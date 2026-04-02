---
globs: ["*.cpp", "*.h", "*.hpp"]
---

# 引擎内存管理规则

> 所有涉及内存操作的代码必须遵循此规则

## 内存管理原则

### 1. RAII（资源获取即初始化）

```cpp
// ✅ 正确：使用 RAII
class Texture
{
public:
    Texture(const std::string& path)
    {
        m_Handle = LoadTexture(path);  // 构造时获取
    }
    
    ~Texture()
    {
        if (m_Handle != InvalidHandle)
        {
            UnloadTexture(m_Handle);  // 析构时释放
        }
    }
    
    // 禁止拷贝
    Texture(const Texture&) = delete;
    Texture& operator=(const Texture&) = delete;
    
    // 允许移动
    Texture(Texture&& other) noexcept
        : m_Handle(other.m_Handle)
    {
        other.m_Handle = InvalidHandle;
    }
    
private:
    TextureHandle m_Handle;
};

// ❌ 错误：手动管理
class Texture
{
public:
    Texture(const std::string& path)
    {
        m_Handle = LoadTexture(path);
    }
    
    // 忘记析构函数！内存泄漏
};
```

### 2. 使用智能指针

```cpp
// ✅ 正确：使用智能指针
class ResourceManager
{
public:
    std::shared_ptr<Texture> LoadTexture(const std::string& path)
    {
        auto texture = std::make_shared<Texture>(path);
        m_Textures[path] = texture;
        return texture;
    }
    
private:
    std::unordered_map<std::string, std::shared_ptr<Texture>> m_Textures;
};

// ❌ 错误：裸指针
class ResourceManager
{
public:
    Texture* LoadTexture(const std::string& path)
    {
        Texture* texture = new Texture(path);  // 谁负责删除？
        m_Textures[path] = texture;
        return texture;
    }
    
private:
    std::unordered_map<std::string, Texture*> m_Textures;
};
```

## 内存分配

### 1. 避免频繁分配

```cpp
// ✅ 正确：预分配
std::vector<Entity> entities;
entities.reserve(10000);  // 预分配

for (int i = 0; i < 10000; ++i)
{
    entities.push_back(CreateEntity());
}

// ❌ 错误：频繁重新分配
std::vector<Entity> entities;

for (int i = 0; i < 10000; ++i)
{
    entities.push_back(CreateEntity());  // 多次重新分配
}
```

### 2. 使用对象池

```cpp
// ✅ 正确：对象池
template<typename T>
class ObjectPool
{
public:
    T* Acquire()
    {
        if (m_FreeList.empty())
        {
            Expand();
        }
        
        T* obj = m_FreeList.back();
        m_FreeList.pop_back();
        new (obj) T();  // placement new
        return obj;
    }
    
    void Release(T* obj)
    {
        obj->~T();  // 显式析构
        m_FreeList.push_back(obj);
    }
    
private:
    void Expand()
    {
        for (int i = 0; i < m_ExpandSize; ++i)
        {
            void* memory = ::operator new(sizeof(T));
            m_FreeList.push_back(static_cast<T*>(memory));
        }
    }
    
    std::vector<T*> m_FreeList;
    size_t m_ExpandSize = 10;
};

// 使用
ObjectPool<Bullet> bulletPool;

Bullet* bullet = bulletPool.Acquire();  // 从池中获取
// ... 使用
bulletPool.Release(bullet);  // 放回池中

// ❌ 错误：频繁分配释放
Bullet* bullet = new Bullet();  // 分配
// ... 使用
delete bullet;  // 释放
```

### 3. 自定义分配器

```cpp
// 线性分配器（帧内存）
class LinearAllocator
{
public:
    LinearAllocator(size_t size)
        : m_Buffer(new char[size])
        , m_Capacity(size)
        , m_Offset(0)
    {}
    
    ~LinearAllocator()
    {
        delete[] m_Buffer;
    }
    
    void* Allocate(size_t size, size_t alignment = alignof(std::max_align_t))
    {
        // 对齐
        uintptr_t current = reinterpret_cast<uintptr_t>(m_Buffer + m_Offset);
        uintptr_t aligned = (current + alignment - 1) & ~(alignment - 1);
        size_t padding = aligned - current;
        
        if (m_Offset + padding + size > m_Capacity)
        {
            return nullptr;  // 内存不足
        }
        
        m_Offset += padding + size;
        return reinterpret_cast<void*>(aligned);
    }
    
    void Reset()
    {
        m_Offset = 0;  // 快速清空
    }
    
private:
    char* m_Buffer;
    size_t m_Capacity;
    size_t m_Offset;
};

// 使用
LinearAllocator frameAllocator(1024 * 1024);  // 1MB

void UpdateFrame()
{
    frameAllocator.Reset();  // 每帧开始重置
    
    // 分配临时数据
    TempData* data = frameAllocator.Allocate<TempData>();
    // ... 使用
    // 不需要释放，下一帧自动重置
}
```

## 内存泄漏检测

### 1. 自定义内存跟踪

```cpp
class MemoryTracker
{
public:
    struct Allocation
    {
        void* ptr;
        size_t size;
        std::string file;
        int line;
    };
    
    static void* Allocate(size_t size, const char* file, int line)
    {
        void* ptr = malloc(size);
        
        std::lock_guard<std::mutex> lock(GetMutex());
        GetAllocations()[ptr] = Allocation{ptr, size, file, line};
        
        return ptr;
    }
    
    static void Deallocate(void* ptr)
    {
        if (!ptr) return;
        
        std::lock_guard<std::mutex> lock(GetMutex());
        GetAllocations().erase(ptr);
        
        free(ptr);
    }
    
    static void ReportLeaks()
    {
        auto& allocations = GetAllocations();
        
        if (allocations.empty())
        {
            std::cout << "No memory leaks detected!\n";
            return;
        }
        
        std::cout << "=== Memory Leaks ===\n";
        for (const auto& [ptr, alloc] : allocations)
        {
            std::cout << "Leak at " << ptr << "\n";
            std::cout << "  Size: " << alloc.size << " bytes\n";
            std::cout << "  Location: " << alloc.file << ":" << alloc.line << "\n";
        }
    }
    
private:
    static std::mutex& GetMutex()
    {
        static std::mutex mutex;
        return mutex;
    }
    
    static std::unordered_map<void*, Allocation>& GetAllocations()
    {
        static std::unordered_map<void*, Allocation> allocations;
        return allocations;
    }
};

// 重载 new/delete
void* operator new(size_t size, const char* file, int line)
{
    return MemoryTracker::Allocate(size, file, line);
}

void operator delete(void* ptr) noexcept
{
    MemoryTracker::Deallocate(ptr);
}

#define new new(__FILE__, __LINE__)

// 使用
int main()
{
    // 测试代码...
    
    MemoryTracker::ReportLeaks();
    return 0;
}
```

### 2. 使用工具检测

```bash
# Valgrind
valgrind --leak-check=full ./MyEngine

# AddressSanitizer (GCC/Clang)
g++ -fsanitize=address -g main.cpp -o MyEngine

# Visual Studio 内存检测
_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
```

## 内存安全规则

### 1. 初始化所有变量

```cpp
// ✅ 正确：初始化
int count = 0;
float* ptr = nullptr;
Entity* entity = nullptr;
std::vector<int> values;
values.reserve(100);

// ❌ 错误：未初始化
int count;
float* ptr;
Entity* entity;
```

### 2. 检查空指针

```cpp
// ✅ 正确：检查空指针
void ProcessEntity(Entity* entity)
{
    if (!entity)
    {
        LOG_ERROR("Entity is null");
        return;
    }
    
    // ... 处理
}

// ❌ 错误：不检查
void ProcessEntity(Entity* entity)
{
    entity->Update();  // 如果 entity 为空，崩溃
}
```

### 3. 边界检查

```cpp
// ✅ 正确：边界检查
int GetElement(const std::vector<int>& vec, size_t index)
{
    if (index >= vec.size())
    {
        LOG_ERROR("Index out of bounds: {} >= {}", index, vec.size());
        return -1;
    }
    return vec[index];
}

// 或使用 at()
int GetElement(const std::vector<int>& vec, size_t index)
{
    return vec.at(index);  // 抛出异常
}

// ❌ 错误：无边界检查
int GetElement(const std::vector<int>& vec, size_t index)
{
    return vec[index];  // 可能越界
}
```

### 4. 避免悬垂指针

```cpp
// ✅ 正确：使用智能指针
std::shared_ptr<Entity> entity = std::make_shared<Entity>();
std::weak_ptr<Entity> weakEntity = entity;  // 不增加引用计数

if (auto locked = weakEntity.lock())
{
    locked->Update();  // 安全
}

// ❌ 错误：悬垂指针
Entity* entity = new Entity();
delete entity;
entity->Update();  // 使用已释放的内存
```

## 内存优化技巧

### 1. 减少内存碎片

```cpp
// ✅ 正确：预分配大块内存
std::vector<Entity> entities;
entities.reserve(10000);  // 一次分配

// ❌ 错误：多次小分配
for (int i = 0; i < 10000; ++i)
{
    entities.push_back(Entity());  // 可能多次重新分配
}
```

### 2. 数据对齐

```cpp
// ✅ 正确：对齐到缓存行
struct alignas(64) CacheAlignedData
{
    float data[16];
};

// ❌ 错误：未对齐
struct UnalignedData
{
    float data[16];
};
```

### 3. 减少内存占用

```cpp
// ✅ 正确：使用合适的数据类型
using EntityID = uint32_t;  // 4 bytes，足够表示 40 亿个实体

struct TransformComponent
{
    Vector3 position;      // 12 bytes
    Quaternion rotation;   // 16 bytes
    Vector3 scale;         // 12 bytes
};  // Total: 40 bytes

// ❌ 错误：过度使用大类型
using EntityID = uint64_t;  // 8 bytes，浪费

struct TransformComponent
{
    Vector3d position;     // 24 bytes (double)
    Matrix4 rotation;      // 64 bytes (过度)
    Vector3d scale;        // 24 bytes
};  // Total: 112 bytes，浪费
```

## 内存检查清单

每次提交涉及内存的代码前检查：

- [ ] 使用了 RAII 管理资源
- [ ] 使用了智能指针而非裸指针
- [ ] 预分配了容器内存
- [ ] 考虑了对象池重用
- [ ] 所有变量都初始化了
- [ ] 检查了空指针
- [ ] 检查了数组边界
- [ ] 避免了悬垂指针
- [ ] 没有内存泄漏
- [ ] 使用 Valgrind/ASan 检测过
