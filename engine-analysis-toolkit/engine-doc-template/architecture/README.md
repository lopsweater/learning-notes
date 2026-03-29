# 引擎架构概览

本文档提供引擎的高层次架构概览，帮助您理解引擎的整体设计和核心系统。

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        应用层 (Application)                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Game   │  │ Editor  │  │ Tools   │  │  Test   │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       引擎核心 (Engine Core)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 渲染系统  │  │ 脚本系统  │  │ 物理系统  │  │ 音频系统  │    │
│  │ Renderer │  │ Scripting│  │ Physics  │  │  Audio   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ UI 系统  │  │ 动画系统  │  │ 输入系统  │  │ 场景管理  │    │
│  │   UI     │  │Animation │  │  Input   │  │  Scene   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     基础设施 (Infrastructure)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 资源管理  │  │ 内存管理  │  │ 线程调度  │  │ 文件系统  │    │
│  │  Asset   │  │  Memory  │  │ Threading│  │   File   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      平台抽象层 (Platform)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Windows  │  │  Linux   │  │  macOS   │  │  Mobile  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 核心子系统

### 1. 渲染系统 (Rendering System)

**职责**:
- 管理 GPU 资源（纹理、缓冲区、着色器）
- 执行渲染管线
- 处理光照和阴影
- 后处理效果

**关键组件**:
- `Renderer` - 主渲染器
- `RenderPipeline` - 渲染管线
- `Material` - 材质系统
- `Light` - 光源系统

**详细文档**: [渲染系统模块](../modules/rendering/README.md)

### 2. 资源管理系统 (Asset Management)

**职责**:
- 资源的导入与转换
- 异步加载与卸载
- 资源缓存与热重载
- 依赖关系管理

**关键组件**:
- `AssetManager` - 资源管理器
- `AssetLoader` - 加载器
- `AssetCache` - 缓存系统

**详细文档**: [资源管理模块](../modules/asset-management/README.md)

### 3. ECS 架构 (Entity-Component-System)

**职责**:
- 游戏对象的组织与管理
- 组件化设计
- 系统的调度与执行

**核心概念**:
- **Entity (实体)** - 唯一标识符，代表游戏对象
- **Component (组件)** - 纯数据容器
- **System (系统)** - 行为逻辑，处理特定组件

**详细文档**: [ECS 架构](./concepts/ecs.md)

### 4. 脚本系统 (Scripting System)

**职责**:
- 提供脚本语言支持（Lua/C#）
- 绑定引擎 API
- 热重载支持

**关键组件**:
- `ScriptEngine` - 脚本引擎
- `ScriptInstance` - 脚本实例
- `ScriptBindings` - API 绑定

**详细文档**: [脚本系统模块](../modules/scripting/README.md)

### 5. 物理系统 (Physics System)

**职责**:
- 碰撞检测
- 物理模拟
- 射线检测

**关键组件**:
- `PhysicsWorld` - 物理世界
- `RigidBody` - 刚体
- `Collider` - 碰撞体

**详细文档**: [物理系统模块](../modules/physics/README.md)

### 6. 场景管理 (Scene Management)

**职责**:
- 场景图管理
- 空间划分
- 视锥剔除

**关键组件**:
- `Scene` - 场景
- `SceneNode` - 场景节点
- `Octree` - 八叉树

**详细文档**: [场景管理模块](../modules/scene/README.md)

## 设计原则

### 1. 数据驱动设计

引擎采用数据驱动架构，将数据与逻辑分离：

```
数据 (Components) → 系统 (Systems) → 行为
```

**优势**:
- 易于序列化和网络同步
- 支持高效的数据布局
- 便于缓存优化

### 2. 模块化设计

每个子系统都是独立的模块：

- 清晰的接口定义
- 松耦合设计
- 可插拔架构

**优势**:
- 易于测试
- 支持自定义扩展
- 减少编译依赖

### 3. 性能优先

- 数据导向设计 (DOD)
- SIMD 优化
- 多线程并行

### 4. 跨平台支持

平台抽象层确保代码可移植：

```cpp
// 平台无关代码
FileSystem::ReadFile("path/to/file.txt");

// 平台相关实现
#if PLATFORM_WINDOWS
    // Windows 实现
#elif PLATFORM_LINUX
    // Linux 实现
#endif
```

## 初始化流程

```
main()
  ↓
Platform::Initialize()
  ↓
Engine::Create()
  ↓
├─ Memory::Initialize()
├─ FileSystem::Initialize()
├─ Threading::Initialize()
├─ AssetManager::Initialize()
├─ Renderer::Initialize()
├─ Physics::Initialize()
├─ Audio::Initialize()
├─ Input::Initialize()
└─ ScriptEngine::Initialize()
  ↓
Application::Run()
  ↓
Engine::Shutdown()
```

## 主循环

```cpp
while (engine.IsRunning()) {
    // 1. 输入处理
    Input::Update();
    
    // 2. 脚本更新
    ScriptEngine::Update(deltaTime);
    
    // 3. 物理模拟
    Physics::Update(deltaTime);
    
    // 4. 动画更新
    Animation::Update(deltaTime);
    
    // 5. 场景更新
    Scene::Update(deltaTime);
    
    // 6. 渲染
    Renderer::Render(scene, camera);
    
    // 7. 音频更新
    Audio::Update(deltaTime);
    
    // 8. 资源加载（异步）
    AssetManager::ProcessLoadingQueue();
}
```

## 线程模型

```
Main Thread
├─ 主循环
├─ 脚本执行
└─ 用户输入

Render Thread
├─ 渲染命令提交
└─ GPU 同步

Worker Threads
├─ 资源加载
├─ 物理模拟
└─ 异步任务
```

## 内存管理

### 内存分配器

| 分配器 | 用途 | 特点 |
|--------|------|------|
| Linear Allocator | 帧内存 | 快速，每帧重置 |
| Pool Allocator | 固定大小对象 | 无碎片 |
| Stack Allocator | 临时内存 | 快速分配/释放 |
| General Allocator | 通用内存 | 灵活 |

### 内存预算

```cpp
struct MemoryBudget {
    size_t rendererBudget = 512 * 1024 * 1024;  // 512 MB
    size_t physicsBudget = 64 * 1024 * 1024;    // 64 MB
    size_t audioBudget = 32 * 1024 * 1024;      // 32 MB
    size_t assetsBudget = 1024 * 1024 * 1024;   // 1 GB
};
```

## 扩展机制

### 插件系统

引擎支持通过插件扩展功能：

```cpp
class IPlugin {
public:
    virtual void Initialize() = 0;
    virtual void Shutdown() = 0;
    virtual void Update(float deltaTime) = 0;
};

// 注册插件
Engine::RegisterPlugin(std::make_unique<MyPlugin>());
```

### 自定义渲染管线

```cpp
class CustomRenderPipeline : public IRenderPipeline {
public:
    void Render(Scene* scene, Camera* camera) override {
        // 自定义渲染逻辑
    }
};

Renderer::SetPipeline(std::make_unique<CustomRenderPipeline>());
```

## 调试与性能分析

### 内置分析器

```cpp
PROFILE_SCOPE("Update");

{
    PROFILE_SCOPE("Physics");
    Physics::Update(deltaTime);
}

{
    PROFILE_SCOPE("Scripts");
    ScriptEngine::Update(deltaTime);
}
```

### 日志系统

```cpp
LOG_INFO("Message: {}", value);
LOG_WARNING("Warning: {}", warning);
LOG_ERROR("Error: {}", error);
LOG_DEBUG("Debug info: {}", debug);
```

## 相关文档

- [核心概念](./concepts/README.md)
- [模块设计](../modules/README.md)
- [性能优化指南](../best-practices/performance.md)
- [调试指南](../troubleshooting/debugging.md)

---

[← 返回首页](../README.md) | [下一章: 核心概念 →](./concepts/README.md)
