# Claude Task Runner

一个基于 Python + FastAPI 的 Claude Code 任务管理系统。

## 功能特性

- 📝 **任务提交**: 通过 Web UI 或 HTTP API 提交 Claude Code 任务
- 📋 **任务队列**: 按顺序自动执行任务
- 📊 **状态可视化**: 实时查看任务状态和结果
- 🔄 **自动刷新**: 每 10 秒自动更新状态
- 📱 **响应式设计**: 支持移动端访问

## 快速开始

### 1. 安装依赖

```bash
./setup.sh
```

或手动安装：

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt
```

### 2. 配置

编辑 `config.yaml`:

```yaml
server:
  host: "0.0.0.0"
  port: 3000

frontend:
  mode: "simple"  # simple, vue, react

claude:
  timeout: 300
  default_working_dir: "/root/learning-notes"
  cli_path: "claude"  # Claude Code CLI 路径

database:
  path: "./data/tasks.db"
```

### 3. 启动服务

```bash
./run.sh
```

或：

```bash
source venv/bin/activate
uvicorn backend.main:app --host 0.0.0.0 --port 3000 --reload
```

### 4. 访问

打开浏览器访问: http://localhost:3000

## API 接口

### 提交任务

```bash
POST /api/tasks

{
  "prompt": "帮我创建一个 Python Hello World 程序",
  "working_directory": "/path/to/project",
  "timeout": 300,
  "callback_url": "https://example.com/callback"
}
```

### 获取任务列表

```bash
GET /api/tasks?page=1&page_size=20&status=pending
```

### 获取任务详情

```bash
GET /api/tasks/{task_id}
```

### 删除任务

```bash
DELETE /api/tasks/{task_id}
```

### 获取统计信息

```bash
GET /api/stats
```

## 项目结构

```
claude-task-runner/
├── backend/
│   ├── main.py              # FastAPI 主入口
│   ├── config.py            # 配置管理
│   ├── models.py            # 数据模型
│   ├── database.py          # SQLite 操作
│   ├── task_queue.py        # 任务队列
│   ├── claude_runner.py     # Claude Code 执行器
│   └── requirements.txt     # Python 依赖
├── frontend/
│   └── simple/              # 纯 HTML+CSS+JS 前端
│       ├── index.html
│       ├── style.css
│       └── app.js
├── data/
│   └── tasks.db             # SQLite 数据库 (自动创建)
├── config.yaml              # 配置文件
├── run.sh                   # 启动脚本
├── setup.sh                 # 安装脚本
└── README.md
```

## 配置说明

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `HOST` | 服务监听地址 | `0.0.0.0` |
| `PORT` | 服务端口 | `3000` |
| `CLAUDE_TASK_RUNNER_CONFIG` | 配置文件路径 | `./config.yaml` |

### 前端模式

支持三种前端模式（在 `config.yaml` 中配置）:

1. **simple**: 纯 HTML + CSS + JavaScript（默认）
2. **vue**: Vue 3 SPA（需自行实现）
3. **react**: React SPA（需自行实现）

## Claude Code 要求

确保 Claude Code 已安装并可在命令行访问：

```bash
# 检查安装
claude --version

# 如果未安装，访问：
# https://docs.anthropic.com/claude/docs/claude-code
```

## 回调通知

任务完成时会向 `callback_url` 发送 POST 请求：

```json
{
  "id": "task-uuid",
  "status": "completed",
  "result": "执行结果...",
  "error": null,
  "completed_at": "2026-03-23T15:30:00"
}
```

## 故障排查

### Claude Code 未找到

```
错误: Claude Code CLI not found at 'claude'
```

解决：安装 Claude Code 或在 `config.yaml` 中设置完整路径：

```yaml
claude:
  cli_path: "/usr/local/bin/claude"
```

### 端口被占用

```bash
# 更换端口
PORT=3001 ./run.sh
```

### 数据库错误

```bash
# 重置数据库
rm -f data/tasks.db
```

## 开发

### 添加新的前端模式

1. 在 `frontend/` 下创建新目录
2. 实现 `index.html`
3. 更新 `config.yaml` 中的 `frontend.mode`

### 扩展 API

在 `backend/main.py` 中添加新的路由。

## License

MIT
