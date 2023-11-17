#include <atomic>
#include <vector>
#include <thread>
#include <threads.h>
#include <Ref.h>
#include <threadqueue.h>
#include <bridging.h>
#include <functional>
#include <tuple>
#include <map>
#include <variant>

using namespace std;
using TaskFuncPtr = void (*)(void);
using Param = std::variant<int, double, float, string, void (*_Nonnull)(void const *_Nonnull value), monostate>;

static auto CPU_Count = thread::hardware_concurrency();

enum class TaskType
{
    Execute,
    Stop
};

struct Task_
{
    TaskType type;
    std::function<void(vector<Param>)> task;
    vector<Param> arguments;
};

enum class DoneType
{
    First,
    Notyet,
    Ready,

};

inline bool operator==(DoneType rhs, DoneType lhs)
{
    return static_cast<int>(rhs) == static_cast<int>(lhs);
}

using TaskQueue = ThreadSafeQueue<Task_>;

class ThreadPool : NonCopyable, public ReferenceCounted<ThreadPool>
{
protected:
    vector<jthread> threads;
    TaskQueue queue;
    int thread_count;

public:
    void submit(TaskFuncPtr _Nonnull f);
    void submit(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor));
    ThreadPool(uint count = CPU_Count);
    void submit(Task_ task);
    ~ThreadPool();
    void stop()
    {
        delete this;
    }
    static ThreadPool *_Nonnull create(uint count = CPU_Count);
} SWIFT_SENDABLE SWIFT_SHARED_REFERENCE(retain_pool, release_pool);

inline void retain_pool(ThreadPool *_Nonnull ref)
{
    retained(ref);
}

inline void release_pool(ThreadPool *_Nonnull ref)
{
    released(ref);
}

string getThreadID();

class SingleThreadedPool : public ThreadPool
{
private:
    atomic<DoneType> done;

public:
    DoneType getDone() const SWIFT_COMPUTED_PROPERTY;
    void setDone(DoneType value) SWIFT_COMPUTED_PROPERTY;
    SingleThreadedPool();
    static SingleThreadedPool *_Nonnull create();
} SWIFT_SENDABLE SWIFT_SHARED_REFERENCE(retain_single_thread, release_single_thread);

inline void retain_single_thread(SingleThreadedPool *_Nonnull ref)
{
    retained(ref);
}

inline void release_single_thread(SingleThreadedPool *_Nonnull ref)
{
    released(ref);
}
