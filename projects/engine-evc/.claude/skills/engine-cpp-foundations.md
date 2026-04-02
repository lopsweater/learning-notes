---
name: engine-cpp-foundations
description: C++ 基础知识 - 内存管理、智能指针、模板、并发编程等游戏引擎开发必备技能
globs:
  - "*.cpp"
  - "*.h"
  - "*.hpp"
---

# Engine C++ Foundations

> **C++ 是游戏引擎开发的核心语言，此技能提供引擎开发必备的 C++ 知识**

## 作用

提供游戏引擎开发中常用的 C++ 技术知识，包括内存管理、智能指针、模板元编程、并发编程等。

## 触发时机

- 编写 C++ 代码时
- 用户提及内存管理、智能指针、模板等关键词时
- 其他技能需要 C++ 基础知识时

## 核心知识点

### 一、内存管理

#### 1. RAII（资源获取即初始化）

```cpp
// 正确示例：使用 RAII 管理资源
class Texture
{
public:
    Texture(const std::string& path)
    {
        m_Handle = LoadTexture(path);  // 构造时获取资源
    }
    
    ~Texture()
    {
        if (m_Handle != InvalidHandle)
        {
            UnloadTexture(m_Handle);  // 析构时释放资源
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
```

#### 2. 自定义内存分配器

```cpp
// 引擎常用的线性分配器
class LinearAllocator
{
public:
    LinearAllocator(size_t size)
        : m_Buffer(new char[size])
        , m_Offset(0)
        , m_Capacity(size)
    {}
    
    ~LinearAllocator()
    {
        delete[] m_Buffer;
    }
    
    void* Allocate(size_t size, size_t alignment = alignof(std::max_align_t))
    {
        // 对齐处理
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
    size_t m_Offset;
    size_t m_Capacity;
};

// 使用示例
LinearAllocator frameAllocator(1024 * 1024);  // 1MB

void UpdateFrame()
{
    frameAllocator.Reset();  // 每帧开始时重置
    
    // 分配临时数据
    auto tempData = frameAllocator.Allocate(sizeof(TempObject));
    // ... 使用 tempData
    // 不需要手动释放，下一帧自动重置
}
```

### 二、智能指针

#### 1. 智能指针选择指南

```
┌─────────────────────────────────────────────────────┐
│              智能指针选择决策树                      │
└─────────────────────────────────────────────────────┘
                     │
           是否需要共享所有权？
                 /         \
               是           否
                │            │
          使用 shared_ptr   是否需要自定义删除器？
                │           /           \
                          否            是
                           │             │
                      使用 unique_ptr   使用 unique_ptr
                           │          + custom deleter
                      是否需要转移所有权？
                         /         \
                       是           否
                        │            │
                  使用 std::move   使用引用或指针
```

#### 2. 引擎中的智能指针使用

```cpp
// 引擎资源通常使用 shared_ptr
class ResourceManager
{
public:
    std::shared_ptr<Texture> LoadTexture(const std::string& path)
    {
        auto it = m_Textures.find(path);
        if (it != m_Textures.end())
        {
            return it->second.lock();  // 从 weak_ptr 升级
        }
        
        auto texture = std::make_shared<Texture>(path);
        m_Textures[path] = texture;  // 缓存
        return texture;
    }
    
private:
    std::unordered_map<std::string, std::weak_ptr<Texture>> m_Textures;
};

// 场景对象使用 unique_ptr
class World
{
public:
    Entity* CreateEntity()
    {
        auto entity = std::make_unique<Entity>();
        auto* ptr = entity.get();
        m_Entities.push_back(std::move(entity));
        return ptr;
    }
    
private:
    std::vector<std::unique_ptr<Entity>> m_Entities;
};
```

### 三、模板元编程

#### 1. 类型萃取（Type Traits）

```cpp
// 检测类型是否有 Update 方法
template<typename T, typename = void>
struct HasUpdate : std::false_type {};

template<typename T>
struct HasUpdate<T, std::void_t<decltype(std::declval<T>().Update(std::declval<float>()))>> 
    : std::true_type {};

// 使用 SFINAE 选择实现
template<typename T>
std::enable_if_t<HasUpdate<T>::value>
CallUpdateIfPossible(T& obj, float dt)
{
    obj.Update(dt);
}

template<typename T>
std::enable_if_t<!HasUpdate<T>::value>
CallUpdateIfPossible(T& obj, float dt)
{
    // 没有 Update 方法，什么都不做
}
```

#### 2. 变参模板（Variadic Templates）

```cpp
// 事件系统
template<typename... Args>
class Event
{
public:
    using Callback = std::function<void(Args...)>;
    
    void Subscribe(Callback callback)
    {
        m_Callbacks.push_back(std::move(callback));
    }
    
    void Emit(Args... args)
    {
        for (auto& callback : m_Callbacks)
        {
            callback(args...);
        }
    }
    
private:
    std::vector<Callback> m_Callbacks;
};

// 使用示例
Event<int, float> onValueChanged;
onValueChanged.Subscribe([](int id, float value) {
    std::cout << "Value changed: " << id << ", " << value << std::endl;
});
onValueChanged.Emit(42, 3.14f);
```

### 四、并发编程

#### 1. 线程安全的数据结构

```cpp
// 线程安全的队列
template<typename T>
class ThreadSafeQueue
{
public:
    void Push(T value)
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        m_Queue.push(std::move(value));
        m_Condition.notify_one();
    }
    
    bool TryPop(T& value)
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        if (m_Queue.empty())
        {
            return false;
        }
        value = std::move(m_Queue.front());
        m_Queue.pop();
        return true;
    }
    
    void WaitAndPop(T& value)
    {
        std::unique_lock<std::mutex> lock(m_Mutex);
        m_Condition.wait(lock, [this] { return !m_Queue.empty(); });
        value = std::move(m_Queue.front());
        m_Queue.pop();
    }
    
private:
    std::queue<T> m_Queue;
    mutable std::mutex m_Mutex;
    std::condition_variable m_Condition;
};
```

#### 2. 任务系统

```cpp
// 简单的任务调度器
class TaskScheduler
{
public:
    TaskScheduler(size_t threadCount = std::thread::hardware_concurrency())
    {
        for (size_t i = 0; i < threadCount; ++i)
        {
            m_Workers.emplace_back([this] { WorkerThread(); });
        }
    }
    
    ~TaskScheduler()
    {
        {
            std::lock_guard<std::mutex> lock(m_Mutex);
            m_Shutdown = true;
        }
        m_Condition.notify_all();
        
        for (auto& worker : m_Workers)
        {
            if (worker.joinable())
            {
                worker.join();
            }
        }
    }
    
    template<typename F>
    auto Submit(F&& task) -> std::future<decltype(task())>
    {
        using ReturnType = decltype(task());
        
        auto promise = std::make_shared<std::promise<ReturnType>>();
        auto future = promise->get_future();
        
        {
            std::lock_guard<std::mutex> lock(m_Mutex);
            m_Tasks.emplace([task = std::forward<F>(task), promise]() {
                try
                {
                    if constexpr (std::is_void_v<ReturnType>)
                    {
                        task();
                        promise->set_value();
                    }
                    else
                    {
                        promise->set_value(task());
                    }
                }
                catch (...)
                {
                    promise->set_exception(std::current_exception());
                }
            });
        }
        
        m_Condition.notify_one();
        return future;
    }
    
private:
    void WorkerThread()
    {
        while (true)
        {
            std::function<void()> task;
            
            {
                std::unique_lock<std::mutex> lock(m_Mutex);
                m_Condition.wait(lock, [this] { 
                    return m_Shutdown || !m_Tasks.empty(); 
                });
                
                if (m_Shutdown && m_Tasks.empty())
                {
                    return;
                }
                
                task = std::move(m_Tasks.front());
                m_Tasks.pop();
            }
            
            task();
        }
    }
    
    std::vector<std::thread> m_Workers;
    std::queue<std::function<void()>> m_Tasks;
    std::mutex m_Mutex;
    std::condition_variable m_Condition;
    bool m_Shutdown = false;
};
```

## 引擎开发最佳实践

### 1. 避免运行时类型信息（RTTI）

```cpp
// ❌ 不推荐：使用 dynamic_cast
Base* base = new Derived();
Derived* derived = dynamic_cast<Derived*>(base);

// ✅ 推荐：使用枚举类型
class Entity
{
public:
    enum class Type { Player, Enemy, Prop };
    virtual Type GetType() const = 0;
};

Entity* entity = ...;
if (entity->GetType() == Entity::Type::Player)
{
    Player* player = static_cast<Player*>(entity);
}
```

### 2. 避免异常（游戏引擎中）

```cpp
// ❌ 不推荐：使用异常
Texture* LoadTexture(const std::string& path)
{
    if (!FileExists(path))
        throw std::runtime_error("File not found");
    // ...
}

// ✅ 推荐：使用 Optional 或错误码
std::optional<Texture> LoadTexture(const std::string& path)
{
    if (!FileExists(path))
        return std::nullopt;
    // ...
    return texture;
}
```

### 3. 使用内联优化

```cpp
// ✅ 小函数强制内联
class Vector3
{
public:
    [[nodiscard]] FORCEINLINE float Length() const
    {
        return std::sqrt(x * x + y * y + z * z);
    }
    
    [[nodiscard]] FORCEINLINE Vector3 Normalized() const
    {
        const float len = Length();
        return len > 0.0f ? *this / len : Vector3::Zero;
    }
    
private:
    float x, y, z;
};
```

## 相关技能

- **engine-project-context** - 读取项目的 C++ 标准版本
- **engine-architecture** - 使用内存管理和并发编程知识
- **engine-rendering** - 使用模板元编程和性能优化技巧
- **engine-testing** - 测试内存管理和并发代码
