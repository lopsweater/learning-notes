# D3D12 设备创建

## 设备创建流程

```cpp
// 1. 启用调试层（Debug 模式）
#ifdef _DEBUG
ComPtr<ID3D12Debug> debugController;
if (SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&debugController)))) {
    debugController->EnableDebugLayer();
}
#endif

// 2. 创建 Factory
ComPtr<IDXGIFactory4> factory;
CreateDXGIFactory1(IID_PPV_ARGS(&factory));

// 3. 枚举适配器
ComPtr<IDXGIAdapter1> adapter;
for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; i++) {
    DXGI_ADAPTER_DESC1 desc;
    adapter->GetDesc1(&desc);
    
    // 跳过软件适配器
    if (desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE) {
        continue;
    }
    
    // 检查是否支持 D3D12
    if (SUCCEEDED(D3D12CreateDevice(adapter.Get(), D3D12_FEATURE_LEVEL_12_0, 
                                     _uuidof(ID3D12Device), nullptr))) {
        break;
    }
}

// 4. 创建设备
ComPtr<ID3D12Device> device;
D3D12CreateDevice(adapter.Get(), D3D12_FEATURE_LEVEL_12_0, 
                  IID_PPV_ARGS(&device));

// 5. 配置调试消息（可选）
ComPtr<ID3D12InfoQueue> infoQueue;
if (SUCCEEDED(device->QueryInterface(IID_PPV_ARGS(&infoQueue)))) {
    // 设置消息严重性
    infoQueue->SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_ERROR, TRUE);
    infoQueue->SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_CORRUPTION, TRUE);
    
    // 抑制特定消息
    D3D12_MESSAGE_ID suppress[] = {
        D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
    };
    D3D12_INFO_QUEUE_FILTER filter = {};
    filter.DenyList.NumIDs = _countof(suppress);
    filter.DenyList.pIDList = suppress;
    infoQueue->AddStorageFilterEntries(&filter);
}
```

## 特性检查

```cpp
// 检查特性支持
D3D12_FEATURE_DATA_ROOT_SIGNATURE rootSigFeature = {};
rootSigFeature.HighestVersion = D3D_ROOT_SIGNATURE_VERSION_1_1;
device->CheckFeatureSupport(D3D12_FEATURE_ROOT_SIGNATURE, 
                            &rootSigFeature, sizeof(rootSigFeature));

// 检查渲染目标格式
D3D12_FEATURE_DATA_FORMAT_SUPPORT formatSupport = {};
formatSupport.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
device->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, 
                           &formatSupport, sizeof(formatSupport));

// 检查多采样支持
D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS msaaLevels = {};
msaaLevels.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
msaaLevels.SampleCount = 4;
device->CheckFeatureSupport(D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS, 
                           &msaaLevels, sizeof(msaaLevels));
```

## 相关文件

- [overview.md](./overview.md) - 架构概览
- [command-queue.md](./command-queue.md) - 命令队列创建
