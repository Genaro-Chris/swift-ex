#pragma once

#include <thread>
#include <threads.h>
#include <bits/std_thread.h>
#include <vector>
#include <functional>
#include "threadqueue.h"
#include "Ref.h"
#include <variant>
#include "swift/bridging"

using namespace std;

const auto CPU_Count = thread::hardware_concurrency();

using TaskFuncPtr = void (*)(void);

enum class TaskTypeForPool
{
    Execute,
    Stop
};

struct Task_Pool
{
    TaskTypeForPool type;
    function<void()> task;
};

using TaskQueueForPool = TSQueue<Task_Pool>;

class CXX_ThreadPool : NonCopyableClass, public ReferenceCountedClass<CXX_ThreadPool>
{    
protected:
    vector<thread> threads;
    TaskQueueForPool queue;
    int thread_count;

protected:
    void submit(Task_Pool task);

public:
    CXX_ThreadPool();
    void submit(TaskFuncPtr _Nonnull f);
    void submit(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor));
    CXX_ThreadPool(uint count = CPU_Count);

    ~CXX_ThreadPool();
    static CXX_ThreadPool *_Nonnull create(uint count = CPU_Count);
    static CXX_ThreadPool *_Nonnull getGlobalPool();
} SWIFT_UNCHECKED_SENDABLE SWIFT_SHARED_REFERENCE(retain_pool, release_pool);

auto getThreadID() -> string;

inline void retain_pool(CXX_ThreadPool *_Nonnull ref)
{
    retained(ref);
}

inline void release_pool(CXX_ThreadPool *_Nonnull ref)
{
    released(ref);
}
