---
name: module-analysis
description: 游戏引擎模块分析工具。对游戏引擎源码进行深度分析，包括架构分析、模块剖析、版本历史追溯和关键概念文档化。适用于理解大型游戏引擎（如 Unreal Engine、Unity、Godot）架构设计的场景。
allowed_tools: ["Read", "Glob", "Grep", "Bash", "Write"]
origin: engine-analysis-toolkit
---

# 游戏引擎模块分析

对游戏引擎源码进行系统化深度分析，生成结构化开发文档。

## When to Activate

- 需要理解大型游戏引擎架构设计
- 分析 Unreal Engine、Unity、Godot 等引擎源码
- 识别引擎核心模块和依赖关系
- 生成引擎开发文档和 API 参考
- 学习引擎设计模式和最佳实践

## Core Principles

### 1. 渐进式分析
从宏观到微观，循序渐进：架构 → 模块 → 细节 → 概念

### 2. 只读模式
只读取源码，不修改任何文件

### 3. 结构化输出
所有输出放在 `engine-doc-template/` 目录，遵循标准化文档结构

### 4. 实用导向
关注开发者在实际使用中需要了解的内容

## Analysis Phases

### Phase 1: Architecture Analysis (10-20 minutes)

**Output**: `engine-doc-template/architecture/README.md`

**Tasks**:
1. Analyze source code directory structure
2. Identify core modules and dependencies
3. Draw architecture diagram (ASCII art)
4. Identify core subsystems:
   - Rendering System (RHI, Pipeline, Materials)
   - Resource Management (Loading, Caching, Lifecycle)
   - ECS/Scene System (Entities, Components, Systems)
   - Scripting System (Language, Binding, Lifecycle)
   - Physics System (Engine Integration, Collision)
   - Audio System (Processing, 3D Audio)
5. Summarize design principles and tech choices

**Directory Analysis Commands**:
```bash
# List top-level directories
find [ENGINE_SOURCE] -maxdepth 1 -type d

# Count files per directory
find [ENGINE_SOURCE] -name "*.cpp" | cut -d'/' -f2 | sort | uniq -c | sort -nr

# Find CMakeLists for build structure
find [ENGINE_SOURCE] -name "CMakeLists.txt" -o -name "*.cmake"

# Generate dependency graph
cmake --graphviz=deps.dot [ENGINE_SOURCE]
dot -Tpng deps.dot -o deps.png
```

**Architecture Diagram Template**:
```
┌─────────────────────────────────────┐
│      Application Layer              │
├─────────────────────────────────────┤
│      Engine Layer                   │
│  Rendering │ Physics │ Audio │ ... │
├─────────────────────────────────────┤
│      Platform Layer                 │
│  File I/O │ Threading │ Memory     │
├─────────────────────────────────────┤
│      OS/Hardware Layer              │
└─────────────────────────────────────┘
```

### Phase 2: Module Deep Dive (20-40 minutes)

**Output**: `engine-doc-template/modules/[module-name]/README.md`

**Tasks**:
1. Create document for each core module
2. Document structure:
   - **Overview**: Module responsibility and positioning
   - **Architecture**: Module internal structure
   - **Core Classes & Interfaces**:
     ```markdown
     ### ClassName
     **Responsibility**: ...
     **File**: path/to/file.cpp
     **Key Methods**:
     - `Method1()`: Description
     - `Method2()`: Description
     ```
   - **Data Structures**: Key data structures
   - **Design Patterns**: Patterns used and their purpose
   - **Dependencies**: What it depends on, what depends on it
   - **Threading Model**: Single/multi-threaded, synchronization
   - **Performance**: Key performance points and optimizations

3. Extract key code snippets with file paths and line numbers

**Code Analysis Commands**:
```bash
# Find class definitions
grep -r "class.*Renderer" --include="*.h" [ENGINE_SOURCE]

# Find interface definitions
grep -r "virtual.*=" --include="*.h" [ENGINE_SOURCE] | grep class

# Analyze include dependencies
grep -r "#include" --include="*.cpp" [ENGINE_SOURCE]/modules/rendering

# Generate Doxygen documentation
doxygen -g Doxyfile
# Edit Doxyfile: INPUT = [ENGINE_SOURCE], RECURSIVE = YES
doxygen Doxyfile
```

### Phase 3: Version History Analysis (5-15 minutes)

**Output**: `engine-doc-template/changelog/evolution.md`

**Tasks** (if version control exists):
1. Parse commit history
2. Organize major changes by timeline
3. Identify key feature evolution
4. Analyze version milestones
5. (Optional) Analyze contributor distribution

**Git Analysis Commands**:
```bash
# Get commit history
git log --oneline --graph --all --decorate -n 100

# Get commit frequency by author
git shortlog -sn --all

# Find large changes
git log --oneline --stat -n 50 | grep -E "^[a-f0-9]|files? changed"

# Get tag information
git tag -l | sort -V | tail -20

# Analyze module evolution
git log --oneline --name-only -- [ENGINE_SOURCE]/modules/rendering | head -50
```

### Phase 4: Concept Documentation (15-25 minutes)

**Output Files**:
- `engine-doc-template/guides/` - Developer guides
- `engine-doc-template/api-reference/` - API reference
- `engine-doc-template/glossary.md` - Terminology

**Tasks**:
1. Create `glossary.md`:
   - List engine-specific concepts and terms
   - Provide concise definitions and related concepts

2. Create `guides/[concept].md`:
   - Select 5-10 key concepts (rendering pipeline, resource lifecycle, ECS architecture, etc.)
   - For each concept:
     - Concept definition
     - Implementation in engine
     - Usage examples
     - Best practices
     - Common issues

3. Create `api-reference/README.md`:
   - Core class index
   - API list organized by module
   - Usage examples for key APIs

## Output Structure

```
engine-doc-template/
├── README.md                    # Documentation entry point
├── architecture/
│   └── README.md               # Architecture overview ★
├── modules/
│   ├── rendering/
│   │   └── README.md           # Rendering module ★
│   ├── resources/
│   │   └── README.md           # Resource management
│   ├── ecs/
│   │   └── README.md           # ECS module
│   └── ...
├── guides/
│   ├── rendering-pipeline.md   # Rendering pipeline guide ★
│   ├── resource-lifecycle.md   # Resource lifecycle
│   └── ...
├── api-reference/
│   └── README.md               # API index
├── changelog/
│   ├── evolution.md            # Evolution history
│   └── contributors.md         # Contributors
└── glossary.md                  # Terminology ★

★ = Phase 1 required
```

## Documentation Standards

### Markdown Format
- Use Markdown format
- Specify language for code blocks
- Use ASCII diagrams for architecture
- Use tables for comparisons

### Highlight Markers
- ★ Must understand
- ★★★ Core focus
- ⚠️ Notes
- 💡 Design highlights

### Code Reference Format
```markdown
// File: path/to/file.cpp
// Lines: 123-145
// Description: Brief description

code snippet...
```

## Tool Stack

| Category | Tool | Usage |
|----------|------|-------|
| Doc Generation | Doxygen | C++ API documentation |
| Doc Organization | Sphinx | Tutorials and guides |
| Dependency Analysis | CMake Graphviz | Build dependencies |
| Visualization | Graphviz | Diagram generation |
| Interactive Exploration | Sourcetrail | Code navigation |

### Doxygen Setup Example
```bash
cd [ENGINE_SOURCE]
doxygen -g Doxyfile

# Edit Doxyfile
cat >> Doxyfile << EOF
PROJECT_NAME = "GameEngine"
EXTRACT_ALL = YES
EXTRACT_PRIVATE = YES
HAVE_DOT = YES
UML_LOOK = YES
CALL_GRAPH = YES
RECURSIVE = YES
INPUT = ./
EOF

doxygen Doxyfile
```

## Progress Reporting

After completing each phase, report progress:

```
✅ Phase 1 Complete: Architecture Analysis
- Analyzed 15 top-level directories
- Identified 8 core subsystems
- Generated architecture diagram
- Output: architecture/README.md (2,500 lines)

⏭️ Proceeding to Phase 2: Module Deep Dive...
```

## Common Analysis Patterns

### Pattern 1: Renderer Architecture
```cpp
// Typical rendering subsystem structure
class IRenderer {
    virtual void Initialize() = 0;
    virtual void Render(Scene* scene) = 0;
    virtual void Shutdown() = 0;
};

class VulkanRenderer : public IRenderer { /* ... */ };
class DirectXRenderer : public IRenderer { /* ... */ };
```

### Pattern 2: Resource Lifecycle
```cpp
// Typical resource management pattern
class ResourceManager {
    Load(path) → Parse → Create → Cache → Return
    Unload(resource) → Remove from cache → Destroy
    Reload(resource) → Unload → Load
};
```

### Pattern 3: ECS Architecture
```cpp
// Entity-Component-System pattern
Entity = ID only
Component = Data only
System = Logic only

// Example
class TransformComponent { vec3 position; };
class RenderSystem { void update(Entity e) { /* ... */ } };
```

## Best Practices

1. **Start with Architecture** - Build global understanding first
2. **Use Tools** - Doxygen, Graphviz, Sourcetrail save time
3. **Focus on Hot Paths** - Identify performance-critical code
4. **Document Patterns** - Record design patterns and their purpose
5. **Track Progress** - Use checklist to ensure completeness
6. **Cross-Reference** - Link related concepts and modules
7. **Include Examples** - Show how to use APIs in practice

## Success Metrics

- ✅ Architecture diagram clearly shows system layers
- ✅ All core modules documented with examples
- ✅ Key APIs have usage examples
- ✅ Glossary covers engine-specific terms
- ✅ Version history shows major milestones
- ✅ Documentation is readable by new team members

## Estimated Time

| Phase | Content | Duration |
|-------|---------|----------|
| Phase 1 | Architecture Analysis | 10-20 min |
| Phase 2 | Module Deep Dive | 20-40 min |
| Phase 3 | Version History | 5-15 min |
| Phase 4 | Concept Documentation | 15-25 min |

**Total**: ~50-100 minutes (depends on engine complexity)

## Reference Resources

- Methodology: `/root/learning-notes/engine-analysis-toolkit/game-engine-analysis-methodology.md`
- Task Template: `/root/learning-notes/engine-analysis-toolkit/engine-analysis-task.md`
- Prompt Template: `/root/learning-notes/engine-analysis-toolkit/engine-analysis-prompt.md`
- VCS Analysis: `/root/learning-notes/engine-analysis-toolkit/vcs-history-analysis.md`

---

**Version**: 1.0.0 | **Created**: 2026-03-31
