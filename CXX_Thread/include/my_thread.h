#include "Ref.h"
#include "threadqueue.h"
#include <atomic>
#include <barrier>
#include <functional>
#include <swift/bridging>
#include <thread>
#include <vector>

#pragma once

using Barrier_ = barrier<>;

struct SWIFT_NAME(CXX_threadpool) threadpool : NonCopyableClass, ReferenceCountedClass<threadpool>
{
    struct TaskTypeForPoolX
    {
        enum struct TaskType
        {
            execute,
            stop
        };
        TaskType type;
        function<void()> task;
    };

private:
    vector<std::unique_ptr<TSQueue<TaskTypeForPoolX>>> queues;
    vector<std::thread> threads;
    atomic_int indexer;
    Barrier_ barrier_;

public:
    static threadpool shared;
    size_t count;
    threadpool(uint count);
    static threadpool *_Nonnull create(uint count);
    void submit(void (*_Nonnull func)(void));
    void submit_with(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void wait_for_all();
    static const threadpool *_Nonnull const global_pool;
    ~threadpool();
} SWIFT_SHARED_REFERENCE(retain_thread_, release_thread_) SWIFT_UNCHECKED_SENDABLE;

void retain_thread_(threadpool *_Nonnull ref);

void release_thread_(threadpool *_Nonnull ref);