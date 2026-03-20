# D3D12 同步机制

## Fence 基础

```cpp
// 创建 Fence
ID3D12Fence* fence;
device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));

UINT64 currentValue = 0;
```

## GPU Signal

```cpp
// 提交命令后发送信号
commandQueue->ExecuteCommandLists(1, &commandList);
currentValue++;
commandQueue->Signal(fence, currentValue);
```

## CPU Wait

```cpp
void WaitForFence(ID3D12Fence* fence, UINT64 value) {
    if (fence->GetCompletedValue() < value) {
        HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
        fence->SetEventOnCompletion(value, event);
        WaitForSingleObject(event, INFINITE);
        CloseHandle(event);
    }
}
```

## 帧同步

```cpp
class FrameSync {
    static const UINT FRAME_COUNT = 3;
    
    ID3D12Fence* m_fence;
    UINT64 m_fenceValues[FRAME_COUNT] = {};
    UINT m_currentFrame = 0;
    HANDLE m_fenceEvent;
    
public:
    void Init(ID3D12Device* device) {
        device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&m_fence));
        m_fenceEvent = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    }
    
    void BeginFrame() {
        // 等待当前帧的 GPU 工作完成
        UINT64 expectedValue = m_fenceValues[m_currentFrame];
        if (m_fence->GetCompletedValue() < expectedValue) {
            m_fence->SetEventOnCompletion(expectedValue, m_fenceEvent);
            WaitForSingleObject(m_fenceEvent, INFINITE);
        }
    }
    
    void EndFrame(ID3D12CommandQueue* queue) {
        m_fenceValues[m_currentFrame] = ++m_currentFenceValue;
        queue->Signal(m_fence, m_fenceValues[m_currentFrame]);
        
        m_currentFrame = (m_currentFrame + 1) % FRAME_COUNT;
    }
};
```

## 跨队列同步

```cpp
// Compute 队列完成后，Graphics 队列才能开始
ID3D12Fence* sharedFence;
UINT64 computeValue = 1;

// Compute 完成
computeQueue->Signal(sharedFence, computeValue);

// Graphics 等待
graphicsQueue->Wait(sharedFence, computeValue);
```

## 时间线 Fence

```cpp
// 创建时间线 Fence（D3D12 Fence 默认就是时间线）
// 可以多次 Signal 和 Wait
UINT64 timelineValue = 0;

// 多个提交点
for (int i = 0; i < 10; i++) {
    queue->ExecuteCommandLists(...);
    queue->Signal(fence, ++timelineValue);
}

// 等待特定点
WaitForFence(fence, 5);  // 等待第 5 个提交完成
```

## 相关文件

- [command-queue.md](./command-queue.md) - 命令队列
- [../design/synchronization-model.md](../design/synchronization-model.md) - 同步模型设计
