---
globs: ["*.cpp", "*.h", "*.hpp"]
---

# 引擎性能优化规则

> 所有性能关键代码必须遵循此规则

## 性能原则

### 1. 知道你的热点

```cpp
// ✅ 正确：先测量，再优化
void UpdateEntities(float dt)
{
    PROFILE_FUNCTION();  // 性能分析
    
    // ... 代码
    
    // 只有测量发现是瓶颈才优化
}

// ❌ 错误：过早优化
void UpdateEntities(float dt)
{
    // 在没有测量之前就进行"优化"
    // 可能反而降低可读性
}
```

### 2. 避免不必要的分配

```cpp
// ✅ 正确：重用内存
class EntityManager
{
public:
    void Update(float dt)
    {
        m_TempEntities.clear();  // 清空但保留容量
        for (auto& [id, entity] : m_Entities)
        {
            if (entity->IsActive())
            {
                m_TempEntities.push_back(entity.get());
            }
        }
        // 使用 m_TempEntities...
    }
    
private:
    std::vector<Entity*> m_TempEntities;  // 重用的临时容器
};

// ❌ 错误：每帧分配
void UpdateEntities(float dt)
{
    std::vector<Entity*> activeEntities;  // 每帧新分配
    // ... 填充
    // 使用后丢弃
}
```

### 3. 数据局部性

```cpp
// ✅ 正确：连续内存，缓存友好
struct TransformComponent
{
    Vector3 position;
    Quaternion rotation;
    Vector3 scale;
};

std::vector<TransformComponent> transforms;  // 连续内存

// ✅ 正确：顺序访问
for (auto& transform : transforms)  // 缓存友好
{
    transform.position += velocity;
}

// ❌ 错误：指针追踪，缓存不友好
std::vector<TransformComponent*> transforms;  // 分散内存

for (auto* transform : transforms)  // 每次访问可能缓存未命中
{
    transform->position += velocity;
}
```

### 4. 避免分支预测失败

```cpp
// ✅ 正确：减少分支
void UpdateEntities(float dt)
{
    // 分组处理
    for (auto& entity : m_ActiveEntities)
    {
        entity->Update(dt);  // 都是 active，无需检查
    }
}

// ❌ 错误：频繁分支
void UpdateEntities(float dt)
{
    for (auto& entity : m_AllEntities)
    {
        if (entity->IsActive())  // 每次都要检查
        {
            entity->Update(dt);
        }
    }
}
```

## 内存优化

### 1. 使用合适的容器

```cpp
// ✅ 正确：根据访问模式选择容器
// 频繁随机访问：vector
std::vector<Entity> entities;
entities[42];  // O(1)

// 频繁查找：unordered_map
std::unordered_map<EntityID, Entity*> entityMap;
entityMap.find(id);  // O(1) 平均

// 频繁插入删除：list
std::list<Task> taskQueue;  // O(1) 插入删除

// ❌ 错误：使用错误的容器
std::list<Entity> entities;  // 随机访问 O(n)！
entities[42];  // 错误：list 没有随机访问
```

### 2. 预分配内存

```cpp
// ✅ 正确：预分配
std::vector<Entity> entities;
entities.reserve(10000);  // 预分配，避免重新分配

for (int i = 0; i < 10000; ++i)
{
    entities.push_back(CreateEntity());  // 不会重新分配
}

// ❌ 错误：未预分配
std::vector<Entity> entities;

for (int i = 0; i < 10000; ++i)
{
    entities.push_back(CreateEntity());  // 多次重新分配和复制！
}
```

### 3. 使用对象池

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
            // 扩展池
            m_Objects.push_back(std::make_unique<T>());
            return m_Objects.back().get();
        }
        
        T* obj = m_FreeList.back();
        m_FreeList.pop_back();
        return obj;
    }
    
    void Release(T* obj)
    {
        m_FreeList.push_back(obj);
    }
    
private:
    std::vector<std::unique_ptr<T>> m_Objects;
    std::vector<T*> m_FreeList;
};

// 使用
ObjectPool<Bullet> bulletPool;
Bullet* bullet = bulletPool.Acquire();  // 重用对象
// ... 使用
bulletPool.Release(bullet);  // 不删除，放回池中

// ❌ 错误：频繁分配释放
Bullet* bullet = new Bullet();  // 每次分配
// ... 使用
delete bullet;  // 每次释放
```

### 4. 避免 String 操作

```cpp
// ✅ 正确：使用 StringView
void ProcessName(std::string_view name)
{
    // 不复制，直接查看
    if (name == "Player") { /* ... */ }
}

// ✅ 正确：预分配字符串
std::string buffer;
buffer.reserve(1024);  // 预分配
for (int i = 0; i < 100; ++i)
{
    buffer += std::to_string(i);  // 不会频繁重新分配
}

// ❌ 错误：频繁字符串操作
std::string result;
for (int i = 0; i < 100; ++i)
{
    result += std::to_string(i);  // 每次可能重新分配！
}
```

## 算法优化

### 1. 选择正确的算法

```cpp
// ✅ 正确：O(n log n) 排序
std::sort(entities.begin(), entities.end(), 
    [](const Entity& a, const Entity& b) {
        return a.id < b.id;
    });

// ✅ 正确：O(n) 查找（有序）
auto it = std::lower_bound(entities.begin(), entities.end(), target,
    [](const Entity& e, EntityID id) {
        return e.id < id;
    });

// ❌ 错误：O(n) 查找（无序）
auto it = std::find_if(entities.begin(), entities.end(),
    [&](const Entity& e) {
        return e.id == target;  // O(n)
    });
```

### 2. 避免不必要的计算

```cpp
// ✅ 正确：缓存结果
class Transform
{
public:
    const Matrix4& GetWorldMatrix() const
    {
        if (m_IsDirty)
        {
            m_WorldMatrix = CalculateWorldMatrix();
            m_IsDirty = false;
        }
        return m_WorldMatrix;
    }
    
    void SetPosition(const Vector3& pos)
    {
        m_Position = pos;
        m_IsDirty = true;  // 标记为脏
    }
    
private:
    Vector3 m_Position;
    mutable Matrix4 m_WorldMatrix;  // 缓存
    mutable bool m_IsDirty = true;
};

// ❌ 错误：每次都计算
Matrix4 GetWorldMatrix() const
{
    return CalculateWorldMatrix();  // 每次都计算
}
```

### 3. 并行化

```cpp
// ✅ 正确：并行处理
#include <execution>

std::for_each(std::execution::par, entities.begin(), entities.end(),
    [](Entity& entity) {
        entity.Update();  // 并行执行
    });

// ✅ 正确：任务系统
TaskScheduler scheduler(4);  // 4 个线程

std::vector<std::future<void>> futures;
for (auto& entity : entities)
{
    futures.push_back(scheduler.Submit([&entity]() {
        entity.Update();
    }));
}

for (auto& future : futures)
{
    future.wait();
}

// ❌ 错误：单线程处理大量数据
for (auto& entity : entities)  // 单线程
{
    entity.Update();
}
```

## 渲染优化

### 1. 减少 Draw Call

```cpp
// ✅ 正确：实例化渲染
void RenderInstanced(const Mesh& mesh, const std::vector<Matrix4>& transforms)
{
    glBindVertexArray(mesh.VAO);
    
    // 上传所有变换矩阵
    glBindBuffer(GL_ARRAY_BUFFER, m_InstanceBuffer);
    glBufferSubData(GL_ARRAY_BUFFER, 0, transforms.size() * sizeof(Matrix4), 
                    transforms.data());
    
    // 一次绘制所有实例
    glDrawElementsInstanced(GL_TRIANGLES, mesh.indexCount, 
                           GL_UNSIGNED_INT, 0, transforms.size());
}

// ❌ 错误：逐个绘制
for (const auto& transform : transforms)
{
    SetModelMatrix(transform);
    DrawMesh(mesh);  // 每次 Draw Call
}
```

### 2. 视锥裁剪

```cpp
// ✅ 正确：视锥裁剪
void RenderScene(const Camera& camera)
{
    Frustum frustum = camera.GetFrustum();
    
    for (auto& entity : m_Entities)
    {
        if (frustum.Intersects(entity.GetBounds()))
        {
            Render(entity);  // 只渲染可见的
        }
    }
}

// ❌ 错误：渲染所有
void RenderScene(const Camera& camera)
{
    for (auto& entity : m_Entities)
    {
        Render(entity);  // 渲染不可见的
    }
}
```

### 3. LOD（细节层次）

```cpp
// ✅ 正确：LOD 选择
void RenderEntity(const Entity& entity, const Camera& camera)
{
    float distance = (entity.GetPosition() - camera.GetPosition()).Length();
    
    const Mesh* mesh = nullptr;
    if (distance < 50.0f)
        mesh = &entity.GetLODMesh(0);  // 高细节
    else if (distance < 150.0f)
        mesh = &entity.GetLODMesh(1);  // 中细节
    else
        mesh = &entity.GetLODMesh(2);  // 低细节
    
    Render(*mesh);
}
```

## 性能检查清单

每次提交性能关键代码前检查：

- [ ] 是否测量过性能？
- [ ] 是否避免了不必要的分配？
- [ ] 是否考虑了数据局部性？
- [ ] 是否减少了分支？
- [ ] 是否选择了正确的容器？
- [ ] 是否预分配了内存？
- [ ] 是否使用了对象池？
- [ ] 是否避免了字符串操作？
- [ ] 是否选择了正确的算法？
- [ ] 是否缓存了计算结果？
- [ ] 是否考虑了并行化？
- [ ] 是否减少了 Draw Call？
- [ ] 是否实现了视锥裁剪？
- [ ] 是否实现了 LOD？
