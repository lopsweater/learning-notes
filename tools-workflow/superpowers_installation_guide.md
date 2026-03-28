# Superpowers 安装和部署指南

## 简介

**Superpowers** 是一个开源的、可扩展的、实时协作的 HTML5 游戏开发 IDE。

- **GitHub**: https://github.com/superpowers/superpowers-core
- **官网**: https://superpowers-html5.com/
- **最新版本**: v5.0.0 (2019-03-18)
- **许可证**: ISC

### 特点

- 🎮 **实时协作**: 多人同时编辑项目
- 🌐 **HTML5 应用**: 可下载的跨平台应用
- 🔌 **可扩展**: 支持插件系统
- 🆓 **开源免费**: ISC 许可证

---

## 系统要求

### 必需环境

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| **Node.js** | >= 10.x | 推荐使用 LTS 版本 |
| **npm** | >= 6.x | 随 Node.js 安装 |
| **Git** | 最新版 | 用于克隆仓库 |

### 支持平台

- ✅ Windows 7+
- ✅ macOS 10.12+
- ✅ Linux (Ubuntu 18.04+, Debian 10+, etc.)

### 可选依赖

- **Electron**: 用于打包桌面应用
- **Gulp**: 构建系统

---

## 安装方式

### 方式一：下载预编译版本（推荐新手）

#### 1. 下载

访问 Itch.io 发布页面：
```
https://sparklinlabs.itch.io/superpowers
```

#### 2. 解压并运行

**Windows:**
```batch
:: 解压后运行
Superpowers.exe
```

**macOS:**
```bash
# 解压后运行
open Superpowers.app
```

**Linux:**
```bash
# 解压后添加执行权限
chmod +x Superpowers
./Superpowers
```

---

### 方式二：从源码编译（开发者）

#### 1. 克隆仓库

```bash
# 克隆核心仓库
git clone https://github.com/superpowers/superpowers-core.git
cd superpowers-core
```

#### 2. 安装依赖

```bash
# 安装 Node.js 依赖
npm install
```

#### 3. 构建项目

```bash
# 完整构建
npm run build

# 或使用 Gulp
gulp
```

#### 4. 运行服务器

```bash
# 启动服务器
npm start

# 或指定数据存储路径
node server start --data-path=/path/to/data
```

---

## 部署方式

### 方式一：本地开发（单机模式）

#### 1. 启动服务器

```bash
cd superpowers-core
npm start
```

#### 2. 访问 Web 界面

打开浏览器访问：
```
http://localhost:4237
```

#### 3. 创建项目

1. 点击 "Create New Project"
2. 输入项目名称
3. 选择项目类型（Game, Web, LÖVE）
4. 开始开发

---

### 方式二：服务器部署（协作模式）

#### 1. 配置服务器

创建配置文件 `config.json`:

```json
{
  "serverName": "My Superpowers Server",
  "mainPort": 4237,
  "buildPort": 4238,
  "password": "your-password-here",
  "sessionSecret": "random-secret-key-change-this",
  "maxRecentBuilds": 10
}
```

**配置说明：**

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `serverName` | null | 服务器名称，显示在界面上 |
| `mainPort` | 4237 | 主服务端口（Web 界面） |
| `buildPort` | 4238 | 构建服务端口 |
| `password` | "" | 服务器密码，为空则不需要密码 |
| `sessionSecret` | null | 会话密钥，必须设置 |
| `maxRecentBuilds` | 10 | 保留的最近构建数量 |

#### 2. 启动服务器

```bash
# 前台运行
npm start

# 后台运行（Linux/macOS）
nohup npm start > superpowers.log 2>&1 &

# 使用 PM2（推荐）
pm2 start npm --name "superpowers" -- start
```

#### 3. 防火墙配置

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 4237/tcp
sudo ufw allow 4238/tcp

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=4237/tcp
sudo firewall-cmd --permanent --add-port=4238/tcp
sudo firewall-cmd --reload
```

#### 4. 访问服务器

```
http://your-server-ip:4237
```

---

### 方式三：Docker 部署

#### 1. 创建 Dockerfile

```dockerfile
FROM node:14

# 安装依赖
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# 克隆仓库
WORKDIR /app
RUN git clone https://github.com/superpowers/superpowers-core.git .

# 安装和构建
RUN npm install
RUN npm run build

# 创建数据目录
RUN mkdir -p /data

# 暴露端口
EXPOSE 4237 4238

# 启动命令
CMD ["node", "server", "start", "--data-path=/data"]
```

#### 2. 构建镜像

```bash
docker build -t superpowers:latest .
```

#### 3. 运行容器

```bash
docker run -d \
  --name superpowers \
  -p 4237:4237 \
  -p 4238:4238 \
  -v /path/to/data:/data \
  superpowers:latest
```

#### 4. 使用 Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3'

services:
  superpowers:
    build: .
    ports:
      - "4237:4237"
      - "4238:4238"
    volumes:
      - ./data:/data
    restart: unless-stopped
```

运行：
```bash
docker-compose up -d
```

---

## 项目结构

```
superpowers-core/
├── client/              # 客户端代码
│   └── ...
├── public/              # 静态资源
│   ├── locales/         # 多语言文件
│   └── superpowers.json # 服务器配置
├── scripts/             # 构建脚本
│   ├── build.js         # 构建入口
│   ├── package.js       # 打包脚本
│   └── getBuildPaths.js # 获取构建路径
├── server/              # 服务器代码
│   ├── commands/        # CLI 命令
│   │   ├── start.ts     # 启动命令
│   │   ├── install.ts   # 安装插件
│   │   ├── uninstall.ts # 卸载插件
│   │   ├── update.ts    # 更新
│   │   └── init.ts      # 初始化
│   ├── ProjectHub.ts    # 项目中心
│   ├── ProjectServer.ts # 项目服务器
│   ├── config.ts        # 配置定义
│   └── index.ts         # 入口文件
├── SupClient/           # 客户端核心
├── SupCore/             # 核心库
├── gulpfile.js          # Gulp 构建配置
├── package.json         # 项目配置
└── tsconfig.json        # TypeScript 配置
```

---

## 命令行工具

### 启动服务器

```bash
node server start
```

### 查看注册表

```bash
node server registry
```

### 安装系统/插件

```bash
# 安装系统
node server install game

# 安装插件
node server install game:author/plugin-name
```

### 卸载系统/插件

```bash
# 卸载系统
node server uninstall game

# 卸载插件
node server uninstall game:author/plugin-name
```

### 更新

```bash
# 更新服务器
node server update server

# 更新系统
node server update game

# 更新插件
node server update game:author/plugin-name
```

### 初始化新系统/插件

```bash
# 初始化系统
node server init my-system

# 初始化插件
node server init game:author/my-plugin
```

---

## 数据存储结构

默认数据存储在用户目录下：

```
~/.superpowers/
├── config.json          # 服务器配置
├── projects/            # 项目目录
│   ├── MyGame/         # 项目文件夹
│   │   ├── assets/     # 资源文件
│   │   └── ...
├── systems/            # 系统插件
│   └── game/          # Superpowers Game 系统
└── plugins/            # 用户插件
```

### 自定义数据路径

```bash
node server start --data-path=/custom/path
```

---

## 可用系统（Systems）

Superpowers 是引擎无关的，核心只提供协作框架。

### 官方系统

| 系统 | 说明 | GitHub |
|------|------|--------|
| **Superpowers Game** | 2D+3D 游戏，TypeScript，Three.js | [superpowers-game](https://github.com/superpowers/superpowers-game) |
| **Superpowers Web** | 静态网站，Pug + Stylus | [superpowers-web](https://github.com/superpowers/superpowers-web) |
| **Superpowers LÖVE** | LÖVE 2D 游戏，Lua | [superpowers-love2d](https://github.com/superpowers/superpowers-love2d) |

### 安装系统

```bash
# 安装游戏系统
node server install game

# 安装 Web 系统
node server install web

# 安装 LÖVE 系统
node server install love
```

---

## 插件开发

### 插件结构

```
my-plugin/
├── plugin.json         # 插件元数据
├── public/             # 客户端代码
│   ├── index.js
│   └── style.css
└── server/             # 服务端代码
    └── index.js
```

### plugin.json

```json
{
  "name": "My Plugin",
  "description": "A sample plugin",
  "version": "1.0.0",
  "author": "your-name",
  "system": "game",
  "main": "server/index.js",
  "scripts": {
    "client": "public/index.js"
  }
}
```

### 初始化插件

```bash
node server init game:your-name/my-plugin
```

---

## 常见问题

### Q1: 端口被占用怎么办？

**错误信息：**
```
Error: listen EADDRINUSE :::4237
```

**解决方案：**
```bash
# 查找占用进程
lsof -i :4237

# 终止进程
kill -9 <PID>

# 或修改配置文件中的端口
```

### Q2: 无法访问服务器？

**检查清单：**
1. 确认服务器正在运行
2. 检查防火墙设置
3. 确认端口已开放
4. 尝试使用 `127.0.0.1` 而不是 `localhost`

### Q3: 构建失败？

**常见原因：**
1. Node.js 版本过低
2. npm 依赖未正确安装
3. TypeScript 编译错误

**解决方案：**
```bash
# 清理并重新安装
rm -rf node_modules
npm install

# 重新构建
npm run build
```

### Q4: 如何备份数据？

```bash
# 备份整个数据目录
tar -czf superpowers-backup.tar.gz ~/.superpowers/

# 只备份项目
tar -czf projects-backup.tar.gz ~/.superpowers/projects/
```

### Q5: 如何更新 Superpowers？

```bash
# 拉取最新代码
git pull origin master

# 更新依赖
npm install

# 重新构建
npm run build

# 重启服务器
```

---

## 性能优化

### 服务器优化

```bash
# 使用 PM2 管理
pm2 start npm --name "superpowers" -- start
pm2 save
pm2 startup

# 设置日志轮转
pm2 install pm2-logrotate
```

### 内存优化

```bash
# 限制 Node.js 内存
node --max-old-space-size=2048 server start
```

---

## 安全建议

### 1. 设置强密码

```json
{
  "password": "use-a-strong-password-here",
  "sessionSecret": "use-a-random-secret-key"
}
```

### 2. 使用 HTTPS

使用 Nginx 反向代理：

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:4237;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### 3. 限制访问

```nginx
# 仅允许特定 IP
location / {
    allow 192.168.1.0/24;
    deny all;
    proxy_pass http://localhost:4237;
}
```

---

## 相关资源

- **GitHub**: https://github.com/superpowers/superpowers-core
- **官网**: https://superpowers-html5.com/
- **下载**: https://sparklinlabs.itch.io/superpowers
- **社区**: https://gitter.im/superpowers/dev
- **Twitter**: https://twitter.com/SuperpowersDev
- **Patreon**: https://www.patreon.com/SparklinLabs

---

## 快速启动命令总结

```bash
# 1. 克隆仓库
git clone https://github.com/superpowers/superpowers-core.git
cd superpowers-core

# 2. 安装依赖
npm install

# 3. 构建
npm run build

# 4. 启动服务器
npm start

# 5. 访问
# http://localhost:4237
```
