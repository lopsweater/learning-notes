---
name: engine-architecture
description: 游戏引擎架构设计 - ECS系统、事件系统、模块设计、资源管理等架构模式
globs:
  - "**/architecture/**"
  - "**/ecs/**"
  - "**/core/**"
---

# Engine Architecture

> **游戏引擎架构是引擎开发的核心，此技能提供架构设计模式和最佳实践**

## 作用

提供游戏引擎架构设计知识，包括 ECS（Entity Component System）、事件系统、模块化设计、资源管理等。

## 触发时机

- 设计引擎架构时
- 实现核心系统时
- 用户提及 ECS、事件系统、模块化等关键词时

## 核心架构模式

### 一、ECS（Entity Component System）

#### 1. ECS 基本概念

```
┌────────────────────────────────────────────────────────┐
│                  ECS 架构图                             │
└────────────────────────────────────────────────────────┘

Entity (实体) - 只是一个 ID
┌─────┐
│ ID: │
│ 42  │ ────────────┐
└─────┘             │
                    ▼
Component (组件) - 纯数据
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Transform    │  │ Velocity     │  │ Sprite       │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ x, y, z      │  │ dx, dy, dz   │  │ texture, uv  │
│ rotation     │  │ speed        │  │ color        │
│ scale        │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
        ▲                  ▲                  ▲
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                           ▼
System (系统) - 纯逻辑
┌──────────────────────────────────────────┐
│ MovementSystem                           │
├──────────────────────────────────────────┤
│ Update(dt):                              │
│   for each (transform, velocity):        │
│     transform.position += velocity * dt  │
└──────────────────────────────────────────┘
```

#### 2. ECS 实现示例

```cpp
// Component: 纯数据结构
struct TransformComponent
{
    Vector3 position{0.0f};
    Quaternion rotation{Vector3::Forward, 0.0f};
    Vector3 scale{1.0f};
};

struct VelocityComponent
{
    Vector3 velocity{0.0f};
    float speed{1.0f};
};

struct SpriteComponent
{
    TextureHandle texture;
    Vector4 color{1.0f};
    Rect uvRect{0.0f, 0.0f, 1.0f, 1.0f};
};

// Entity: 只是 ID
using EntityID = uint64_t;

class Entity
{
public:
    EntityID GetID() const { return m_ID; }
    
    template<typename T>
    T& GetComponent();
    
    template<typename T>
    bool HasComponent() const;
    
    template<typename T, typename... Args>
    T& AddComponent(Args&&... args);
    
    template<typename T>
    void RemoveComponent();
    
private:
    EntityID m_ID;
    World* m_World;
};

// World: 管理所有实体和组件
class World
{
public:
    Entity CreateEntity()
    {
        EntityID id = m_NextEntityID++;
        m_Entities.insert(id);
        return Entity{id, this};
    }
    
    void DestroyEntity(EntityID id)
    {
        // 删除所有组件
        for (auto& [type, pool] : m_ComponentPools)
        {
            pool->Remove(id);
        }
        m_Entities.erase(id);
    }
    
    template<typename T>
    T& GetComponent(EntityID id)
    {
        auto& pool = GetOrCreatePool<T>();
        return pool.template Get<T>(id);
    }
    
    template<typename T, typename... Args>
    T& AddComponent(EntityID id, Args&&... args)
    {
        auto& pool = GetOrCreatePool<T>();
        return pool.template Add<T>(id, std::forward<Args>(args)...);
    }
    
private:
    EntityID m_NextEntityID = 1;
    std::unordered_set<EntityID> m_Entities;
    std::unordered_map<std::type_index, std::unique_ptr<IComponentPool>> m_ComponentPools;
};

// System: 纯逻辑
class MovementSystem : public System
{
public:
    void Update(float deltaTime) override
    {
        // 遍历所有拥有 Transform 和 Velocity 组件的实体
        for (auto [entity, transform, velocity] : 
             m_World->View<TransformComponent, VelocityComponent>())
        {
            transform.position += velocity.velocity * deltaTime * velocity.speed;
        }
    }
};

class RenderSystem : public System
{
public:
    void Update(float deltaTime) override
    {
        // 按渲染顺序排序
        std::vector<Entity> renderables;
        for (auto [entity, transform, sprite] : 
             m_World->View<TransformComponent, SpriteComponent>())
        {
            renderables.push_back(entity);
        }
        
        // 按深度排序
        std::sort(renderables.begin(), renderables.end(), 
            [this](Entity a, Entity b) {
                return m_World->GetComponent<TransformComponent>(a).position.z <
                       m_World->GetComponent<TransformComponent>(b).position.z;
            });
        
        // 渲染
        for (auto entity : renderables)
        {
            auto& transform = m_World->GetComponent<TransformComponent>(entity);
            auto& sprite = m_World->GetComponent<SpriteComponent>(entity);
            RenderSprite(transform, sprite);
        }
    }
};
```

### 二、事件系统

#### 1. 观察者模式

```cpp
// 事件基类
struct Event
{
    virtual ~Event() = default;
    virtual const char* GetName() const = 0;
};

// 具体事件
struct EntityDestroyedEvent : public Event
{
    EntityID entityID;
    
    const char* GetName() const override { return "EntityDestroyedEvent"; }
};

// 事件处理器
class EventHandler
{
public:
    template<typename T, typename F>
    void Subscribe(F&& callback)
    {
        auto& handlers = m_Handlers[typeid(T)];
        handlers.push_back([callback = std::forward<F>(callback)](Event* e) {
            callback(static_cast<T*>(e));
        });
    }
    
    void Publish(Event* event)
    {
        auto it = m_Handlers.find(typeid(*event));
        if (it != m_Handlers.end())
        {
            for (auto& handler : it->second)
            {
                handler(event);
            }
        }
    }
    
private:
    std::unordered_map<std::type_index, std::vector<std::function<void(Event*)>>> m_Handlers;
};
```

#### 2. 立即模式 vs 延迟模式

```cpp
// 立即模式：事件立即处理
class ImmediateEventBus
{
public:
    template<typename T>
    void Publish(T event)
    {
        auto& handlers = m_Handlers[typeid(T)];
        for (auto& handler : handlers)
        {
            handler(&event);
        }
    }
};

// 延迟模式：事件在帧末尾处理（适合多线程）
class DeferredEventBus
{
public:
    template<typename T>
    void Publish(T event)
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        m_PendingEvents.push(std::make_unique<T>(std::move(event)));
    }
    
    void ProcessEvents()
    {
        while (!m_PendingEvents.empty())
        {
            auto event = std::move(m_PendingEvents.front());
            m_PendingEvents.pop();
            
            auto it = m_Handlers.find(typeid(*event));
            if (it != m_Handlers.end())
            {
                for (auto& handler : it->second)
                {
                    handler(event.get());
                }
            }
        }
    }
    
private:
    std::queue<std::unique_ptr<Event>> m_PendingEvents;
    std::mutex m_Mutex;
};
```

### 三、模块化设计

#### 1. 模块接口

```cpp
// 模块基类
class IModule
{
public:
    virtual ~IModule() = default;
    
    virtual void Initialize() = 0;
    virtual void Update(float deltaTime) = 0;
    virtual void Shutdown() = 0;
    
    virtual const char* GetName() const = 0;
    virtual int GetPriority() const { return 0; }
};

// 模块管理器
class ModuleManager
{
public:
    template<typename T, typename... Args>
    T& RegisterModule(Args&&... args)
    {
        auto module = std::make_unique<T>(std::forward<Args>(args)...);
        T* ptr = module.get();
        
        m_Modules.push_back(std::move(module));
        std::sort(m_Modules.begin(), m_Modules.end(),
            [](const auto& a, const auto& b) {
                return a->GetPriority() < b->GetPriority();
            });
        
        return *ptr;
    }
    
    void InitializeAll()
    {
        for (auto& module : m_Modules)
        {
            module->Initialize();
        }
    }
    
    void UpdateAll(float deltaTime)
    {
        for (auto& module : m_Modules)
        {
            module->Update(deltaTime);
        }
    }
    
    void ShutdownAll()
    {
        for (auto it = m_Modules.rbegin(); it != m_Modules.rend(); ++it)
        {
            (*it)->Shutdown();
        }
    }
    
private:
    std::vector<std::unique_ptr<IModule>> m_Modules;
};

// 具体模块
class RenderModule : public IModule
{
public:
    const char* GetName() const override { return "Render"; }
    int GetPriority() const override { return 100; }  // 后初始化
    
    void Initialize() override
    {
        m_Renderer = std::make_unique<Renderer>();
        m_Renderer->Initialize();
    }
    
    void Update(float deltaTime) override
    {
        m_Renderer->RenderFrame();
    }
    
    void Shutdown() override
    {
        m_Renderer->Shutdown();
    }
    
private:
    std::unique_ptr<Renderer> m_Renderer;
};
```

### 四、资源管理

#### 1. 资源生命周期

```
┌──────────────────────────────────────────────────┐
│            资源生命周期状态机                     │
└──────────────────────────────────────────────────┘

     ┌──────────┐
     │ Unloaded │ ◄──────────────────────┐
     └────┬─────┘                        │
          │ Load()                       │
          ▼                              │
     ┌──────────┐                        │
     │ Loading  │                        │
     └────┬─────┘                        │
          │ OnLoadComplete()             │
          ▼                              │ Unload()
     ┌──────────┐                        │
     │  Loaded  │ ◄─────┐                │
     └────┬─────┘       │                │
          │ Get()       │ Release()      │
          ▼             │                │
     ┌──────────┐       │                │
     │   InUse  │ ──────┘                │
     └────┬─────┘                        │
          │ ReferenceCount == 0          │
          └──────────────────────────────┘
```

#### 2. 资源管理器

```cpp
// 资源基类
class Resource
{
public:
    enum class State
    {
        Unloaded,
        Loading,
        Loaded,
        Failed
    };
    
    virtual ~Resource() = default;
    
    const std::string& GetPath() const { return m_Path; }
    State GetState() const { return m_State; }
    bool IsLoaded() const { return m_State == State::Loaded; }
    
    void AddRef() { ++m_RefCount; }
    void Release() { if (--m_RefCount == 0) OnZeroRefCount(); }
    
protected:
    friend class ResourceManager;
    
    virtual bool Load() = 0;
    virtual void Unload() = 0;
    
    void OnZeroRefCount()
    {
        if (m_AutoUnload)
        {
            Unload();
        }
    }
    
    std::string m_Path;
    State m_State = State::Unloaded;
    int m_RefCount = 0;
    bool m_AutoUnload = true;
};

// 资源管理器
class ResourceManager
{
public:
    template<typename T>
    std::shared_ptr<T> Load(const std::string& path)
    {
        // 检查缓存
        auto it = m_Resources.find(path);
        if (it != m_Resources.end())
        {
            return std::static_pointer_cast<T>(it->second);
        }
        
        // 创建资源
        auto resource = std::make_shared<T>();
        resource->m_Path = path;
        resource->Load();
        
        m_Resources[path] = resource;
        return resource;
    }
    
    void Unload(const std::string& path)
    {
        auto it = m_Resources.find(path);
        if (it != m_Resources.end())
        {
            it->second->Unload();
            m_Resources.erase(it);
        }
    }
    
    void UnloadAll()
    {
        for (auto& [path, resource] : m_Resources)
        {
            resource->Unload();
        }
        m_Resources.clear();
    }
    
private:
    std::unordered_map<std::string, std::shared_ptr<Resource>> m_Resources;
};
```

## 架构设计原则

### 1. 单一职责原则（SRP）

```cpp
// ❌ 违反 SRP：一个类做太多事情
class GameManager
{
public:
    void UpdateEntities();
    void RenderScene();
    void HandleInput();
    void PlayAudio();
    void LoadAssets();
};

// ✅ 遵循 SRP：职责分离
class EntityManager { void UpdateEntities(); };
class RenderSystem { void RenderScene(); };
class InputManager { void HandleInput(); };
class AudioManager { void PlayAudio(); };
class AssetManager { void LoadAssets(); };
```

### 2. 依赖倒置原则（DIP）

```cpp
// ✅ 遵循 DIP：依赖抽象
class IAudioDevice
{
public:
    virtual ~IAudioDevice() = default;
    virtual void PlaySound(SoundHandle sound) = 0;
};

class AudioManager
{
public:
    AudioManager(IAudioDevice* device) : m_Device(device) {}
    void PlaySound(SoundHandle sound) { m_Device->PlaySound(sound); }
    
private:
    IAudioDevice* m_Device;
};
```

## 相关技能

- **engine-project-context** - 读取项目模块结构
- **engine-cpp-foundations** - 使用内存管理和并发编程
- **engine-rendering** - 渲染系统集成
- **engine-testing** - 架构测试
