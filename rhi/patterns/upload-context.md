# 上传上下文

## 概述

上传上下文用于管理 CPU 到 GPU 的数据传输，使用 Staging Buffer 实现高效上传。

## 上传策略

### 1. 直接上传（小数据）

```cpp
// 小数据直接通过 Constant Buffer 上传
void UploadConstants(RHICommandList* cmdList, const void* data, size_t size) {
    auto allocation = m_constantBufferAllocator->Allocate(size, 256);
    memcpy(allocation.cpuPtr, data, size);
    
    cmdList->SetConstantBuffer(rootIndex, allocation.gpuAddress);
}
```

### 2. Staging Buffer（大数据）

```cpp
// 使用 Staging Buffer 上传
void UploadBuffer(RHIBuffer* dst, const void* data, size_t size) {
    // 创建 Staging Buffer
    BufferDesc stagingDesc = {
        size, 0, 
        BufferUsage::CopySrc, 
        MemoryType::Upload
    };
    RHIBuffer* staging = m_device->CreateBuffer(stagingDesc);
    
    // 复制数据到 Staging Buffer
    void* mapped = staging->Map();
    memcpy(mapped, data, size);
    staging->Unmap();
    
    // GPU 复制
    m_cmdList->CopyBuffer(dst, staging);
    
    // 延迟销毁 Staging Buffer
    m_deletionQueue->Enqueue(staging);
}
```

## 上传上下文设计

```cpp
class UploadContext {
    RHIDevice* m_device;
    RHICommandQueue* m_copyQueue;
    RHICommandList* m_cmdList;
    RHIFence* m_fence;
    
    LinearAllocator m_stagingAllocator;
    std::vector<UploadTask> m_pendingUploads;
    
public:
    // 上传 Buffer
    void UploadBuffer(RHIBuffer* dst, const void* data, size_t size, size_t offset = 0) {
        // 分配 Staging 内存
        auto allocation = m_stagingAllocator.Allocate(size, 256);
        memcpy(allocation.cpuPtr, data, size);
        
        // 记录上传任务
        m_pendingUploads.push_back({
            dst, allocation.buffer, allocation.offset, size, offset
        });
    }
    
    // 上传 Texture
    void UploadTexture(RHITexture* dst, const void* data, 
                       const TextureCopyRegion& region) {
        size_t rowPitch = region.width * GetPixelSize(dst->GetFormat());
        size_t slicePitch = rowPitch * region.height;
        size_t totalSize = slicePitch * region.depth;
        
        auto allocation = m_stagingAllocator.Allocate(totalSize, 512);
        
        // 复制数据（考虑行对齐）
        uint8_t* dstPtr = allocation.cpuPtr;
        const uint8_t* srcPtr = (const uint8_t*)data;
        for (uint32_t z = 0; z < region.depth; z++) {
            for (uint32_t y = 0; y < region.height; y++) {
                memcpy(dstPtr, srcPtr, rowPitch);
                dstPtr += allocation.rowPitch;
                srcPtr += rowPitch;
            }
        }
        
        m_pendingUploads.push_back({
            dst, allocation.buffer, allocation.offset, region
        });
    }
    
    // 提交所有上传
    void Submit() {
        if (m_pendingUploads.empty()) return;
        
        m_cmdList->Open();
        
        for (const auto& task : m_pendingUploads) {
            if (task.type == UploadType::Buffer) {
                m_cmdList->CopyBufferRegion(
                    task.dstBuffer, task.dstOffset,
                    task.stagingBuffer, task.stagingOffset,
                    task.size
                );
            } else {
                m_cmdList->CopyBufferToTexture(
                    task.dstTexture, task.stagingBuffer,
                    task.stagingOffset, task.region
                );
            }
        }
        
        m_cmdList->Close();
        m_copyQueue->Submit(&m_cmdList, 1, m_fence);
        
        m_pendingUploads.clear();
    }
    
    // 等待完成
    void Wait() {
        m_fence->Wait(m_fence->GetCompletedValue() + 1);
        m_stagingAllocator.Reset();
    }
};
```

## 线性分配器

```cpp
class StagingBufferAllocator {
    struct Block {
        RHIBuffer* buffer;
        uint8_t* mappedPtr;
        uint64_t capacity;
        uint64_t used;
    };
    
    std::vector<Block> m_blocks;
    size_t m_blockSize;
    
public:
    Allocation Allocate(size_t size, size_t alignment) {
        // 查找有空闲空间的 Block
        for (auto& block : m_blocks) {
            size_t alignedOffset = AlignUp(block.used, alignment);
            if (alignedOffset + size <= block.capacity) {
                Allocation alloc;
                alloc.buffer = block.buffer;
                alloc.offset = alignedOffset;
                alloc.cpuPtr = block.mappedPtr + alignedOffset;
                block.used = alignedOffset + size;
                return alloc;
            }
        }
        
        // 创建新 Block
        Block newBlock;
        newBlock.capacity = std::max(m_blockSize, size);
        newBlock.used = 0;
        
        BufferDesc desc = {newBlock.capacity, 0, BufferUsage::CopySrc, MemoryType::Upload};
        newBlock.buffer = m_device->CreateBuffer(desc);
        newBlock.mappedPtr = (uint8_t*)newBlock.buffer->Map();
        
        m_blocks.push_back(newBlock);
        return Allocate(size, alignment);
    }
    
    void Reset() {
        for (auto& block : m_blocks) {
            block.used = 0;
        }
    }
};
```

## 多队列上传

```cpp
// 使用专用 Copy Queue 上传
class CopyQueueUploader {
    RHICommandQueue* m_copyQueue;
    UploadContext* m_uploadContext;
    
public:
    void UploadAsync(RHIBuffer* dst, const void* data, size_t size) {
        m_uploadContext->UploadBuffer(dst, data, size);
        m_uploadContext->Submit();
    }
    
    void WaitForCompletion() {
        m_uploadContext->Wait();
    }
};

// 主队列同步
void SyncWithCopyQueue() {
    // Copy Queue Signal
    m_copyFence->Signal(m_copyFenceValue);
    
    // Graphics Queue Wait
    m_graphicsQueue->Wait(m_copyFence, m_copyFenceValue);
}
```

## 最佳实践

### ✅ 推荐

1. **批量上传** - 减少提交次数
2. **使用 Copy Queue** - 与渲染并行
3. **复用 Staging Buffer** - 减少分配
4. **异步上传** - 不阻塞主线程

### ❌ 避免

1. **每资源单独上传** - 性能差
2. **阻塞等待** - GPU 空闲
3. **过度分配 Staging Buffer** - 内存浪费

## 相关文件

- [resource-pool.md](./resource-pool.md) - 资源池模式
- [deferred-destruction.md](./deferred-destruction.md) - 延迟销毁
