# 游戏引擎多线程设计核心样例

## 目录

1. [跨线程内存同步基础](#1-跨线程内存同步基础)
2. [Task 系统设计](#2-task-系统设计)
3. [依赖关系处理](#3-依赖关系处理)
4. [渲染线程与逻辑线程同步](#4-渲染线程与逻辑线程同步)
5. [完整示例：帧同步架构](#5-完整示例帧同步架构)

---

## 1. 跨线程内存同步基础

### 1.1 内存屏障 (Memory Barrier)

```cpp
// ============================================
// 原子操作与内存序
// ============================================

#include <atomic>
#include <thread>

class SpinLock {
private:
    std::atomic<bool> locked{false};

public:
    void lock() {
        // memory_order_acquire: 确保后续读操作不会被重排到此之前
        while (locked.exchange(true, std::memory_order_acquire)) {
            // 自旋等待
            while (locked.load(std::memory_order_relaxed)) {
                std::this_thread::yield();
            }
        }
    }

    void unlock() {
        // memory_order_release: 确保之前的写操作不会被重排到此之后
        locked.store(false, std::memory_order_release);
    }
};

// 使用示例
SpinLock spinLock;
int sharedData = 0;

void thread1() {
    sharedData = 42;
    spinLock.unlock();  // release: 确保上面的写操作可见
}

void thread2() {
    spinLock.lock();    // acquire: 确保看到上面的写操作
    printf("%d\n", sharedData);  // 保证输出 42
}
```

### 1.2 双缓冲机制 (Double Buffering)

```cpp
// ============================================
// 双缓冲：无锁数据交换
// ============================================

template<typename T>
class DoubleBuffer {
private:
    T buffers[2];
    std::atomic<int> writeIndex{0};

public:
    // 写线程：获取写缓冲区
    T& getWriteBuffer() {
        return buffers[writeIndex.load(std::memory_order_relaxed)];
    }

    // 读线程：获取读缓冲区
    const T& getReadBuffer() {
        return buffers[1 - writeIndex.load(std::memory_order_acquire)];
    }

    // 写线程完成，切换缓冲区
    void swapBuffers() {
        // 确保所有写操作完成
        std::atomic_thread_fence(std::memory_order_release);
        writeIndex.store(1 - writeIndex.load(std::memory_order_relaxed),
                         std::memory_order_release);
    }
};

// 使用示例：游戏状态同步
struct GameState {
    std::vector<Entity> entities;
    Camera camera;
    float deltaTime;
};

DoubleBuffer<GameState> gameStateBuffer;

// 逻辑线程
void logicThread() {
    while (running) {
        auto& state = gameStateBuffer.getWriteBuffer();
        updateEntities(state.entities, state.deltaTime);
        gameStateBuffer.swapBuffers();  // 切换缓冲区
    }
}

// 渲染线程
void renderThread() {
    while (running) {
        const auto& state = gameStateBuffer.getReadBuffer();
        renderEntities(state.entities);
    }
}
```

### 1.3 环形缓冲区 (Ring Buffer)

```cpp
// ============================================
// 单生产者-单消费者 无锁队列
// ============================================

#include <atomic>
#include <vector>

template<typename T, size_t Capacity>
class SPSCQueue {
private:
    alignas(64) std::atomic<size_t> head{0};  // 读指针
    alignas(64) std::atomic<size_t> tail{0};  // 写指针
    std::vector<T> buffer;
    size_t mask;

public:
    SPSCQueue() : buffer(Capacity), mask(Capacity - 1) {
        static_assert((Capacity & (Capacity - 1)) == 0,
                      "Capacity must be power of 2");
    }

    // 生产者：写入
    bool push(const T& item) {
        size_t currentTail = tail.load(std::memory_order_relaxed);
        size_t nextTail = (currentTail + 1) & mask;

        if (nextTail == head.load(std::memory_order_acquire)) {
            return false;  // 队列满
        }

        buffer[currentTail] = item;

        // release 确保上面的写操作可见
        tail.store(nextTail, std::memory_order_release);
        return true;
    }

    // 消费者：读取
    bool pop(T& item) {
        size_t currentHead = head.load(std::memory_order_relaxed);

        if (currentHead == tail.load(std::memory_order_acquire)) {
            return false;  // 队列空
        }

        item = buffer[currentHead];

        // release 确保上面的读操作完成
        head.store((currentHead + 1) & mask, std::memory_order_release);
        return true;
    }
};

// 使用示例：渲染命令队列
struct RenderCommand {
    enum Type { DrawMesh, SetMaterial, SetTransform };
    Type type;
    // ... 数据
};

SPSCQueue<RenderCommand, 4096> renderQueue;

// 逻辑线程：生产渲染命令
void submitRenderCommand(const RenderCommand& cmd) {
    while (!renderQueue.push(cmd)) {
        // 队列满，等待或丢弃
        std::this_thread::yield();
    }
}

// 渲染线程：消费渲染命令
void processRenderCommands() {
    RenderCommand cmd;
    while (renderQueue.pop(cmd)) {
        executeCommand(cmd);
    }
}
```

---

## 2. Task 系统设计

### 2.1 基础 Task 抽象

```cpp
// ============================================
// Task 基础接口
// ============================================

#include <functional>
#include <memory>
#include <vector>
#include <atomic>

class Task {
public:
    using Ptr = std::shared_ptr<Task>;
    using Callback = std::function<void()>;

private:
    Callback execute;
    std::atomic<int> dependencies{0};
    std::vector<Task::Ptr> successors;
    std::atomic<bool> completed{false};

public:
    Task(Callback func) : execute(std::move(func)) {}

    void addDependency() {
        dependencies.fetch_add(1, std::memory_order_relaxed);
    }

    void removeDependency() {
        if (dependencies.fetch_sub(1, std::memory_order_acq_rel) == 1) {
            // 所有依赖完成，可以执行
            schedule(this);
        }
    }

    void run() {
        execute();
        completed.store(true, std::memory_order_release);

        // 通知后续任务
        for (auto& successor : successors) {
            successor->removeDependency();
        }
    }

    void addSuccessor(Task::Ptr task) {
        successors.push_back(task);
        task->addDependency();
    }

    bool isCompleted() const {
        return completed.load(std::memory_order_acquire);
    }
};
```

### 2.2 线程池与任务队列

```cpp
// ============================================
// Work-Stealing 线程池
// ============================================

#include <thread>
#include <deque>
#include <mutex>
#include <condition_variable>

class ThreadPool {
private:
    struct Worker {
        std::deque<Task::Ptr> localQueue;
        std::mutex mutex;
        std::condition_variable cv;
        bool running = true;
    };

    std::vector<std::thread> threads;
    std::vector<std::unique_ptr<Worker>> workers;
    std::atomic<size_t> nextWorker{0};

public:
    ThreadPool(size_t numThreads) {
        for (size_t i = 0; i < numThreads; ++i) {
            auto worker = std::make_unique<Worker>();
            workers.push_back(worker.get());

            threads.emplace_back([this, worker = worker.get()] {
                workerThread(worker);
            });
        }
    }

    void submit(Task::Ptr task) {
        // 轮询分配到工作线程
        size_t index = nextWorker.fetch_add(1, std::memory_order_relaxed)
                       % workers.size();

        auto& worker = workers[index];
        {
            std::lock_guard<std::mutex> lock(worker->mutex);
            worker->localQueue.push_back(task);
        }
        worker->cv.notify_one();
    }

private:
    void workerThread(Worker* worker) {
        while (worker->running) {
            Task::Ptr task;

            // 从本地队列获取任务
            {
                std::unique_lock<std::mutex> lock(worker->mutex);
                worker->cv.wait(lock, [&] {
                    return !worker->localQueue.empty() || !worker->running;
                });

                if (!worker->localQueue.empty()) {
                    task = worker->localQueue.front();
                    worker->localQueue.pop_front();
                }
            }

            if (task) {
                task->run();
            } else {
                // 本地队列空，尝试偷取其他队列的任务
                task = stealTask(worker);
                if (task) {
                    task->run();
                }
            }
        }
    }

    Task::Ptr stealTask(Worker* thief) {
        for (auto& worker : workers) {
            if (worker == thief) continue;

            std::lock_guard<std::mutex> lock(worker->mutex);
            if (!worker->localQueue.empty()) {
                auto task = worker->localQueue.back();
                worker->localQueue.pop_back();
                return task;
            }
        }
        return nullptr;
    }
};
```

### 2.3 并行 For 循环

```cpp
// ============================================
// ParallelFor 实现
// ============================================

class ParallelFor {
private:
    ThreadPool& pool;
    std::atomic<int> remainingTasks{0};
    std::mutex mutex;
    std::condition_variable cv;

public:
    ParallelFor(ThreadPool& p) : pool(p) {}

    template<typename Func>
    void execute(size_t begin, size_t end, size_t batchSize, Func func) {
        size_t total = end - begin;
        size_t numTasks = (total + batchSize - 1) / batchSize;
        remainingTasks = numTasks;

        for (size_t i = 0; i < numTasks; ++i) {
            size_t taskBegin = begin + i * batchSize;
            size_t taskEnd = std::min(taskBegin + batchSize, end);

            auto task = std::make_shared<Task>([&, taskBegin, taskEnd] {
                for (size_t j = taskBegin; j < taskEnd; ++j) {
                    func(j);
                }

                if (remainingTasks.fetch_sub(1, std::memory_order_acq_rel) == 1) {
                    std::lock_guard<std::mutex> lock(mutex);
                    cv.notify_all();
                }
            });

            pool.submit(task);
        }

        // 等待所有任务完成
        std::unique_lock<std::mutex> lock(mutex);
        cv.wait(lock, [&] { return remainingTasks == 0; });
    }
};

// 使用示例：更新大量实体
void updateEntities(std::vector<Entity>& entities) {
    ThreadPool pool(8);
    ParallelFor parallel(pool);

    parallel.execute(0, entities.size(), 100, [&](size_t i) {
        entities[i].update();
    });
}
```

---

## 3. 依赖关系处理

### 3.1 基于计数器的依赖

```cpp
// ============================================
// 任务依赖计数器
// ============================================

class TaskCounter {
private:
    std::atomic<int> count{0};
    std::vector<Task::Ptr> waitingTasks;
    std::mutex mutex;

public:
    void set(int value) {
        count.store(value, std::memory_order_release);
    }

    void decrement() {
        if (count.fetch_sub(1, std::memory_order_acq_rel) == 1) {
            // 计数归零，唤醒等待的任务
            std::lock_guard<std::mutex> lock(mutex);
            for (auto& task : waitingTasks) {
                task->removeDependency();
            }
            waitingTasks.clear();
        }
    }

    void waitFor(Task::Ptr task) {
        if (count.load(std::memory_order_acquire) > 0) {
            std::lock_guard<std::mutex> lock(mutex);
            waitingTasks.push_back(task);
            task->addDependency();
        }
    }
};

// 使用示例：等待多个任务完成
void example() {
    ThreadPool pool(4);
    TaskCounter counter;

    counter.set(3);  // 3 个前置任务

    auto task1 = std::make_shared<Task>([&] {
        doWork1();
        counter.decrement();
    });

    auto task2 = std::make_shared<Task>([&] {
        doWork2();
        counter.decrement();
    });

    auto task3 = std::make_shared<Task>([&] {
        doWork3();
        counter.decrement();
    });

    auto finalTask = std::make_shared<Task>([] {
        finalWork();
    });

    counter.waitFor(finalTask);

    pool.submit(task1);
    pool.submit(task2);
    pool.submit(task3);
    pool.submit(finalTask);
}
```

### 3.2 任务图 (DAG)

```cpp
// ============================================
// 任务依赖图
// ============================================

#include <unordered_map>
#include <unordered_set>

class TaskGraph {
private:
    struct Node {
        Task::Ptr task;
        std::vector<std::string> dependencies;
        std::vector<std::string> dependents;
    };

    std::unordered_map<std::string, Node> nodes;
    ThreadPool& pool;

public:
    TaskGraph(ThreadPool& p) : pool(p) {}

    void addTask(const std::string& name, Task::Ptr task,
                 const std::vector<std::string>& deps = {}) {
        Node node;
        node.task = task;
        node.dependencies = deps;

        for (const auto& dep : deps) {
            nodes[dep].dependents.push_back(name);
        }

        nodes[name] = std::move(node);
    }

    void execute() {
        // 计算每个任务的依赖数量
        std::unordered_map<std::string, std::atomic<int>> depCount;
        for (auto& [name, node] : nodes) {
            depCount[name] = node.dependencies.size();
        }

        // 找出无依赖的任务，开始执行
        for (auto& [name, node] : nodes) {
            if (node.dependencies.empty()) {
                scheduleTask(name, depCount);
            }
        }
    }

private:
    void scheduleTask(const std::string& name,
                      std::unordered_map<std::string, std::atomic<int>>& depCount) {
        auto& node = nodes[name];

        auto wrapper = std::make_shared<Task>([&, name] {
            node.task->run();

            // 通知依赖此任务的其他任务
            for (const auto& dependent : node.dependents) {
                if (--depCount[dependent] == 0) {
                    scheduleTask(dependent, depCount);
                }
            }
        });

        pool.submit(wrapper);
    }
};

// 使用示例
void buildFrameTasks(TaskGraph& graph) {
    graph.addTask("physics", std::make_shared<Task>(physicsUpdate));
    graph.addTask("animation", std::make_shared<Task>(animationUpdate));
    graph.addTask("ai", std::make_shared<Task>(aiUpdate));

    // 渲染准备依赖物理和动画
    graph.addTask("prepare_render",
                  std::make_shared<Task>(prepareRender),
                  {"physics", "animation"});

    // 渲染命令生成依赖渲染准备
    graph.addTask("render_commands",
                  std::make_shared<Task>(generateRenderCommands),
                  {"prepare_render"});

    // 音频独立执行
    graph.addTask("audio", std::make_shared<Task>(audioUpdate));

    graph.execute();
}
```

---

## 4. 渲染线程与逻辑线程同步

### 4.1 帧同步策略

```cpp
// ============================================
// 帧同步管理器
// ============================================

class FrameSynchronizer {
private:
    // 帧数据缓冲区（三缓冲）
    struct FrameData {
        std::vector<RenderCommand> commands;
        std::vector<Matrix4> transforms;
        CameraData camera;
        std::atomic<bool> ready{false};
    };

    FrameData frames[3];
    std::atomic<int> logicFrameIndex{0};  // 逻辑线程正在写入的帧
    std::atomic<int> renderFrameIndex{0}; // 渲染线程正在读取的帧

    std::atomic<int> logicFrameNumber{0};
    std::atomic<int> renderedFrameNumber{0};

    std::mutex syncMutex;
    std::condition_variable logicCV;
    std::condition_variable renderCV;

public:
    // 逻辑线程：开始新帧
    FrameData& beginLogicFrame() {
        // 等待渲染线程至少落后 2 帧（三缓冲）
        while (logicFrameNumber - renderedFrameNumber >= 2) {
            std::unique_lock<std::mutex> lock(syncMutex);
            logicCV.wait(lock);
        }

        return frames[logicFrameIndex.load(std::memory_order_acquire)];
    }

    // 逻辑线程：结束帧
    void endLogicFrame() {
        int index = logicFrameIndex.load(std::memory_order_acquire);
        frames[index].ready.store(true, std::memory_order_release);

        logicFrameIndex.store((index + 1) % 3, std::memory_order_release);
        logicFrameNumber.fetch_add(1, std::memory_order_release);

        std::lock_guard<std::mutex> lock(syncMutex);
        renderCV.notify_one();
    }

    // 渲染线程：获取可渲染的帧
    const FrameData* beginRenderFrame() {
        // 等待逻辑线程完成至少一帧
        while (renderedFrameNumber >= logicFrameNumber) {
            std::unique_lock<std::mutex> lock(syncMutex);
            renderCV.wait(lock);
        }

        int index = renderFrameIndex.load(std::memory_order_acquire);

        if (!frames[index].ready.load(std::memory_order_acquire)) {
            return nullptr;
        }

        return &frames[index];
    }

    // 渲染线程：结束帧渲染
    void endRenderFrame() {
        int index = renderFrameIndex.load(std::memory_order_acquire);
        frames[index].ready.store(false, std::memory_order_release);

        renderFrameIndex.store((index + 1) % 3, std::memory_order_release);
        renderedFrameNumber.fetch_add(1, std::memory_order_release);

        std::lock_guard<std::mutex> lock(syncMutex);
        logicCV.notify_one();
    }
};
```

### 4.2 渲染命令缓冲区

```cpp
// ============================================
// 渲染命令编码器
// ============================================

class RenderCommandEncoder {
private:
    std::vector<RenderCommand> commands;
    std::vector<uint8_t> dataBuffer;  // 命令数据
    size_t currentOffset = 0;

public:
    // 编码绘制命令
    void drawMesh(uint64_t meshId, uint64_t materialId,
                  const Matrix4& transform) {
        RenderCommand cmd;
        cmd.type = RenderCommand::DrawMesh;
        cmd.meshId = meshId;
        cmd.materialId = materialId;
        cmd.transformOffset = allocateData(&transform, sizeof(Matrix4));

        commands.push_back(cmd);
    }

    // 编码材质设置
    void setMaterial(uint64_t materialId, const MaterialData& data) {
        RenderCommand cmd;
        cmd.type = RenderCommand::SetMaterial;
        cmd.materialId = materialId;
        cmd.dataOffset = allocateData(&data, sizeof(MaterialData));

        commands.push_back(cmd);
    }

    // 完成编码，返回命令列表
    std::vector<RenderCommand> finish() {
        return std::move(commands);
    }

private:
    size_t allocateData(const void* data, size_t size) {
        size_t offset = currentOffset;
        dataBuffer.resize(currentOffset + size);
        memcpy(dataBuffer.data() + offset, data, size);
        currentOffset += size;
        return offset;
    }
};

// 使用示例
void logicThread(FrameSynchronizer& sync) {
    while (running) {
        auto& frame = sync.beginLogicFrame();

        // 更新游戏逻辑
        updateGameLogic();

        // 编码渲染命令
        RenderCommandEncoder encoder;
        for (auto& entity : entities) {
            if (entity.visible) {
                encoder.drawMesh(entity.mesh, entity.material,
                                entity.transform);
            }
        }

        frame.commands = encoder.finish();
        sync.endLogicFrame();
    }
}

void renderThread(FrameSynchronizer& sync) {
    while (running) {
        auto frame = sync.beginRenderFrame();
        if (!frame) continue;

        // 执行渲染命令
        for (const auto& cmd : frame->commands) {
            executeRenderCommand(cmd);
        }

        // 提交 GPU
        present();

        sync.endRenderFrame();
    }
}
```

### 4.3 数据同步点

```cpp
// ============================================
// 同步点 (Sync Point)
// ============================================

class SyncPoint {
private:
    std::atomic<bool> triggered{false};
    std::mutex mutex;
    std::condition_variable cv;

public:
    void signal() {
        std::lock_guard<std::mutex> lock(mutex);
        triggered.store(true, std::memory_order_release);
        cv.notify_all();
    }

    void wait() {
        std::unique_lock<std::mutex> lock(mutex);
        cv.wait(lock, [&] {
            return triggered.load(std::memory_order_acquire);
        });
    }

    void reset() {
        triggered.store(false, std::memory_order_release);
    }
};

// 使用示例：逻辑线程等待渲染线程完成
class GameLoop {
private:
    SyncPoint renderComplete;
    SyncPoint logicComplete;

public:
    void run() {
        std::thread logic([&] { logicThread(); });
        std::thread render([&] { renderThread(); });

        logic.join();
        render.join();
    }

    void logicThread() {
        while (running) {
            updateLogic();

            logicComplete.signal();
            renderComplete.wait();
            renderComplete.reset();
            logicComplete.reset();
        }
    }

    void renderThread() {
        while (running) {
            logicComplete.wait();

            renderFrame();
            present();

            renderComplete.signal();
        }
    }
};
```

---

## 5. 完整示例：帧同步架构

```cpp
// ============================================
// 完整的游戏引擎多线程架构
// ============================================

#include <thread>
#include <atomic>
#include <vector>
#include <memory>
#include <mutex>
#include <condition_variable>

// ============================================
// 1. 帧数据定义
// ============================================

struct FrameData {
    // 游戏状态
    std::vector<EntityTransform> transforms;
    CameraData camera;
    std::vector<LightData> lights;

    // 渲染命令
    std::vector<RenderCommand> renderCommands;

    // 同步标记
    std::atomic<bool> ready{false};
    int frameNumber = 0;
};

// ============================================
// 2. 帧同步器
// ============================================

class FrameSynchronizer {
private:
    static constexpr int FRAME_COUNT = 3;
    FrameData frames[FRAME_COUNT];

    std::atomic<int> writeIndex{0};
    std::atomic<int> readIndex{0};
    std::atomic<int> writeFrame{-1};
    std::atomic<int> readFrame{-1};

    std::mutex mutex;
    std::condition_variable writeCV;
    std::condition_variable readCV;

public:
    // 逻辑线程：获取写缓冲区
    FrameData& acquireWriteBuffer() {
        // 等待有空闲帧
        std::unique_lock<std::mutex> lock(mutex);
        writeCV.wait(lock, [&] {
            return writeFrame - readFrame < FRAME_COUNT - 1;
        });
        lock.unlock();

        return frames[writeIndex];
    }

    // 逻辑线程：释放写缓冲区
    void releaseWriteBuffer() {
        int index = writeIndex.load();
        frames[index].ready.store(true, std::memory_order_release);

        writeIndex = (index + 1) % FRAME_COUNT;
        writeFrame++;

        readCV.notify_one();
    }

    // 渲染线程：获取读缓冲区
    const FrameData& acquireReadBuffer() {
        // 等待有可用帧
        std::unique_lock<std::mutex> lock(mutex);
        readCV.wait(lock, [&] {
            return readFrame < writeFrame;
        });
        lock.unlock();

        return frames[readIndex];
    }

    // 渲染线程：释放读缓冲区
    void releaseReadBuffer() {
        int index = readIndex.load();
        frames[index].ready.store(false, std::memory_order_release);

        readIndex = (index + 1) % FRAME_COUNT;
        readFrame++;

        writeCV.notify_one();
    }

    int getWriteFrameNumber() const { return writeFrame; }
    int getReadFrameNumber() const { return readFrame; }
};

// ============================================
// 3. 逻辑线程
// ============================================

class LogicThread {
private:
    FrameSynchronizer& sync;
    std::thread thread;
    std::atomic<bool> running{true};

public:
    LogicThread(FrameSynchronizer& s) : sync(s) {
        thread = std::thread([&] { run(); });
    }

    ~LogicThread() {
        running = false;
        thread.join();
    }

private:
    void run() {
        while (running) {
            auto& frame = sync.acquireWriteBuffer();

            // 更新游戏逻辑
            updateEntities(frame.transforms);
            updateCamera(frame.camera);
            updateLights(frame.lights);

            // 生成渲染命令
            generateRenderCommands(frame.renderCommands);

            sync.releaseWriteBuffer();
        }
    }

    void updateEntities(std::vector<EntityTransform>& transforms) {
        // ... 更新实体变换
    }

    void updateCamera(CameraData& camera) {
        // ... 更新相机
    }

    void updateLights(std::vector<LightData>& lights) {
        // ... 更新灯光
    }

    void generateRenderCommands(std::vector<RenderCommand>& commands) {
        // ... 生成渲染命令
    }
};

// ============================================
// 4. 渲染线程
// ============================================

class RenderThread {
private:
    FrameSynchronizer& sync;
    std::thread thread;
    std::atomic<bool> running{true};

public:
    RenderThread(FrameSynchronizer& s) : sync(s) {
        thread = std::thread([&] { run(); });
    }

    ~RenderThread() {
        running = false;
        thread.join();
    }

private:
    void run() {
        while (running) {
            const auto& frame = sync.acquireReadBuffer();

            // 执行渲染
            executeRenderCommands(frame.renderCommands);

            // 提交 GPU
            present();

            sync.releaseReadBuffer();
        }
    }

    void executeRenderCommands(const std::vector<RenderCommand>& commands) {
        // ... 执行渲染命令
    }

    void present() {
        // ... 提交到显示器
    }
};

// ============================================
// 5. 主循环
// ============================================

class GameEngine {
private:
    FrameSynchronizer sync;
    std::unique_ptr<LogicThread> logicThread;
    std::unique_ptr<RenderThread> renderThread;

public:
    void initialize() {
        logicThread = std::make_unique<LogicThread>(sync);
        renderThread = std::make_unique<RenderThread>(sync);
    }

    void run() {
        // 主线程可以做其他事情
        while (true) {
            // 处理输入、网络等
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    }
};

int main() {
    GameEngine engine;
    engine.initialize();
    engine.run();
    return 0;
}
```

---

## 核心要点总结

| 技术 | 解决的问题 | 适用场景 |
|------|-----------|---------|
| **内存屏障** | 确保跨线程内存可见性 | 所有跨线程共享数据 |
| **双缓冲** | 无锁数据交换 | 游戏状态同步 |
| **环形缓冲区** | 单生产者-单消费者 | 渲染命令队列 |
| **原子计数器** | 等待多任务完成 | 任务依赖管理 |
| **任务图(DAG)** | 复杂依赖关系 | 帧任务调度 |
| **三缓冲** | 逻辑/渲染解耦 | 帧同步架构 |

## 参考资料

1. **C++ Concurrency in Action** - Anthony Williams
2. **Game Engine Architecture** - Jason Gregory
3. **Intel TBB** - Thread Building Blocks
4. **Unity Job System** - Unity Technologies
5. **Unreal Engine Task Graph** - Epic Games
