---
description: Diagnose and resolve RHI layer issues. Resource leak detection, state transition errors, synchronization problems, API error analysis, performance issue investigation.
---

# RHI Debug Command

This command helps diagnose and resolve RHI layer issues.

## What This Command Does

1. 资源泄漏检测 - Buffer、Texture、Descriptor 泄漏
2. 资源状态检查 - 状态转换错误
3. 同步问题诊断 - Fence、死锁
4. API 错误分析 - D3D12/Vulkan 错误
5. 性能问题分析 - API 调用效率

## 常见问题诊断

### 1. 资源泄漏

**症状：** 内存占用持续增长

**诊断命令：**
```bash
# D3D12 调试层
# 启用后会在输出窗口显示泄漏信息
D3D12GetDebugInterface()->EnableDebugLayer();

# Vulkan 验证层
# 设置环境变量
export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation
```

**检查清单：**
- [ ] 所有 CreateBuffer 有对应的 DestroyBuffer
- [ ] 所有 CreateTexture 有对应的 DestroyTexture
- [ ] 所有 AllocateDescriptor 有对应的 FreeDescriptor
- [ ] 使用 RAII 包装资源

### 2. 资源状态错误

**症状：** 渲染结果错误、闪烁、设备丢失

**D3D12 诊断：**
```cpp
// 启用资源状态验证
D3D12_DEBUG_FEATURE features = D3D12_DEBUG_FEATURE_VALIDATION;
debug->SetEnableGPUBasedValidation(TRUE);
```

**Vulkan 诊断：**
```bash
export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation
# 验证层会报告状态转换错误
```

**检查清单：**
- [ ] 所有资源使用前有正确的 Barrier
- [ ] 状态转换完整（Before → After）
- [ ] 并行访问使用 UAV Barrier
- [ ] Present 前转换到 Present 状态

### 3. 同步问题

**症状：** 画面撕裂、设备丢失、随机崩溃

**诊断方法：**
```cpp
// D3D12: 检查 Fence 值
uint64_t completed = fence->GetCompletedValue();
uint64_t signaled = fenceValue;
if (completed < signaled - FRAME_COUNT) {
    // 警告：GPU 落后过多
}

// Vulkan: 检查 Timeline Semaphore
uint64_t value;
vkGetSemaphoreCounterValue(device, timelineSemaphore, &value);
```

**检查清单：**
- [ ] 每帧开始等待上一帧完成
- [ ] 提交命令后正确设置 Fence
- [ ] 资源重用前等待 GPU 完成
- [ ] 避免死锁（Fence 等待顺序）

### 4. API 错误

**D3D12 常见错误：**

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| DXGI_ERROR_DEVICE_REMOVED | GPU 挂起 | 检查资源状态、同步 |
| E_OUTOFMEMORY | 显存不足 | 释放未使用资源 |
| E_INVALIDARG | 参数无效 | 检查参数范围 |

**Vulkan 常见错误：**

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| VK_ERROR_DEVICE_LOST | GPU 挂起 | 检查资源状态、同步 |
| VK_ERROR_OUT_OF_MEMORY | 内存不足 | 释放未使用资源 |
| VK_ERROR_OUT_OF_DATE_KHR | Swapchain 过期 | 重新创建 Swapchain |

## 调试工具

### D3D12 工具

| 工具 | 用途 |
|------|------|
| PIX for Windows | 帧捕获、资源检查 |
| Visual Studio Graphics Debugger | 图形调试 |
| NVIDIA Nsight Graphics | GPU 性能分析 |

### Vulkan 工具

| 工具 | 用途 |
|------|------|
| RenderDoc | 帧捕获分析 |
| Vulkan Validation Layers | API 验证 |
| NVIDIA Nsight Graphics | GPU 性能分析 |

## 调试脚本

### D3D12 资源跟踪

```cpp
// utils/resource_tracker.hpp
class ResourceTracker {
public:
    void TrackBuffer(RHIBuffer* buffer, const char* name) {
        std::lock_guard<std::mutex> lock(mutex_);
        buffers_[buffer] = {name, std::chrono::steady_clock::now()};
    }
    
    void UntrackBuffer(RHIBuffer* buffer) {
        std::lock_guard<std::mutex> lock(mutex_);
        buffers_.erase(buffer);
    }
    
    void ReportLeaks() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!buffers_.empty()) {
            printf("=== Buffer 泄漏 ===\n");
            for (const auto& [buffer, info] : buffers_) {
                printf("  %s (created %ld seconds ago)\n",
                    info.name,
                    std::chrono::duration_cast<std::chrono::seconds>(
                        std::chrono::steady_clock::now() - info.createTime
                    ).count()
                );
            }
        }
    }
    
private:
    struct ResourceInfo {
        const char* name;
        std::chrono::steady_clock::time_point createTime;
    };
    
    std::mutex mutex_;
    std::unordered_map<RHIBuffer*, ResourceInfo> buffers_;
};
```

### Vulkan 验证层配置

```cpp
// 启用验证层
const char* layers[] = {
    "VK_LAYER_KHRONOS_validation",
};

VkInstanceCreateInfo createInfo = {};
createInfo.enabledLayerCount = 1;
createInfo.ppEnabledLayerNames = layers;

// 配置验证层
VkValidationFeaturesEXT features = {};
VkValidationFeatureEnableEXT enables[] = {
    VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT,
    VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT,
};
features.sType = VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT;
features.enabledValidationFeatureCount = 2;
features.pEnabledValidationFeatures = enables;
createInfo.pNext = &features;
```

## 性能问题诊断

### API 调用过多

**症状：** CPU 时间过长

**诊断：**
```cpp
// 统计 API 调用次数
struct APICallStats {
    int drawCalls = 0;
    int setPipelineCalls = 0;
    int barrierCalls = 0;
    int copyCalls = 0;
    
    void Reset() { *this = {}; }
    void Report() {
        printf("Draw Calls: %d\n", drawCalls);
        printf("SetPipeline: %d\n", setPipelineCalls);
        printf("Barriers: %d\n", barrierCalls);
    }
};
```

**优化建议：**
- 使用实例化减少 Draw Call
- 合并相同状态的绘制
- 批量提交 Barrier

### 内存带宽瓶颈

**症状：** GPU 时间过长

**诊断：**
- 使用 PIX/Nsight 分析带宽使用
- 检查纹理格式压缩
- 检查常量缓冲区大小

**优化建议：**
- 使用 BC 压缩纹理
- 减少 Vertex Format 大小
- 使用持久映射减少上传开销

## 示例会话

用户: /rhi-debug 我的程序运行一段时间后崩溃，怀疑是资源泄漏

Agent:
# RHI 资源泄漏诊断

## 步骤 1：启用调试层

**D3D12:**
```cpp
ComPtr<ID3D12Debug> debug;
D3D12GetDebugInterface(IID_PPV_ARGS(&debug));
debug->EnableDebugLayer();
```

**Vulkan:**
```bash
export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation
```

## 步骤 2：添加资源跟踪

```cpp
ResourceTracker tracker;

// 创建时
RHIBuffer* buffer = device->CreateBuffer(desc);
tracker.TrackBuffer(buffer, "MyBuffer");

// 销毁时
tracker.UntrackBuffer(buffer);
device->DestroyBuffer(buffer);
```

## 步骤 3：程序退出时检查

```cpp
// main.cpp 退出前
tracker.ReportLeaks();
```

## 步骤 4：检查泄漏来源

常见泄漏原因：
1. 忘记调用 DestroyBuffer/DestroyTexture
2. 异常路径未释放资源
3. RAII 包装不完整

## 建议修复

使用 RAII 包装：
```cpp
class BufferPtr {
public:
    BufferPtr(RHIDevice* device, const BufferDesc& desc)
        : device_(device), buffer_(device->CreateBuffer(desc)) {}
    ~BufferPtr() { if (buffer_) device_->DestroyBuffer(buffer_); }
    
    // 禁止拷贝
    BufferPtr(const BufferPtr&) = delete;
    BufferPtr& operator=(const BufferPtr&) = delete;
    
    // 允许移动
    BufferPtr(BufferPtr&& other) noexcept
        : device_(other.device_), buffer_(other.buffer_) {
        other.buffer_ = nullptr;
    }
    
    RHIBuffer* Get() const { return buffer_; }
    
private:
    RHIDevice* device_;
    RHIBuffer* buffer_;
};
```

## 相关命令

- `/rhi-design` - 设计 RHI 接口
- `/rhi-implement` - 实现 RHI 后端
- `/engine-gpu-review` - GPU 代码审查
