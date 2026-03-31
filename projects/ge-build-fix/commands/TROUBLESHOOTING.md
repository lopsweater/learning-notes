# 编译修复检查清单

> 用于跟踪编译修复进度

## 准备阶段

- [ ] 确认构建日志存在
- [ ] 确认编译器版本
- [ ] 确认目标平台
- [ ] 备份关键文件

## 错误诊断

- [ ] 读取构建日志
- [ ] 提取错误信息
- [ ] 分类错误类型
  - [ ] 平台特定错误
  - [ ] 图形 API 错误
  - [ ] 模板/类型错误
  - [ ] 链接错误
  - [ ] CMake 错误
- [ ] 识别根因

## 环境检查

### Windows

- [ ] MSVC 已安装
- [ ] Windows SDK 已安装
- [ ] DirectX SDK（如需要）
- [ ] 环境变量已配置

### Linux

- [ ] GCC/Clang 已安装
- [ ] Vulkan SDK 已安装
- [ ] 开发库已安装
  - [ ] libvulkan-dev
  - [ ] libx11-dev
  - [ ] libxcb1-dev

### macOS

- [ ] Xcode 已安装
- [ ] Command Line Tools 已安装
- [ ] Vulkan SDK（如使用）

## 依赖检查

### D3D12

- [ ] d3d12.dll 存在
- [ ] dxgi.dll 存在
- [ ] 头文件可访问
  - [ ] d3d12.h
  - [ ] dxgi1_6.h

### Vulkan

- [ ] VULKAN_SDK 环境变量已设置
- [ ] libvulkan.so / vulkan-1.dll 存在
- [ ] vulkan.h 可访问
- [ ] Vulkan Loader 已安装

### OpenGL

- [ ] libGL.so / opengl32.dll 存在
- [ ] GL/gl.h 可访问

## 修复应用

### 头文件修复

- [ ] 识别缺少的头文件
- [ ] 检查平台兼容性
- [ ] 添加正确的 #include
- [ ] 添加库链接（#pragma comment）

### 导出宏修复

- [ ] 检查导出宏定义
- [ ] 添加 RHI_API 宏
- [ ] 设置 BUILD_XXX 定义
- [ ] 验证宏展开

### CMake 修复

- [ ] 检查 find_package 配置
- [ ] 添加依赖路径
- [ ] 更新 target_link_libraries
- [ ] 验证 CMake 配置

## 验证阶段

- [ ] 清理构建目录
- [ ] 重新配置 CMake
- [ ] 重新编译
- [ ] 检查错误数量
- [ ] 检查警告数量
- [ ] 运行测试（如有）

## 完成检查

- [ ] 所有编译错误已解决
- [ ] 所有链接错误已解决
- [ ] 无新增警告
- [ ] 目标可执行
- [ ] 功能正常（基本测试）
- [ ] 文档已更新（如有需要）

## 回滚计划

如果修复失败：

- [ ] 恢复备份文件（.bak）
- [ ] 清理构建目录
- [ ] 重新编译
- [ ] 使用交互模式手动修复

---

**创建时间**: 2026-03-31
**版本**: 1.0.0
