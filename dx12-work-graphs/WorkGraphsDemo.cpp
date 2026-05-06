// cl WorkGraphsDemo.cpp d3d12.lib dxgi.lib dxcompiler.lib
#include <windows.h>
#include <stdio.h>
#include <d3d12.h>
#include <dxcapi.h>
#include <dxgi1_6.h>

extern "C" { __declspec(dllexport) extern const UINT D3D12SDKVersion = 613; }
extern "C" { __declspec(dllexport) extern const char* D3D12SDKPath = ".\\"; }

static const char NodeShader[] =
	"RWByteAddressBuffer _RWByteAddressBuffer : register(u0);"
	"[Shader(\"node\")]"
	"[NodeLaunch(\"broadcasting\")]"
	"[NodeDispatchGrid(1, 1, 1)]"
	"[NumThreads(1, 1, 1)]"
	"void TestNode()"
	"{"
	"	_RWByteAddressBuffer.Store4(0, uint4(0x6B726F57, 0x61724720, 0x44206870, 0x006F6D65));"
	"}";

int main()
{
	const int size = 1024;
	const wchar_t* programName = L"WorkGraphDemo";
	IDXGIFactory4* factory;
	CreateDXGIFactory2(0, IID_PPV_ARGS(&factory));
	IDXGIAdapter1* adapter;
	for (int i = 0;; i++)
	{
		factory->EnumAdapters1(i, &adapter);
		DXGI_ADAPTER_DESC1 adapterDesc;
		adapter->GetDesc1(&adapterDesc);
		if (wcscmp(adapterDesc.Description, L"Microsoft Basic Render Driver") == 0)
		{
			break;
		}
	}
	ID3D12Device9* device;
	D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_11_0, IID_PPV_ARGS(&device));
	HMODULE hModule = LoadLibraryW(L"dxcompiler.dll");
	DxcCreateInstanceProc createInstanceProc = (DxcCreateInstanceProc)GetProcAddress(hModule, "DxcCreateInstance");
	IDxcUtils* utils;
	IDxcCompiler* compiler;
	IDxcBlobEncoding* blobEncoding;
	IDxcOperationResult* operationResult;
	createInstanceProc(CLSID_DxcUtils, IID_PPV_ARGS(&utils));
	createInstanceProc(CLSID_DxcCompiler, IID_PPV_ARGS(&compiler));
	utils->CreateBlob(NodeShader, sizeof(NodeShader), 0, &blobEncoding);
	compiler->Compile(blobEncoding, 0, 0, L"lib_6_8", 0, 0, 0, 0, 0, &operationResult);
	ID3DBlob* library;	
	operationResult->GetResult((IDxcBlob**)&library);
	ID3D12RootSignature* rootSignature;
	D3D12_ROOT_PARAMETER rootParameter = {};
	rootParameter.ParameterType = D3D12_ROOT_PARAMETER_TYPE_UAV;
	rootParameter.Descriptor.ShaderRegister = 0;
	rootParameter.Descriptor.RegisterSpace = 0;
	rootParameter.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
	D3D12_ROOT_SIGNATURE_DESC rootSignatureDesc = {1, &rootParameter, 0, 0, D3D12_ROOT_SIGNATURE_FLAG_NONE};
	ID3DBlob* blob;
	D3D12SerializeRootSignature(&rootSignatureDesc, D3D_ROOT_SIGNATURE_VERSION_1, &blob, 0);
	device->CreateRootSignature(0, blob->GetBufferPointer(), blob->GetBufferSize(), IID_PPV_ARGS(&rootSignature));
	ID3D12StateObject* stateObject;
	D3D12_STATE_SUBOBJECT subobjects[3];
	D3D12_SHADER_BYTECODE shaderByteCode = {library->GetBufferPointer(), library->GetBufferSize()};	
	D3D12_DXIL_LIBRARY_DESC dxilLibraryDesc = { shaderByteCode, 0, 0 };
	subobjects[0].Type = D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY;
	subobjects[0].pDesc = &dxilLibraryDesc;
	D3D12_GLOBAL_ROOT_SIGNATURE globalRootSignature = {rootSignature};
	subobjects[1].Type = D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_ROOT_SIGNATURE;
	subobjects[1].pDesc = &globalRootSignature;
	D3D12_WORK_GRAPH_DESC workGraphDesc = { programName, D3D12_WORK_GRAPH_FLAG_INCLUDE_ALL_AVAILABLE_NODES, 0, 0, 0, 0 };
	subobjects[2].Type = D3D12_STATE_SUBOBJECT_TYPE_WORK_GRAPH;
	subobjects[2].pDesc = &workGraphDesc;
	D3D12_STATE_OBJECT_DESC stateObjectDesc = {D3D12_STATE_OBJECT_TYPE_EXECUTABLE, _countof(subobjects), subobjects};
	device->CreateStateObject(&stateObjectDesc, IID_PPV_ARGS(&stateObject));
	ID3D12StateObjectProperties1* stateObjectProperties;
	ID3D12WorkGraphProperties* workGraphProperties;
	stateObject->QueryInterface(IID_PPV_ARGS(&stateObjectProperties));
	stateObject->QueryInterface(IID_PPV_ARGS(&workGraphProperties));
	UINT index = workGraphProperties->GetWorkGraphIndex(programName);
	D3D12_WORK_GRAPH_MEMORY_REQUIREMENTS memoryRequirements = {};
	workGraphProperties->GetWorkGraphMemoryRequirements(index, &memoryRequirements);
	ID3D12Resource* resource1;
	D3D12_HEAP_PROPERTIES heapProperties1 = {D3D12_HEAP_TYPE_DEFAULT, D3D12_CPU_PAGE_PROPERTY_UNKNOWN, D3D12_MEMORY_POOL_UNKNOWN, 1, 1 };
	D3D12_RESOURCE_FLAGS resourceFlagsUAV = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
	D3D12_RESOURCE_DIMENSION dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	D3D12_TEXTURE_LAYOUT layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	D3D12_RESOURCE_DESC resourceDesc1 = {dimension, 0, memoryRequirements.MaxSizeInBytes, 1, 1, 1, DXGI_FORMAT_UNKNOWN, {1, 0}, layout, resourceFlagsUAV};
	device->CreateCommittedResource(&heapProperties1, D3D12_HEAP_FLAG_NONE, &resourceDesc1, D3D12_RESOURCE_STATE_COMMON, 0, IID_PPV_ARGS(&resource1));
	ID3D12Resource* resource2;
	D3D12_HEAP_PROPERTIES heapProperties2 = { D3D12_HEAP_TYPE_DEFAULT, D3D12_CPU_PAGE_PROPERTY_UNKNOWN, D3D12_MEMORY_POOL_UNKNOWN, 1, 1 };
	D3D12_RESOURCE_DESC resourceDesc2 = {dimension, 0, size, 1, 1, 1, DXGI_FORMAT_UNKNOWN, {1, 0}, layout, resourceFlagsUAV };
	device->CreateCommittedResource(&heapProperties2, D3D12_HEAP_FLAG_NONE, &resourceDesc2, D3D12_RESOURCE_STATE_COMMON, 0, IID_PPV_ARGS(&resource2));
	ID3D12Resource* resource3;
	D3D12_HEAP_PROPERTIES heapProperties3 = {D3D12_HEAP_TYPE_READBACK, D3D12_CPU_PAGE_PROPERTY_UNKNOWN, D3D12_MEMORY_POOL_UNKNOWN, 1, 1};
	D3D12_RESOURCE_DESC resourceDesc3 = {dimension, 0, size, 1, 1, 1, DXGI_FORMAT_UNKNOWN, {1, 0}, layout, D3D12_RESOURCE_FLAG_NONE };
	device->CreateCommittedResource(&heapProperties3, D3D12_HEAP_FLAG_NONE, &resourceDesc3, D3D12_RESOURCE_STATE_COMMON, 0, IID_PPV_ARGS(&resource3));
	UINT test = workGraphProperties->GetNumEntrypoints(index);
	D3D12_SET_PROGRAM_DESC setProgramDesc = {};
	setProgramDesc.Type = D3D12_PROGRAM_TYPE_WORK_GRAPH;
	setProgramDesc.WorkGraph.ProgramIdentifier = stateObjectProperties->GetProgramIdentifier(programName);
	setProgramDesc.WorkGraph.Flags = D3D12_SET_WORK_GRAPH_FLAG_INITIALIZE;
	setProgramDesc.WorkGraph.BackingMemory = {resource1->GetGPUVirtualAddress(), memoryRequirements.MaxSizeInBytes};
	ID3D12CommandQueue* commandQueue;
	ID3D12CommandAllocator* commandAllocator;
	ID3D12GraphicsCommandList10* commandList;
	ID3D12Fence* fence;
	D3D12_COMMAND_QUEUE_DESC commandQueueDesc = { D3D12_COMMAND_LIST_TYPE_DIRECT, 0, D3D12_COMMAND_QUEUE_FLAG_DISABLE_GPU_TIMEOUT, 0};
	device->CreateCommandQueue(&commandQueueDesc, IID_PPV_ARGS(&commandQueue));
	device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commandAllocator));
	device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commandAllocator, nullptr, IID_PPV_ARGS(&commandList));
	device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));
	D3D12_DISPATCH_GRAPH_DESC dispatchGraphDesc = {D3D12_DISPATCH_MODE_NODE_CPU_INPUT, {0, 1}};
	commandList->SetComputeRootSignature(rootSignature);
	commandList->SetComputeRootUnorderedAccessView(0, resource2->GetGPUVirtualAddress());
	commandList->SetProgram(&setProgramDesc);
	commandList->DispatchGraph(&dispatchGraphDesc);
	D3D12_RESOURCE_BARRIER_TYPE barrierType = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	D3D12_RESOURCE_BARRIER_FLAGS barrierFlags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
	D3D12_RESOURCE_BARRIER barrier = {barrierType, barrierFlags, {resource2, 0, D3D12_RESOURCE_STATE_UNORDERED_ACCESS, D3D12_RESOURCE_STATE_COPY_SOURCE}};
	commandList->ResourceBarrier(1, &barrier);
	commandList->CopyResource(resource3, resource2);
	commandList->Close();
	commandQueue->ExecuteCommandLists(1, reinterpret_cast<ID3D12CommandList* const*>(&commandList));
	commandQueue->Signal(fence, 1);
	HANDLE handle = CreateEvent(0, FALSE, FALSE, 0);
	fence->SetEventOnCompletion(1, handle);
	DWORD waitForSingleObject = WaitForSingleObject(handle, INFINITE);
	CloseHandle(handle);
	if (waitForSingleObject == WAIT_OBJECT_0 && SUCCEEDED(device->GetDeviceRemovedReason()))
	{
		commandAllocator->Reset();
		commandList->Reset(commandAllocator, 0);
	}
	char* output;
	D3D12_RANGE range{0, size};
	resource3->Map(0, &range, (void**)&output);
	char result[size / sizeof(char)];
	memcpy(result, output, size);
	resource3->Unmap(0, 0);
	printf("Expected: Work Graph Demo\nResult: %s\nPress any key to continue...\n", result);
	FreeLibrary(hModule);
	return 0;
}