# CLI-Anything 深度研究

> 研究时间：2026-03-21
> 项目地址：https://github.com/HKUDS/CLI-Anything
> 核心理念：**让任何软件都能被 AI Agent 控制，而不需要修改软件本身**

---

## 一、核心原理

### 1.1 问题背景

AI agents 擅长推理，但不擅长使用真实的专业软件（GIMP、Blender、LibreOffice 等）。现有解决方案：

- **UI 自动化**：脆弱、易崩溃、依赖像素识别
- **API 封装**：需要软件开发者支持，覆盖率低
- **功能重实现**：丢失 90% 专业功能

### 1.2 CLI-Anything 的解决方案

**不重新实现软件，而是为现有软件构建结构化的命令行接口。**

```
源代码 → 分析 → 设计 → 实现 → 测试 → 文档 → 发布 → 可安装的 CLI
```

### 1.3 核心设计原则

| 原则 | 说明 |
|------|------|
| **真实软件集成** | CLI 调用实际应用渲染，不替代实现 |
| **Agent 原生设计** | --json 输出，--help 发现，统一 REPL |
| **解决渲染差距** | 原生渲染器 → 过滤器转换 → 渲染脚本 |
| **无妥协依赖** | 软件是硬依赖，不是可选项 |

---

## 二、7 阶段自动化流水线

```
Phase 1: 代码库分析
├── 识别后端引擎
├── 映射 GUI 操作到 API
├── 分析数据模型
└── 发现现有 CLI 工具

Phase 2: CLI 架构设计
├── 选择交互模型（REPL / 子命令 / 双模式）
├── 定义命令组
├── 设计状态模型
└── 规划输出格式

Phase 3: 实现
├── 数据层：项目文件操作
├── 查询命令：info, list, status
├── 修改命令：create, update, delete
├── 后端集成：调用真实软件
├── 会话管理：状态持久化、撤销/重做
└── REPL 界面：统一体验

Phase 4: 测试规划（TEST.md）
├── 测试清单
├── 单元测试计划
├── E2E 测试计划
└── 真实工作流场景

Phase 5: 测试实现
├── 单元测试：合成数据，无外部依赖
├── E2E 原生：验证项目文件结构
├── E2E 真实后端：调用真实软件
└── CLI 子进程测试

Phase 6: 测试文档
└── 记录测试结果和覆盖率

Phase 6.5: SKILL.md 生成
└── 为 AI Agent 生成技能定义文件

Phase 7: PyPI 发布
└── 打包、安装、发布
```

---

## 三、不同项目类型的分析策略

### 3.1 GUI 软件（如 GIMP, Blender）

```
分析流程：
1. 识别后端引擎（MLT, GEGL, bpy）
2. 映射 GUI 操作 → API 调用
3. 分析项目文件格式（XML, JSON, 二进制）
4. 发现现有 CLI 工具（melt, ffmpeg, convert）
```

**实现模式：**
```python
# 1. CLI 生成项目文件
odf_path = write_odf(tmp_path, doc_type, project)

# 2. 调用真实软件渲染
subprocess.run([
    "libreoffice", "--headless",
    "--convert-to", "pdf",
    odf_path,
])
```

### 3.2 REST API 服务（如 Zoom, AnyGen）

```
分析流程：
1. 分析 API 端点目录
2. 识别资源模型（meeting, task, file）
3. 映射端点 → 命令组
4. 处理认证和异步任务
```

**端点映射：**
```
REST API                        CLI 命令
─────────────────────────────────────────────
POST /users/me/meetings    →   meeting create
GET  /users/me/meetings    →   meeting list
PATCH /meetings/{id}       →   meeting update
DELETE /meetings/{id}      →   meeting delete
```

### 3.3 SDK/库（如 bpy, Python 库）

```
分析流程：
1. 分析公开函数/类签名
2. 识别参数类型和返回值
3. 按功能分组
4. 构建命令映射
```

### 3.4 游戏引擎（复杂案例）

```
游戏引擎
├── GUI 编辑器
├── 脚本系统（C#, GDScript, Blueprints）
├── 资源格式（场景、材质、预制件）
├── 渲染引擎
└── 构建系统
```

**分析策略：**
| 引擎 | 脚本接口 | 资源格式 | CLI 策略 |
|------|----------|----------|----------|
| Unreal | C++ + Blueprints + Python | .umap + .uasset | Python API + 脚本生成 |
| Unity | C# + Editor Scripts | .unity (YAML) | Batch mode + YAML 操作 |
| Godot | GDScript + C# | .tscn (文本) | 直接操作文本格式 |

**实现模式：**
```python
# 中间 JSON → 引擎脚本生成
def generate_unreal_script(scene_json):
    script = """
    import unreal
    
    for obj in scene_json["objects"]:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.StaticMesh,
            unreal.Vector(obj['position'])
        )
    """
    return script
```

---

## 四、关键技术洞察

### 4.1 渲染差距问题

**问题**：GUI 应用在渲染时才应用效果。如果 CLI 只操作项目文件但用简单工具导出，效果会丢失。

**解决方案优先级：**
1. **最佳**：使用软件原生渲染器（melt for MLT, Blender for .blend）
2. **备选**：构建翻译层（MLT 滤镜 → ffmpeg `-filter_complex`）
3. **最后**：生成用户可手动运行的渲染脚本

### 4.2 滤镜转换挑战

| 挑战 | 解决方案 |
|------|----------|
| 同一滤镜不能重复 | 合并参数：`eq=brightness=X:saturation=Y` |
| 流顺序约束 | ffmpeg concat 要求交错：`[v0][a0][v1][a1]` |
| 参数范围不同 | 显式映射每个参数 |
| 无法映射的效果 | 警告并跳过，不崩溃 |

### 4.3 时间码精度

非整数帧率（29.97fps）导致累积舍入：
- 使用 `round()` 而非 `int()`
- 整数运算显示时间码
- 测试中允许 ±1 帧容差

### 4.4 输出验证方法论

```python
# 永远不要信任"成功退出"
# 必须验证：

# 视频格式
assert f.read(5) == b"%PDF-"  # 魔数

# ZIP 结构（OOXML）
import zipfile
zipfile.ZipFile(path).testzip()

# 像素分析
probe_frames(video_path, frames=[0, mid, -1])

# 音频分析
check_rms_levels(audio_path, start=0, end=duration)
```

---

## 五、运行时 IPC 通信方案

当需要在引擎运行时执行 CLI 指令：

### 5.1 方案对比

| 方案 | 延迟 | 复杂度 | 适用场景 |
|------|------|--------|----------|
| TCP Socket | 低 | 中 | 所有引擎，跨进程 |
| HTTP Server | 中 | 中 | 通用性强，易调试 |
| 共享内存 | 最低 | 中 | 高频数据交换 |
| 文件监控 | 中 | 低 | 简单原型 |
| 控制台命令 | 最低 | 低 | Unreal 专用 |

### 5.2 TCP Socket 实现

**引擎端：**
```python
class EngineCommandServer:
    def __init__(self, port=9999):
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.bind(('127.0.0.1', port))
        self.server.listen(1)
        
    def _execute(self, command):
        import unreal
        cmd = command.get("cmd")
        
        if cmd == "spawn_actor":
            actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
                unreal.StaticMesh,
                unreal.Vector(**command["args"]["position"])
            )
            return {"status": "ok", "actor": actor.get_name()}
```

**CLI 端：**
```python
class EngineClient:
    def send(self, command):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('127.0.0.1', 9999))
        sock.send(json.dumps(command).encode())
        return json.loads(sock.recv(4096))
```

### 5.3 推荐架构

```
CLI (Click)
    ↓
Engine Client (TCP/HTTP/File)
    ↓ IPC
Engine Server (运行中)
    ↓
Game Engine
```

---

## 六、CLI 命令架构示例

以游戏引擎为例：

```bash
# 场景管理
cli-anything-engine scene new --name "Level1" -o level1.json
cli-anything-engine --project level1.json scene info

# 对象操作
cli-anything-engine --project level1.json object add cube --position 0,0,0
cli-anything-engine --project level1.json object add light --type point
cli-anything-engine --project level1.json object list

# 材质
cli-anything-engine --project level1.json material create --name "Wood"
cli-anything-engine --project level1.json material assign --object Cube

# 预制件
cli-anything-engine --project level1.json prefab create --objects Player

# 渲染
cli-anything-engine --project level1.json render preview --output shot.png

# 构建
cli-anything-engine --project level1.json build windows --output ./builds/
```

---

## 七、目录结构规范

```
<software>/
└── agent-harness/
    ├── <SOFTWARE>.md          # 项目特定分析 SOP
    ├── setup.py               # PyPI 配置
    ├── cli_anything/          # 命名空间包（无 __init__.py）
    │   └── <software>/
    │       ├── __init__.py
    │       ├── <software>_cli.py  # CLI 入口
    │       ├── core/              # 核心模块
    │       │   ├── project.py
    │       │   ├── objects.py
    │       │   └── session.py
    │       ├── utils/             # 工具
    │       │   ├── <software>_backend.py
    │       │   └── repl_skin.py
    │       └── tests/
    │           ├── TEST.md
    │           ├── test_core.py
    │           └── test_full_e2e.py
```

---

## 八、关键收获

1. **CLI 是接口，不是替代品**
   - 为软件构建结构化接口，而非重新实现

2. **真实软件是硬依赖**
   - 必须调用实际应用渲染
   - 测试失败而非跳过，当软件缺失时

3. **中间格式 + 脚本生成**
   - JSON 场景描述 → 引擎脚本 → 真实渲染

4. **多层级测试**
   - 单元：合成数据
   - E2E 原生：验证文件结构
   - E2E 真实：调用真实软件
   - CLI 子进程：测试安装后的命令

5. **Agent 友好设计**
   - `--json` 结构化输出
   - `--help` 能力发现
   - REPL 交互模式
   - SKILL.md 自动生成

---

## 九、参考资源

- [CLI-Anything GitHub](https://github.com/HKUDS/CLI-Anything)
- [CLI-Hub](https://hkuds.github.io/CLI-Anything/hub/) - 社区 CLI 注册中心
- [HARNESS.md](https://github.com/HKUDS/CLI-Anything/blob/main/cli-anything-plugin/HARNESS.md) - 方法论 SOP

---

## 十、应用思考

### 对自研游戏引擎的启发

1. **暴露 Python 脚本接口**
   - 实现类似 bpy 的脚本 API
   - 支持后台模式运行

2. **设计文本格式的资源文件**
   - 场景文件可文本序列化
   - 便于 CLI 直接操作

3. **内置 IPC 服务器**
   - TCP/HTTP 接口接收命令
   - 支持运行时动态修改

4. **统一的 CLI 规范**
   - JSON 输出模式
   - 标准化命令结构
   - REPL 交互体验

---

*本文档基于 CLI-Anything 项目研究和讨论整理*
