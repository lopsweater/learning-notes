# D3D12 命令队列

## 命令队列类型

```cpp
enum D3D12_COMMAND_LIST_TYPE {
    D3D12_COMMAND_LIST_TYPE_DIRECT   = 0,  // 图形、计算、复制
    D3D12_COMMAND_LIST_TYPE_COMPUTE  = 1,  // 计算、复制
    D3D12_COMMAND_LIST_TYPE_COPY     = 2,  // 仅复制
    D3D12_COMMAND_LIST_TYPE_BUNDLE   = 3,  // Bundle
};
```

## 创建命令队列

```cpp
// 创建 Graphics 队列
D3D12_COMMAND_QUEUE_DESC queueDesc = {};
queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
queueDesc.Priority = D3D12_COMMAND_QUEUE_PRIORITY_NORMAL;
queueDesc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
queueDesc.NodeMask = 0;

ID3D12CommandQueue* graphicsQueue;
device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&graphicsQueue));

// 创建 Compute 队列
queueDesc.Type = D3D12_COMMAND_LIST_TYPE_COMPUTE;
ID3D12CommandQueue* computeQueue;
device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&computeQueue));

// 创建 Copy 队列
queueDesc.Type = D3D12_COMMAND_LIST_TYPE_COPY;
ID3D12CommandQueue* copyQueue;
device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&copyQueue));
```

## 提交命令列表

```cpp
// 创建命令分配器
ID3D12CommandAllocator* allocator;
device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, 
                               IID_PPV_ARGS(&allocator));

// 创建命令列表
ID3D12GraphicsCommandList* commandList;
device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT,
                          allocator, nullptr, IID_PPV_ARGS(&commandList));

// 录制命令
commandList->SetPipelineState(pso);
commandList->DrawInstanced(3, 1, 0, 0);
commandList->Close();

// 提交
ID3D12CommandList* cmdLists[] = { commandList };
graphicsQueue->ExecuteCommandLists(1, cmdLists);
```

## 同步操作

```cpp
// 创建 Fence
ID3D12Fence* fence;
device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));
UINT64 fenceValue = 0;

// 提交并 Signal
graphicsQueue->Signal(fence, ++fenceValue);

// CPU 等待
if (fence->GetCompletedValue() < fenceValue) {
    HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    fence->SetEventOnCompletion(fenceValue, event);
    WaitForSingleObject(event, INFINITE);
    CloseHandle(event);
}

// 跨队列同步
computeQueue->Signal(fence, fenceValue);  // Compute 完成
graphicsQueue->Wait(fence, fenceValue);    // Graphics 等待
```

## 队列优先级

```cpp
// 高优先级队列（实时渲染）
queueDesc.Priority = D3D12_COMMAND_QUEUE_PRIORITY_HIGH;

// 全局实时优先级（最高优先级）
queueDesc.Priority = D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME;
```

## 相关文件

- [device.md](./device.md) - 设备创建
- [command-list.md](./command-list.md) - 命令列表
- [synchronization.md](./synchronization.md) - 同步机制
