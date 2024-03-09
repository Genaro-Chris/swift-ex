#ifndef Header_M
#define Header_M

#include <thread>
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

using TaskQueueForPool = ThreadSafeQueue<Task_Pool>;

class ThreadPool : NonCopyable, public ReferenceCounted<ThreadPool>
{
protected:
    vector<thread> threads;
    TaskQueueForPool queue;
    int thread_count;

protected:
    void submit(Task_Pool task);

public:
    ThreadPool();
    void submit(TaskFuncPtr _Nonnull f);
    void submit(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor));
    ThreadPool(uint count = CPU_Count);

    ~ThreadPool();
    static ThreadPool *_Nonnull create(uint count = CPU_Count);
} SWIFT_UNCHECKED_SENDABLE SWIFT_SHARED_REFERENCE(retain_pool, release_pool);

string getThreadID();

inline void retain_pool(ThreadPool *_Nonnull ref)
{
    retained(ref);
}

inline void release_pool(ThreadPool *_Nonnull ref)
{
    released(ref);
}

#endif