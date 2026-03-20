# D3D12 资源屏障

## 屏障类型

```cpp
enum D3D12_RESOURCE_BARRIER_TYPE {
    D3D12_RESOURCE_BARRIER_TYPE_TRANSITION,  // 状态转换
    D3D12_RESOURCE_BARRIER_TYPE_ALIASING,    // 资源别名
    D3D12_RESOURCE_BARRIER_TYPE_UAV,         // UAV 同步
};
```

## 状态转换屏障

```cpp
// 单个资源转换
CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Transition(
    texture,
    D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
    D3D12_RESOURCE_STATE_RENDER_TARGET
);
commandList->ResourceBarrier(1, &barrier);

// 批量转换
CD3DX12_RESOURCE_BARRIER barriers[3] = {
    CD3DX12_RESOURCE_BARRIER::Transition(tex0, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_RENDER_TARGET),
    CD3DX12_RESOURCE_BARRIER::Transition(tex1, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_DEPTH_WRITE),
    CD3DX12_RESOURCE_BARRIER::Transition(buffer, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_VERTEX_BUFFER),
};
commandList->ResourceBarrier(3, barriers);
```

## 资源状态

| 状态 | 用途 |
|------|------|
| COMMON | 通用状态 |
| VERTEX_BUFFER | 顶点缓冲 |
| INDEX_BUFFER | 索引缓冲 |
| CONSTANT_BUFFER | 常量缓冲 |
| VERTEX_AND_CONSTANT_BUFFER | 顶点和常量缓冲 |
| SHADER_RESOURCE | 着色器资源 |
| UNORDERED_ACCESS | UAV |
| RENDER_TARGET | 渲染目标 |
| DEPTH_WRITE | 深度写入 |
| DEPTH_READ | 深度读取 |
| COPY_SOURCE | 复制源 |
| COPY_DEST | 复制目标 |
| PRESENT | 呈现 |
| INDIRECT_ARGUMENT | 间接参数 |

## UAV 屏障

```cpp
// 确保 UAV 写入完成后再读取
CD3DX12_RESOURCE_BARRIER uavBarrier = 
    CD3DX12_RESOURCE_BARRIER::UAV(buffer);
commandList->ResourceBarrier(1, &uavBarrier);
```

## 别名屏障

```cpp
// 资源别名转换
CD3DX12_RESOURCE_BARRIER aliasBarrier = 
    CD3DX12_RESOURCE_BARRIER::Aliasing(nullptr, textureB);
commandList->ResourceBarrier(1, &aliasBarrier);
```

## 分离屏障（D3D12+）

```cpp
// 分离的开始和结束屏障
CD3DX12_RESOURCE_BARRIER beginBarrier = 
    CD3DX12_RESOURCE_BARRIER::Transition(
        texture,
        D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
        D3D12_RESOURCE_STATE_RENDER_TARGET,
        D3D12_RESOURCE_BARRIER_FLAG_BEGIN_ONLY
    );

CD3DX12_RESOURCE_BARRIER endBarrier = 
    CD3DX12_RESOURCE_BARRIER::Transition(
        texture,
        D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
        D3D12_RESOURCE_STATE_RENDER_TARGET,
        D3D12_RESOURCE_BARRIER_FLAG_END_ONLY
    );

// 可以在中间执行其他操作
commandList->ResourceBarrier(1, &beginBarrier);
// ... 其他 GPU 工作 ...
commandList->ResourceBarrier(1, &endBarrier);
```

## 最佳实践

### ✅ 推荐

1. **批量提交屏障** - 减少 API 调用
2. **合并相同转换** - 多个资源同时转换
3. **使用分离屏障** - 允许 GPU 重叠工作

### ❌ 避免

1. **每操作后立即屏障** - 性能差
2. **冗余屏障** - 相同状态的转换
3. **忽略子资源** - 部分 mip 可能状态不同

## 相关文件

- [resources.md](./resources.md) - 资源管理
- [state-tracking.md](../patterns/state-tracking.md) - 状态追踪模式
