#pragma once

#include <thread>
#include <functional>
#include "threadqueue.h"
#include "Ref.h"
#include "swift/bridging"

using namespace std;
using TaskFuncPtr = void (*)();

enum class TaskTypeForSingle
{
    Execute,
    Stop
};

struct Task_Empty
{
    TaskTypeForSingle type;
    function<void()> task;
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

using TaskQueue = TSQueue<Task_Empty>;

class SingleThread : NonCopyableClass, public ReferenceCountedClass<SingleThread>
{
private:
    atomic<DoneType> done;
    TaskQueue queue;
    thread m_thread;

public:
    void submit(TaskFuncPtr _Nonnull f);
    void submit(const void *_Nonnull value, void (*_Nonnull callback)(void const *_Nonnull value));
    void submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(const void *_Nonnull job, const void *_Nonnull executor));
    DoneType getDone() const SWIFT_COMPUTED_PROPERTY;
    void setDone(DoneType value) SWIFT_COMPUTED_PROPERTY;
    void submit(Task_Empty task);
    SingleThread();
    ~SingleThread();
    static SingleThread *_Nonnull create();
} SWIFT_UNCHECKED_SENDABLE SWIFT_SHARED_REFERENCE(retain_single, release_single);

inline void retain_single(SingleThread *_Nonnull ref)
{
    ref->addref();
    // retained(ref);
}

inline void release_single(SingleThread *_Nonnull ref)
{
    ref->delref();
    // released(ref);
}
