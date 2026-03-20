---
description: GPU 侧引擎代码审查。GPU 资源泄漏、资源屏障、线程安全、性能问题。
---

# 引擎 GPU 审查命令

此命令调用 **engine-gpu-reviewer** agent，对 GPU 侧代码进行全面审查。

## 此命令的功能

1. 识别 GPU 侧变更 - git diff 查找 rhi/render/*.cpp 文件
2. 运行静态分析 - clang-tidy、cppcheck
3. GPU 资源泄漏检测 - Buffer、Texture、Descriptor
4. 资源屏障检查 - 状态转换正确性
5. 线程安全检查 - 多线程渲染
6. 性能问题检查 - API 调用效率
7. 生成报告 - 按严重性分类

## 适用范围（GPU 侧）

- RHI 抽象层
- GPU Buffer 管理
- Texture 管理
- Descriptor Heap 管理
- Command List 封装
- 渲染管线

## 审查类别

### CRITICAL（必须修复）

- GPU 资源泄漏（Buffer、Texture、Descriptor）
- 使用中销毁资源
- 错误的资源屏障
- 设备丢失未处理

### HIGH（应该修复）

- 命令列表未提交
- Fence 同步缺失
- 描述符堆溢出
- 常量缓冲区对齐错误

### MEDIUM（考虑修复）

- 过多的 API 调用
- 未使用 Bindless 优化
- 资源未池化复用
- 冗余的状态切换

## 示例会话

用户: /engine-gpu-review

Agent:
# GPU 代码审查报告

## 审查文件
- src/rhi/buffer_pool.cpp（已修改）
- src/rhi/descriptor_heap.cpp（已修改）

## 静态分析结果
✓ clang-tidy: 1 个警告
✓ cppcheck: 无问题

## 发现问题

[CRITICAL] Buffer 泄漏
文件：src/rhi/buffer_pool.cpp:78
问题：BufferPool 析构函数未销毁 Buffer

```cpp
// 错误示例
BufferPool::~BufferPool() {
    // 未销毁 buffers_
}

// 修复方案
BufferPool::~BufferPool() {
    for (auto buffer : buffers_) {
        device_->DestroyBuffer(buffer);
    }
    buffers_.clear();
}
```

[HIGH] Fence 同步缺失
文件：src/rhi/buffer_pool.cpp:92
问题：重置 BufferPool 前未等待 GPU 完成

```cpp
// 错误示例
void BufferPool::reset() {
    used_ = 0;  // 可能在 GPU 使用中
}

// 修复方案
void BufferPool::reset(uint64_t fenceValue) {
    device_->WaitForFence(fenceValue);
    used_ = 0;
}
```

[MEDIUM] 过多的 SetGraphicsRootDescriptorTable 调用
文件：src/render/render_pipeline.cpp:145
问题：每个 Draw Call 都设置描述符表

```cpp
// 当前实现
for (auto& draw : drawCalls) {
    commandList->SetGraphicsRootDescriptorTable(0, draw.descriptor);
    commandList->DrawInstanced(...);
}

// 优化方案：使用 Bindless
commandList->SetGraphicsRootDescriptorTable(0, bindlessDescriptorTable);
for (auto& draw : drawCalls) {
    commandList->SetGraphicsRoot32BitConstant(0, draw.materialIndex, 0);
    commandList->DrawInstanced(...);
}
```

## 汇总
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 1

建议：❌ 阻止合并，直到 CRITICAL 和 HIGH 问题修复

## 批准标准

| 状态 | 条件 |
|------|------|
| ✅ 批准 | 无 CRITICAL 或 HIGH 问题 |
| ⚠️ 警告 | 仅有 MEDIUM 问题（谨慎合并） |
| ❌ 阻止 | 有 CRITICAL 或 HIGH 问题 |

## GPU 侧检查清单

### 资源生命周期
- [ ] Buffer 创建后正确销毁
- [ ] Texture 创建后正确销毁
- [ ] Descriptor 正确释放
- [ ] 使用延迟销毁队列

### 资源屏障
- [ ] 状态转换正确
- [ ] UAV 屏障正确
- [ ] 使用正确的 Barrier 标志

### 同步
- [ ] 使用 Fence 同步
- [ ] 等待 GPU 完成
- [ ] 避免死锁

### 性能
- [ ] 资源池化复用
- [ ] Bindless 优化
- [ ] 减少 API 调用

## 自动化检查命令

```bash
# 静态分析
clang-tidy --checks='*' src/rhi/*.cpp src/render/*.cpp -- -std=c++20

# 构建并启用警告
cmake --build build -- -Wall -Wextra -Wpedantic

# AddressSanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" ..
ctest --test-dir build -L gpu --output-on-failure
```

## GPU 调试工具推荐

| 工具 | 用途 |
|------|------|
| PIX for Windows | D3D12 资源跟踪 |
| RenderDoc | 帧捕获、资源检查 |
| NVIDIA Nsight | GPU 性能分析 |
| Tracy Profiler | CPU/GPU 时间线 |

## 相关命令

- `/engine-gpu-build-fix` - 修复构建错误
- `/engine-gpu-test` - 运行测试
- `/engine-render-debug` - 渲染调试

## 相关 Agent

- `agents/engine-gpu-reviewer.md`
- `skills/engine-gpu-testing/`
