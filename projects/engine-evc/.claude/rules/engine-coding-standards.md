---
globs: ["*.cpp", "*.h", "*.hpp"]
---

# 引擎编码规范

> 所有 C++ 代码必须遵循此规范

## 命名约定

### 类型命名（PascalCase）

```cpp
// ✅ 正确
class EntityManager {};
struct TransformComponent {};
enum class RenderMode {};
using EntityID = uint64_t;

// ❌ 错误
class entity_manager {};
struct transformComponent {};
enum render_mode {};
```

### 变量命名（camelCase）

```cpp
// ✅ 正确
int entityCount = 0;
float deltaTime = 0.016f;
Vector3 playerPosition;

// ❌ 错误
int EntityCount = 0;
float delta_time = 0.016f;
Vector3 PlayerPosition;
```

### 常量命名（UPPER_SNAKE_CASE）

```cpp
// ✅ 正确
constexpr int MAX_ENTITIES = 10000;
constexpr float PI = 3.14159f;
const std::string DEFAULT_NAME = "Unknown";

// ❌ 错误
constexpr int maxEntities = 10000;
constexpr float Pi = 3.14159f;
```

### 私有成员变量（m_ 前缀）

```cpp
// ✅ 正确
class Entity
{
private:
    EntityID m_ID;
    std::string m_Name;
    bool m_IsActive = true;
};

// ❌ 错误
class Entity
{
private:
    EntityID id_;
    std::string _name;
    bool isActive;
};
```

### 函数命名（PascalCase）

```cpp
// ✅ 正确
void UpdateEntity(float deltaTime);
Entity* FindEntityByID(EntityID id);
bool IsEntityActive(EntityID id);

// ❌ 错误
void update_entity(float deltaTime);
Entity* find_entity_by_id(EntityID id);
bool isEntityActive(EntityID id);
```

### 接口命名（I 前缀）

```cpp
// ✅ 正确
class IRenderer
{
public:
    virtual ~IRenderer() = default;
    virtual void Initialize() = 0;
    virtual void Render() = 0;
};

class IAudioDevice { /* ... */ };
class IInputHandler { /* ... */ };

// ❌ 错误
class Renderer { /* ... */ };  // 抽象基类
class AudioDeviceInterface { /* ... */ };
```

## 文件组织

### 头文件结构

```cpp
#pragma once

// 1. 标准库
#include <vector>
#include <memory>
#include <string>

// 2. 第三方库
#include <glm/glm.hpp>

// 3. 引擎内部
#include "Core/Types.h"
#include "Core/Memory.h"

// 4. 前向声明
namespace Engine { class World; }

// 5. 命名空间
namespace Engine
{

/**
 * @brief 实体管理器
 * 
 * 负责创建、销毁和管理所有实体
 */
class EntityManager
{
public:
    // 构造/析构
    EntityManager();
    ~EntityManager();
    
    // 禁止拷贝
    EntityManager(const EntityManager&) = delete;
    EntityManager& operator=(const EntityManager&) = delete;
    
    // 允许移动
    EntityManager(EntityManager&&) noexcept;
    EntityManager& operator=(EntityManager&&) noexcept;
    
    // 公共方法
    Entity* CreateEntity();
    void DestroyEntity(EntityID id);
    Entity* FindEntity(EntityID id) const;
    
private:
    // 私有方法
    void OnEntityDestroyed(EntityID id);
    
    // 私有成员
    std::unordered_map<EntityID, std::unique_ptr<Entity>> m_Entities;
    EntityID m_NextID = 1;
};

} // namespace Engine
```

### 源文件结构

```cpp
// 1. 对应头文件
#include "EntityManager.h"

// 2. 标准库
#include <algorithm>

// 3. 第三方库
// ...

// 4. 引擎内部
#include "Entity.h"
#include "World.h"

namespace Engine
{

// 构造函数
EntityManager::EntityManager()
{
    LOG_INFO("EntityManager initialized");
}

// 析构函数
EntityManager::~EntityManager()
{
    m_Entities.clear();
    LOG_INFO("EntityManager destroyed");
}

// 方法实现
Entity* EntityManager::CreateEntity()
{
    EntityID id = m_NextID++;
    auto entity = std::make_unique<Entity>(id);
    auto* ptr = entity.get();
    m_Entities[id] = std::move(entity);
    return ptr;
}

// ... 其他方法实现

} // namespace Engine
```

## 代码风格

### 花括号风格（Allman）

```cpp
// ✅ 正确
if (condition)
{
    DoSomething();
}
else
{
    DoOther();
}

for (int i = 0; i < count; ++i)
{
    Process(i);
}

// ❌ 错误
if (condition) {
    DoSomething();
} else {
    DoOther();
}
```

### 缩进（4空格）

```cpp
// ✅ 正确
namespace Engine
{
    class Entity
    {
    public:
        void Update(float deltaTime)
        {
            if (m_IsActive)
            {
                m_Position += m_Velocity * deltaTime;
            }
        }
    };
}

// ❌ 错误（2空格或Tab）
namespace Engine {
  class Entity {
    void Update(float deltaTime) {
      if (m_IsActive) {
        // ...
```

### 空格使用

```cpp
// ✅ 正确
int x = 5;
float y = 3.14f;
Vector3 v(1.0f, 2.0f, 3.0f);

if (x > 0)
for (int i = 0; i < 10; ++i)
while (true)

auto result = CalculateValue();
auto ptr = std::make_unique<Entity>();

// ❌ 错误
int x=5;
float y = 3.14 f;
if(x>0)
auto result=CalculateValue();
```

## 注释规范

### 文档注释（Doxygen）

```cpp
/**
 * @brief 创建新实体
 * 
 * 在世界中创建一个新实体，并返回其指针。
 * 实体初始状态下没有任何组件。
 * 
 * @param name 实体名称（可选）
 * @return Entity* 创建的实体指针，失败返回 nullptr
 * 
 * @note 实体 ID 自动分配，从 1 开始
 * @see DestroyEntity, FindEntity
 * 
 * @example
 * @code
 * auto* entity = manager.CreateEntity("Player");
 * entity->AddComponent<TransformComponent>();
 * @endcode
 */
Entity* CreateEntity(const std::string& name = "");

/**
 * @brief 更新实体状态
 * 
 * @param deltaTime 帧时间（秒）
 * @throws std::invalid_argument 如果 deltaTime <= 0
 */
void Update(float deltaTime);
```

### 行内注释

```cpp
// ✅ 正确：解释"为什么"
// 使用平方根近似，因为精度要求不高
float distance = std::sqrt(dx * dx + dy * dy);

// 避免 GC 压力，预分配内存
entities.reserve(expectedCount);

// ❌ 错误：解释"是什么"（代码已经说明了）
// 设置 x 为 5
int x = 5;

// 循环遍历实体
for (auto& entity : entities)
```

### TODO 注释

```cpp
// TODO(鼓鼓): 添加多线程支持
// FIXME: 这里有内存泄漏
// HACK: 临时解决方案，等待重构
// NOTE: 这里的顺序很重要，不要改变
// OPTIMIZE: 可以优化为 O(n log n)
```

## 最佳实践

### 1. 使用 RAII

```cpp
// ✅ 正确
{
    auto texture = LoadTexture("hero.png");  // 引用计数 +1
    Render(texture);
}  // 引用计数 -1，自动释放

// ❌ 错误
Texture* texture = LoadTextureRaw("hero.png");
Render(texture);
delete texture;  // 容易忘记
```

### 2. 避免裸指针

```cpp
// ✅ 正确
std::unique_ptr<Entity> entity = std::make_unique<Entity>();
std::shared_ptr<Texture> texture = LoadTexture("hero.png");
Entity* rawPtr = entity.get();  // 仅在必要时使用

// ❌ 错误
Entity* entity = new Entity();  // 谁负责删除？
Texture* texture = new Texture();  // 内存泄漏风险
```

### 3. 使用 const

```cpp
// ✅ 正确
class Entity
{
public:
    const std::string& GetName() const { return m_Name; }
    bool IsActive() const { return m_IsActive; }
    
    void SetName(const std::string& name) { m_Name = name; }
    
private:
    std::string m_Name;
    bool m_IsActive = false;
};

// const 参数
void ProcessEntity(const Entity& entity);
void RenderTexture(const Texture* texture);

// const 局部变量
const int kMaxEntities = 10000;
const auto& entities = world.GetEntities();
```

### 4. 使用 constexpr

```cpp
// ✅ 正确
constexpr int MAX_ENTITIES = 10000;
constexpr float PI = 3.14159265359f;
constexpr int SQUARE(int x) { return x * x; }

// 编译期计算
constexpr int bufferSize = SQUARE(1024);  // 编译期求值
static_assert(bufferSize == 1048576, "Buffer size mismatch");
```

### 5. 避免魔法数字

```cpp
// ✅ 正确
constexpr int MAX_ENTITY_COUNT = 10000;
constexpr float DEFAULT_GRAVITY = -9.81f;
constexpr int INVALID_ENTITY_ID = 0;

if (entityCount > MAX_ENTITY_COUNT) { /* ... */ }

// ❌ 错误
if (entityCount > 10000) { /* ... */ }
velocity.y += -9.81f * deltaTime;
```

## 禁止事项

### 1. 禁止使用 `using namespace std`

```cpp
// ❌ 禁止
using namespace std;
string name;
vector<int> ids;

// ✅ 正确
std::string name;
std::vector<int> ids;
```

### 2. 禁止全局变量

```cpp
// ❌ 禁止
int g_EntityCount = 0;
World* g_World = nullptr;

// ✅ 正确：使用单例或依赖注入
class Engine
{
public:
    static Engine& Get() { static Engine instance; return instance; }
    World& GetWorld() { return m_World; }
    
private:
    World m_World;
};
```

### 3. 禁止 C 风格转换

```cpp
// ❌ 禁止
float f = 3.14f;
int i = (int)f;
void* ptr = (void*)&obj;

// ✅ 正确
float f = 3.14f;
int i = static_cast<int>(f);
void* ptr = static_cast<void*>(&obj);
```

### 4. 禁止 `goto`

```cpp
// ❌ 禁止
if (error)
    goto cleanup;
// ...
cleanup:
    // ...

// ✅ 正确：使用 RAII 或提前返回
if (error)
    return false;
// ...
return true;
```

### 5. 禁止未初始化变量

```cpp
// ❌ 禁止
int x;
float y;
Entity* entity;

// ✅ 正确
int x = 0;
float y = 0.0f;
Entity* entity = nullptr;
```

## 检查清单

每次提交代码前检查：

- [ ] 所有类型使用 PascalCase
- [ ] 所有变量使用 camelCase（私有成员 m_ 前缀）
- [ ] 所有常量使用 UPPER_SNAKE_CASE
- [ ] 所有接口使用 I 前缀
- [ ] 文件包含顺序正确
- [ ] 使用 4 空格缩进
- [ ] 使用 Allman 花括号风格
- [ ] 所有公共 API 有文档注释
- [ ] 没有 `using namespace std`
- [ ] 没有全局变量
- [ ] 没有裸指针（除非必要）
- [ ] 没有魔法数字
- [ ] 没有未初始化变量
- [ ] 没有内存泄漏
