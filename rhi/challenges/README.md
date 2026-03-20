# RHI 常见挑战

本目录记录 RHI 开发中常见的挑战和解决方案。

## 文件说明

| 文件 | 内容 |
|------|------|
| `resource-aliasing.md` | 资源别名、内存复用 |
| `memory-fragmentation.md` | 内存碎片问题、分配器策略 |
| `synchronization-hazards.md` | 同步危害、数据竞争、死锁 |
| `multi-threading.md` | 多线程渲染、线程安全 |
| `performance-optimization.md` | 性能优化策略 |

## 常见问题概览

### 1. 资源管理挑战

```
问题：资源生命周期复杂，GPU 使用期间不能销毁
解决：延迟销毁队列、帧延迟管理
```

### 2. 内存管理挑战

```
问题：显存有限，资源碎片化
解决：内存池、资源别名、驻留管理
```

### 3. 同步挑战

```
问题：CPU-GPU 同步、跨队列同步复杂
解决：Fence、Semaphore、时间线同步
```

### 4. 多线程挑战

```
问题：多线程录制、资源创建竞争
解决：命令池、资源池、无锁数据结构
```

### 5. 性能挑战

```
问题：CPU 开销、GPU 空闲、内存带宽
解决：批处理、异步计算、资源压缩
```

## 学习路径

1. `resource-aliasing.md` - 理解资源别名
2. `memory-fragmentation.md` - 内存管理策略
3. `synchronization-hazards.md` - 同步问题
4. `multi-threading.md` - 多线程渲染
5. `performance-optimization.md` - 性能优化
