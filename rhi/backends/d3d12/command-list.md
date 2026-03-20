# D3D12 命令列表

## 创建命令列表

```cpp
// 创建命令分配器
ID3D12CommandAllocator* allocator;
device->CreateCommandAllocator(
    D3D12_COMMAND_LIST_TYPE_DIRECT,
    IID_PPV_ARGS(&allocator)
);

// 创建命令列表
ID3D12GraphicsCommandList* commandList;
device->CreateCommandList(
    0,                                  // Node mask
    D3D12_COMMAND_LIST_TYPE_DIRECT,     // 类型
    allocator,                          // 分配器
    nullptr,                            // 初始 PSO（可选）
    IID_PPV_ARGS(&commandList)
);
```

## 命令录制流程

```cpp
// 1. 重置命令列表
commandList->Reset(allocator, nullptr);

// 2. 设置状态
commandList->SetGraphicsRootSignature(rootSignature);
commandList->SetPipelineState(pso);
commandList->SetDescriptorHeaps(1, &descriptorHeap);

// 3. 设置资源
commandList->SetGraphicsRootDescriptorTable(0, gpuHandle);
commandList->IASetVertexBuffers(0, 1, &vertexBufferView);
commandList->IASetIndexBuffer(&indexBufferView);
commandList->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

// 4. 设置渲染目标
commandList->OMSetRenderTargets(1, &rtvHandle, FALSE, &dsvHandle);

// 5. 清除
float clearColor[] = { 0.0f, 0.2f, 0.4f, 1.0f };
commandList->ClearRenderTargetView(rtvHandle, clearColor, 0, nullptr);
commandList->ClearDepthStencilView(dsvHandle, 
    D3D12_CLEAR_FLAG_DEPTH | D3D12_CLEAR_FLAG_STENCIL, 1.0f, 0, 0, nullptr);

// 6. 设置视口和裁剪
CD3DX12_VIEWPORT viewport(0.0f, 0.0f, 1920.0f, 1080.0f);
CD3DX12_RECT scissor(0, 0, 1920, 1080);
commandList->RSSetViewports(1, &viewport);
commandList->RSSetScissorRects(1, &scissor);

// 7. 绘制
commandList->DrawIndexedInstanced(indexCount, 1, 0, 0, 0);

// 8. 关闭命令列表
commandList->Close();
```

## 命令分配器复用

```cpp
// 分配器必须在 GPU 完成使用后才能重置
// 使用 Fence 同步

void ResetAllocator(ID3D12CommandAllocator* allocator, ID3D12Fence* fence, 
                    UINT64 expectedValue) {
    if (fence->GetCompletedValue() >= expectedValue) {
        allocator->Reset();
    } else {
        // 等待 GPU 完成
        HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
        fence->SetEventOnCompletion(expectedValue, event);
        WaitForSingleObject(event, INFINITE);
        CloseHandle(event);
        allocator->Reset();
    }
}
```

## 多命令列表

```cpp
// 使用多个命令分配器
std::vector<ComPtr<ID3D12CommandAllocator>> allocators(FRAME_COUNT);
for (auto& allocator : allocators) {
    device->CreateCommandAllocator(
        D3D12_COMMAND_LIST_TYPE_DIRECT,
        IID_PPV_ARGS(&allocator)
    );
}

// 每帧使用不同分配器
UINT frameIndex = currentFrame % FRAME_COUNT;
commandList->Reset(allocators[frameIndex].Get(), nullptr);
```

## Bundle 命令列表

```cpp
// 创建 Bundle 分配器
ID3D12CommandAllocator* bundleAllocator;
device->CreateCommandAllocator(
    D3D12_COMMAND_LIST_TYPE_BUNDLE,
    IID_PPV_ARGS(&bundleAllocator)
);

// 创建 Bundle
ID3D12GraphicsCommandList* bundle;
device->CreateCommandList(
    0,
    D3D12_COMMAND_LIST_TYPE_BUNDLE,
    bundleAllocator,
    nullptr,
    IID_PPV_ARGS(&bundle)
);

// 录制 Bundle（只需一次）
bundle->SetPipelineState(pso);
bundle->SetGraphicsRootSignature(rootSignature);
bundle->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
bundle->DrawInstanced(3, 1, 0, 0);
bundle->Close();

// 执行 Bundle
commandList->ExecuteBundle(bundle);
```

## 相关文件

- [command-queue.md](./command-queue.md) - 命令队列
- [synchronization.md](./synchronization.md) - 同步机制
