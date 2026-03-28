# Superpowers 安装和部署指南

## 概述

**Superpowers** 是一个开源的、可扩展的、实时协作的 HTML5 游戏开发 IDE。

### 特点
- 可下载的 HTML5 应用
- 实时协作开发
- 支持 2D + 3D 游戏开发
- TypeScript 脚本
- 基于 Three.js
- 跨平台（Windows、macOS、Linux）

---

## 方式一：下载预编译版本（推荐）

### 下载地址

官方下载页面：https://sparklinlabs.itch.io/superpowers

### 支持平台
- Windows
- macOS
- Linux

### 安装步骤

```bash
# 1. 访问下载页面
# https://sparklinlabs.itch.io/superpowers

# 2. 选择对应平台的版本下载

# 3. 解压并运行
# Windows: 双击 Superpowers.exe
# macOS: 打开 Superpowers.app
# Linux: ./Superpowers
```

---

## 方式二：从源码构建

### 环境要求

- **Node.js**: v10.x 或更高版本
- **npm**: v6.x 或更高版本
- **Git**: 最新版本

### 构建步骤

```bash
# 1. 克隆仓库
git clone https://github.com/superpowers/superpowers-core.git
cd superpowers-core

# 2. 安装依赖
npm install

# 3. 构建项目
npm run build

# 4. 启动服务器
npm start
```

### 构建脚本说明

```json
{
  "scripts": {
    "build": "node scripts/build.js",    // 构建项目
    "start": "node server start",        // 启动服务器
    "package": "node scripts/package.js" // 打包为可执行文件
  }
}
```

---

## 方式三：开发模式运行

### 开发环境设置

```bash
# 1. 克隆仓库
git clone https://github.com/superpowers/superpowers-core.git
cd superpowers-core

# 2. 安装依赖
npm install

# 3. 开发模式运行（自动重新编译）
npm run build
npm start
```

### 访问应用

启动后，打开浏览器访问：
- **本地**: http://localhost:4237
- **局域网**: http://<your-ip>:4237

---

## 配置和部署

### 服务器配置

Superpowers 支持两种模式：

#### 1. 单机模式（离线使用）

```bash
# 直接启动，无需密码
npm start
```

#### 2. 协作模式（多人在线）

```bash
# 设置密码，允许其他人加入
npm start -- --password your-password

# 或者使用配置文件
```

### 端口配置

默认端口是 `4237`，可以通过命令行修改：

```bash
# 自定义端口
npm start -- --port 8080
```

### 命令行参数

```bash
# 查看帮助
node server --help

# 常用参数
node server start \
  --port 4237 \          # 监听端口
  --password secret \    # 设置密码
  --storage ./projects   # 项目存储路径
```

---

## 项目结构

```
superpowers-core/
├── client/              # 客户端代码
├── server/              # 服务器代码
├── public/              # 静态资源
├── scripts/             # 构建脚本
├── SupClient/           # 客户端核心库
├── SupCore/             # 服务器核心库
├── package.json         # 项目配置
└── registry.json        # 插件注册表
```

---

## 插件系统

Superpowers 支持插件扩展：

### 官方插件

1. **Superpowers Game** - 2D+3D 游戏开发
   - GitHub: https://github.com/superpowers/superpowers-game

2. **Superpowers Web** - 静态网站制作
   - GitHub: http://github.com/superpowers/superpowers-web

3. **Superpowers LÖVE** - LÖVE 2D 游戏开发
   - GitHub: https://github.com/superpowers/superpowers-love2d

### 安装插件

```bash
# 1. 下载插件
cd superpowers-core
git clone https://github.com/superpowers/superpowers-game plugins/superpowers-game

# 2. 重新构建
npm run build

# 3. 重启服务器
npm start
```

---

## Docker 部署（可选）

### Dockerfile 示例

```dockerfile
FROM node:12

WORKDIR /app

# 克隆仓库
RUN git clone https://github.com/superpowers/superpowers-core.git .

# 安装依赖
RUN npm install

# 构建
RUN npm run build

# 暴露端口
EXPOSE 4237

# 启动
CMD ["node", "server", "start"]
```

### 构建和运行

```bash
# 构建镜像
docker build -t superpowers .

# 运行容器
docker run -d \
  -p 4237:4237 \
  -v /path/to/projects:/app/projects \
  --name superpowers-server \
  superpowers
```

---

## 常见问题

### Q1: 端口被占用？

```bash
# 查看端口占用
lsof -i :4237

# 使用其他端口
npm start -- --port 8080
```

### Q2: 依赖安装失败？

```bash
# 清理缓存
npm cache clean --force

# 删除 node_modules
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

### Q3: 构建失败？

```bash
# 检查 Node.js 版本
node --version  # 需要 v10+

# 检查 TypeScript 版本
npx tsc --version
```

### Q4: 无法访问？

```bash
# 检查防火墙
# Linux
sudo ufw allow 4237

# macOS
# 系统偏好设置 → 安全性与隐私 → 防火墙选项

# Windows
# 控制面板 → Windows 防火墙 → 允许应用
```

---

## 生产环境部署建议

### 1. 使用 PM2 管理进程

```bash
# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start server/index.js --name superpowers

# 开机自启
pm2 startup
pm2 save
```

### 2. 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:4237;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### 3. 使用 HTTPS

```bash
# 使用 Let's Encrypt
sudo certbot --nginx -d your-domain.com
```

---

## 参考链接

- **官方网站**: http://superpowers-html5.com/
- **下载页面**: https://sparklinlabs.itch.io/superpowers
- **文档**: http://docs.superpowers-html5.com/
- **GitHub**: https://github.com/superpowers/superpowers-core
- **社区**: https://gitter.im/superpowers/dev
- **Twitter**: https://twitter.com/SuperpowersDev
- **Patreon**: https://www.patreon.com/SparklinLabs

---

## 许可证

Superpowers 使用 **ISC 许可证**，开源免费。

---

## 总结

| 方式 | 难度 | 适用场景 |
|------|------|---------|
| **下载预编译版** | ⭐ | 快速体验、日常使用 |
| **从源码构建** | ⭐⭐⭐ | 开发插件、定制功能 |
| **Docker 部署** | ⭐⭐ | 生产环境、团队协作 |

**推荐**：初次使用下载预编译版本，需要定制时再从源码构建。
