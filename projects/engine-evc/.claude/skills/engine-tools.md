---
name: engine-tools
description: 引擎工具开发 - 编辑器扩展、资源管线、调试工具等引擎工具开发知识
globs:
  - "**/editor/**"
  - "**/tools/**"
  - "**/asset/**"
---

# Engine Tools

> **工具系统是引擎生产力的重要组成部分，此技能提供编辑器扩展和工具开发知识**

## 作用

提供游戏引擎工具开发知识，包括编辑器扩展、资源管线、调试工具、性能分析工具等。

## 触发时机

- 开发编辑器相关代码时
- 用户提及编辑器、工具、资源管线等关键词时
- 创建自定义工具时

## 核心内容

### 一、编辑器架构

#### 1. 编辑器架构图

```
┌────────────────────────────────────────────────────────┐
│                  编辑器系统架构                         │
└────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Editor Application                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Menu Bar    │  │  Tool Bar    │  │ Status Bar   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Scene Editor │  │ Asset Browser│  │ Inspector    │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ 3D Viewport  │  │ File Tree    │  │ Property Grid│
│ Hierarchy    │  │ Preview      │  │ Components   │
│ Gizmos       │  │ Import       │  │ References   │
└──────────────┘  └──────────────┘  └──────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Editor Modules                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │Undo/Redo     │  │  Selection   │  │  Clipboard   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Drag & Drop │  │  Settings    │  │  Console     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

#### 2. 编辑器核心系统

```cpp
// 编辑器应用
class EditorApplication
{
public:
    static EditorApplication& Get()
    {
        static EditorApplication instance;
        return instance;
    }
    
    void Initialize()
    {
        // 创建主窗口
        m_MainWindow = CreateMainWindow();
        
        // 初始化模块
        m_SceneEditor = std::make_unique<SceneEditor>();
        m_AssetBrowser = std::make_unique<AssetBrowser>();
        m_Inspector = std::make_unique<Inspector>();
        
        // 初始化子系统
        m_UndoSystem = std::make_unique<UndoSystem>();
        m_SelectionSystem = std::make_unique<SelectionSystem>();
        m_Clipboard = std::make_unique<Clipboard>();
        
        // 注册菜单
        RegisterMenus();
    }
    
    void Run()
    {
        while (!m_ShouldClose)
        {
            // 处理输入
            ProcessInput();
            
            // 更新编辑器
            Update(m_DeltaTime);
            
            // 渲染
            Render();
            
            // 等待下一帧
            m_DeltaTime = CalculateDeltaTime();
        }
    }
    
    // 获取子系统
    UndoSystem& GetUndoSystem() { return *m_UndoSystem; }
    SelectionSystem& GetSelectionSystem() { return *m_SelectionSystem; }
    
private:
    std::unique_ptr<Window> m_MainWindow;
    std::unique_ptr<SceneEditor> m_SceneEditor;
    std::unique_ptr<AssetBrowser> m_AssetBrowser;
    std::unique_ptr<Inspector> m_Inspector;
    
    std::unique_ptr<UndoSystem> m_UndoSystem;
    std::unique_ptr<SelectionSystem> m_SelectionSystem;
    std::unique_ptr<Clipboard> m_Clipboard;
    
    bool m_ShouldClose = false;
    float m_DeltaTime = 0.0f;
};
```

### 二、Undo/Redo 系统

#### 1. 命令模式实现

```cpp
// 编辑器命令基类
class IEditorCommand
{
public:
    virtual ~IEditorCommand() = default;
    
    virtual void Execute() = 0;
    virtual void Undo() = 0;
    virtual void Redo() { Execute(); }
    
    virtual std::string GetDescription() const = 0;
    virtual bool CanMerge(const IEditorCommand* other) const { return false; }
    virtual void Merge(const IEditorCommand* other) {}
};

// Undo/Redo 系统
class UndoSystem
{
public:
    void ExecuteCommand(std::unique_ptr<IEditorCommand> command)
    {
        command->Execute();
        
        // 尝试与上一个命令合并
        if (!m_CommandStack.empty() && m_CommandStack.back()->CanMerge(command.get()))
        {
            m_CommandStack.back()->Merge(command.get());
        }
        else
        {
            m_CommandStack.push_back(std::move(command));
        }
        
        // 清除 Redo 栈
        m_RedoStack.clear();
        
        // 限制历史记录数量
        if (m_CommandStack.size() > m_MaxHistorySize)
        {
            m_CommandStack.erase(m_CommandStack.begin());
        }
    }
    
    bool CanUndo() const { return !m_CommandStack.empty(); }
    bool CanRedo() const { return !m_RedoStack.empty(); }
    
    void Undo()
    {
        if (!CanUndo()) return;
        
        auto command = std::move(m_CommandStack.back());
        m_CommandStack.pop_back();
        
        command->Undo();
        m_RedoStack.push_back(std::move(command));
    }
    
    void Redo()
    {
        if (!CanRedo()) return;
        
        auto command = std::move(m_RedoStack.back());
        m_RedoStack.pop_back();
        
        command->Redo();
        m_CommandStack.push_back(std::move(command));
    }
    
private:
    std::vector<std::unique_ptr<IEditorCommand>> m_CommandStack;
    std::vector<std::unique_ptr<IEditorCommand>> m_RedoStack;
    size_t m_MaxHistorySize = 100;
};

// 具体命令：移动实体
class MoveEntityCommand : public IEditorCommand
{
public:
    MoveEntityCommand(EntityID entity, const Vector3& oldPosition, const Vector3& newPosition)
        : m_Entity(entity)
        , m_OldPosition(oldPosition)
        , m_NewPosition(newPosition)
    {}
    
    void Execute() override
    {
        auto& transform = m_World->GetComponent<TransformComponent>(m_Entity);
        transform.position = m_NewPosition;
    }
    
    void Undo() override
    {
        auto& transform = m_World->GetComponent<TransformComponent>(m_Entity);
        transform.position = m_OldPosition;
    }
    
    std::string GetDescription() const override
    {
        return "Move Entity";
    }
    
    bool CanMerge(const IEditorCommand* other) const override
    {
        auto* moveCmd = dynamic_cast<const MoveEntityCommand*>(other);
        return moveCmd && moveCmd->m_Entity == m_Entity;
    }
    
    void Merge(const IEditorCommand* other) override
    {
        auto* moveCmd = static_cast<const MoveEntityCommand*>(other);
        m_NewPosition = moveCmd->m_NewPosition;
    }
    
private:
    EntityID m_Entity;
    Vector3 m_OldPosition;
    Vector3 m_NewPosition;
    World* m_World;
};
```

### 三、选择系统

```cpp
// 选择系统
class SelectionSystem
{
public:
    // 选择对象
    void Select(ObjectID object, bool addToSelection = false)
    {
        if (!addToSelection)
        {
            ClearSelection();
        }
        
        m_SelectedObjects.insert(object);
        OnSelectionChanged.Broadcast(m_SelectedObjects);
    }
    
    // 取消选择
    void Deselect(ObjectID object)
    {
        m_SelectedObjects.erase(object);
        OnSelectionChanged.Broadcast(m_SelectedObjects);
    }
    
    // 清除选择
    void ClearSelection()
    {
        m_SelectedObjects.clear();
        OnSelectionChanged.Broadcast(m_SelectedObjects);
    }
    
    // 查询
    bool IsSelected(ObjectID object) const
    {
        return m_SelectedObjects.count(object) > 0;
    }
    
    const std::set<ObjectID>& GetSelectedObjects() const
    {
        return m_SelectedObjects;
    }
    
    ObjectID GetPrimarySelection() const
    {
        return m_SelectedObjects.empty() ? InvalidObjectID : *m_SelectedObjects.begin();
    }
    
    // 事件
    Event<const std::set<ObjectID>&> OnSelectionChanged;
    
private:
    std::set<ObjectID> m_SelectedObjects;
};
```

### 四、Inspector（属性检查器）

```cpp
// 属性检查器
class Inspector
{
public:
    void Inspect(ObjectID object)
    {
        m_CurrentObject = object;
        RefreshProperties();
    }
    
    void RefreshProperties()
    {
        m_Properties.clear();
        
        if (!m_CurrentObject.IsValid()) return;
        
        // 反射获取所有属性
        auto* typeInfo = m_CurrentObject.GetTypeInfo();
        for (auto& property : typeInfo->GetProperties())
        {
            m_Properties.push_back(PropertyInfo{
                .name = property.GetName(),
                .type = property.GetType(),
                .value = property.GetValue(m_CurrentObject),
                .setter = [this, property](const auto& value) {
                    property.SetValue(m_CurrentObject, value);
                }
            });
        }
    }
    
    void Render()
    {
        ImGui::Begin("Inspector");
        
        for (auto& prop : m_Properties)
        {
            RenderProperty(prop);
        }
        
        ImGui::End();
    }
    
private:
    void RenderProperty(PropertyInfo& prop)
    {
        ImGui::PushID(prop.name.c_str());
        
        if (prop.type == typeid(float))
        {
            float value = std::any_cast<float>(prop.value);
            if (ImGui::DragFloat(prop.name.c_str(), &value))
            {
                prop.setter(value);
            }
        }
        else if (prop.type == typeid(Vector3))
        {
            Vector3 value = std::any_cast<Vector3>(prop.value);
            if (ImGui::DragFloat3(prop.name.c_str(), &value.x))
            {
                prop.setter(value);
            }
        }
        else if (prop.type == typeid(std::string))
        {
            std::string value = std::any_cast<std::string>(prop.value);
            char buffer[256];
            strcpy(buffer, value.c_str());
            if (ImGui::InputText(prop.name.c_str(), buffer, sizeof(buffer)))
            {
                prop.setter(std::string(buffer));
            }
        }
        // ... 其他类型
        
        ImGui::PopID();
    }
    
    ObjectID m_CurrentObject;
    std::vector<PropertyInfo> m_Properties;
};
```

### 五、资源管线

#### 1. 资源导入流程

```
┌────────────────────────────────────────────────────────┐
│                  资源导入管线                          │
└────────────────────────────────────────────────────────┘

原始资源
┌──────────────┐
│ model.fbx    │
│ texture.png  │
│ audio.wav    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 导入器检测   │
│ (by ext)     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 资源导入     │
│ - 解析格式   │
│ - 提取数据   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 后处理       │
│ - 优化       │
│ - 压缩       │
│ - 生成 Mips  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 序列化       │
│ - 写入引擎   │
│   格式       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 元数据       │
│ - GUID       │
│ - 依赖关系   │
│ - 导入设置   │
└──────────────┘
```

#### 2. 资源导入器

```cpp
// 资源导入器基类
class IAssetImporter
{
public:
    virtual ~IAssetImporter() = default;
    
    virtual bool CanImport(const std::string& extension) const = 0;
    virtual std::vector<std::string> GetSupportedExtensions() const = 0;
    
    virtual bool Import(const std::string& sourcePath, const std::string& destPath) = 0;
    
    virtual std::string GetName() const = 0;
};

// 模型导入器
class FBXImporter : public IAssetImporter
{
public:
    bool CanImport(const std::string& extension) const override
    {
        return extension == ".fbx" || extension == ".obj";
    }
    
    std::vector<std::string> GetSupportedExtensions() const override
    {
        return {".fbx", ".obj"};
    }
    
    bool Import(const std::string& sourcePath, const std::string& destPath) override
    {
        // 1. 加载 FBX
        FbxManager* fbxManager = FbxManager::Create();
        FbxImporter* importer = FbxImporter::Create(fbxManager, "");
        
        if (!importer->Initialize(sourcePath.c_str()))
        {
            LOG_ERROR("Failed to import FBX: {}", sourcePath);
            return false;
        }
        
        // 2. 解析场景
        FbxScene* scene = FbxScene::Create(fbxManager, "");
        importer->Import(scene);
        
        // 3. 提取数据
        ModelData modelData;
        ExtractMeshes(scene, modelData);
        ExtractMaterials(scene, modelData);
        ExtractAnimations(scene, modelData);
        
        // 4. 优化
        OptimizeMeshes(modelData);
        
        // 5. 序列化
        SaveModel(destPath, modelData);
        
        // 6. 清理
        importer->Destroy();
        fbxManager->Destroy();
        
        return true;
    }
    
    std::string GetName() const override { return "FBX Importer"; }
    
private:
    void ExtractMeshes(FbxScene* scene, ModelData& data);
    void ExtractMaterials(FbxScene* scene, ModelData& data);
    void ExtractAnimations(FbxScene* scene, ModelData& data);
    void OptimizeMeshes(ModelData& data);
};

// 资源导入管理器
class AssetImportManager
{
public:
    void RegisterImporter(std::unique_ptr<IAssetImporter> importer)
    {
        m_Importers.push_back(std::move(importer));
    }
    
    bool ImportAsset(const std::string& sourcePath, const std::string& destPath)
    {
        std::string ext = GetExtension(sourcePath);
        
        for (auto& importer : m_Importers)
        {
            if (importer->CanImport(ext))
            {
                return importer->Import(sourcePath, destPath);
            }
        }
        
        LOG_ERROR("No importer found for extension: {}", ext);
        return false;
    }
    
private:
    std::vector<std::unique_ptr<IAssetImporter>> m_Importers;
};
```

### 六、调试工具

#### 1. 性能分析工具

```cpp
// 性能分析器
class Profiler
{
public:
    struct FrameData
    {
        float totalTime;
        std::unordered_map<std::string, float> scopes;
    };
    
    static Profiler& Get();
    
    void BeginFrame()
    {
        m_CurrentFrame = FrameData{};
        m_FrameStartTime = std::chrono::high_resolution_clock::now();
    }
    
    void EndFrame()
    {
        auto endTime = std::chrono::high_resolution_clock::now();
        m_CurrentFrame.totalTime = std::chrono::duration<float>(endTime - m_FrameStartTime).count();
        
        m_FrameHistory.push_back(m_CurrentFrame);
        if (m_FrameHistory.size() > m_MaxHistorySize)
        {
            m_FrameHistory.pop_front();
        }
    }
    
    void BeginScope(const std::string& name)
    {
        m_ScopeStack.push({name, std::chrono::high_resolution_clock::now()});
    }
    
    void EndScope()
    {
        auto [name, startTime] = m_ScopeStack.top();
        m_ScopeStack.pop();
        
        auto endTime = std::chrono::high_resolution_clock::now();
        float duration = std::chrono::duration<float>(endTime - startTime).count();
        
        m_CurrentFrame.scopes[name] += duration;
    }
    
    const std::deque<FrameData>& GetFrameHistory() const
    {
        return m_FrameHistory;
    }
    
private:
    FrameData m_CurrentFrame;
    std::chrono::time_point<std::chrono::high_resolution_clock> m_FrameStartTime;
    std::stack<std::pair<std::string, std::chrono::time_point<std::chrono::high_resolution_clock>>> m_ScopeStack;
    std::deque<FrameData> m_FrameHistory;
    size_t m_MaxHistorySize = 300;
};

// 作用域计时器
class ScopedProfiler
{
public:
    ScopedProfiler(const std::string& name)
        : m_Name(name)
    {
        Profiler::Get().BeginScope(name);
    }
    
    ~ScopedProfiler()
    {
        Profiler::Get().EndScope();
    }
    
private:
    std::string m_Name;
};

// 使用宏简化
#define PROFILE_SCOPE(name) ScopedProfiler _profiler_##__LINE__(name)
#define PROFILE_FUNCTION() PROFILE_SCOPE(__FUNCTION__)
```

#### 2. 调试可视化

```cpp
// 调试绘制器
class DebugRenderer
{
public:
    static void DrawLine(const Vector3& start, const Vector3& end, const Color& color, float duration = 0.0f);
    static void DrawBox(const Vector3& center, const Vector3& extent, const Color& color, float duration = 0.0f);
    static void DrawSphere(const Vector3& center, float radius, const Color& color, float duration = 0.0f);
    static void DrawArrow(const Vector3& start, const Vector3& end, const Color& color, float duration = 0.0f);
    static void DrawText(const Vector3& position, const std::string& text, const Color& color);
    
    // 使用示例
    static void DebugPhysicsColliders()
    {
        PROFILE_FUNCTION();
        
        for (auto [entity, collider, transform] : 
             World::Get().View<ColliderComponent, TransformComponent>())
        {
            if (collider.type == ColliderType::Box)
            {
                DrawBox(transform.position, collider.size, Color::Green);
            }
            else if (collider.type == ColliderType::Sphere)
            {
                DrawSphere(transform.position, collider.radius, Color::Blue);
            }
        }
    }
};
```

## 工具开发最佳实践

### 1. 响应式设计

```cpp
// ✅ 推荐：编辑器操作应该快速响应
class ResponsiveEditor
{
public:
    void OnObjectMoved(EntityID entity, const Vector3& newPosition)
    {
        // 立即更新视觉
        UpdateVisualImmediately(entity, newPosition);
        
        // 延迟保存
        m_PendingSaves.push_back({entity, newPosition});
    }
    
    void OnIdle()
    {
        // 空闲时保存
        if (!m_PendingSaves.empty())
        {
            SavePendingChanges();
        }
    }
};
```

### 2. 可扩展性

```cpp
// ✅ 推荐：使用插件系统
class IEditorPlugin
{
public:
    virtual void Initialize() = 0;
    virtual void Shutdown() = 0;
    virtual void OnGUI() = 0;
};

class EditorPluginManager
{
public:
    void RegisterPlugin(std::unique_ptr<IEditorPlugin> plugin)
    {
        plugin->Initialize();
        m_Plugins.push_back(std::move(plugin));
    }
};
```

## 相关技能

- **engine-project-context** - 读取编辑器模块配置
- **engine-architecture** - 模块化设计
- **engine-testing** - 编辑器测试
