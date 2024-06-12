#include "Ref.h"
#include "swift/bridging"
#include "threadqueue.h"
#include <barrier>
#include <bits/std_thread.h>
#include <functional>
#include <thread>
#include <utility>
#include <vector>

#pragma once

using namespace std;

const auto CPU_Count = thread::hardware_concurrency();

using TaskFuncPtr = void (*)(void);

enum class TaskTypeForPool
{
    Execute,
    Stop,
    Wait
};

struct Task_Pool
{
    TaskTypeForPool type;
    function<void()> task;
};

using TaskQueueForPool = TSQueue<Task_Pool>;

class CXX_ThreadPool : NonCopyableClass, public ReferenceCountedClass<CXX_ThreadPool>
{
private:
    vector<thread> threads;
    TaskQueueForPool queue;
    uint thread_count;
    // static const CXX_ThreadPool *_Nonnull shared;
    static CXX_ThreadPool shared;
    barrier<> _barrier;

protected:
    void submit(Task_Pool task);

public:
    // CXX_ThreadPool();
    static const CXX_ThreadPool *_Nonnull const globalPool;
    void submit(TaskFuncPtr _Nonnull f);
    void submit(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void submitTasks(function<void()> task);
    void submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor));
    void waitForAll();
    CXX_ThreadPool(uint count);
    ~CXX_ThreadPool();
    static CXX_ThreadPool *_Nonnull create(uint count = CPU_Count);

} SWIFT_UNCHECKED_SENDABLE SWIFT_SHARED_REFERENCE(retain_pool, release_pool);

// const CXX_ThreadPool *_Nonnull CXX_ThreadPool::shared{CXX_ThreadPool::create()};

auto getThreadID() -> string;

inline void retain_pool(CXX_ThreadPool *_Nonnull ref)
{
    retained(ref);
}

inline void release_pool(CXX_ThreadPool *_Nonnull ref)
{
    released(ref);
}