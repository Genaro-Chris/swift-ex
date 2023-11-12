#include <iostream>
#include <bridging.h>
#include <vector>
#include <threads.h>
#include <thread>

using namespace std;

using FuncPtr = void (*)(void);

class Thread;

template <class Subclass>
class ReferenceCounted
{
public:
    ReferenceCounted() : referenceCount(0) {}
    // NO virtual destructor!  Subclass should have a virtual destructor if it is not sealed.
    void addref() const { ++referenceCount; }
    void delref() const
    {
        if (delref_no_destroy())
            delete (Subclass *)this;
    }
    bool delref_no_destroy() const { return !--referenceCount; }
    int32_t debugGetReferenceCount() const { return referenceCount; } // Never use in production code, only for tracing
    bool isSoleOwner() const { return referenceCount == 1; }

private:
    ReferenceCounted(const ReferenceCounted &) /* = delete*/;
    void operator=(const ReferenceCounted &) /* = delete*/;
    mutable int32_t referenceCount;
};

class NonCopyable
{
protected:
    NonCopyable() = default;
    ~NonCopyable() = default; /// Protected non-virtual destructor
    NonCopyable(NonCopyable &&) = default;
    NonCopyable &operator=(NonCopyable &&) = default;
    NonCopyable(const NonCopyable &) = delete;
    NonCopyable &operator=(const NonCopyable &) = delete;
};

struct SWIFT_SHARED_REFERENCE(retain, release)
    Thread : NonCopyable,
             ReferenceCounted<Thread>
{
private:
    std::thread my_thread;
    Thread() = default;

public:
    static Thread *_Nonnull new_thread();
    Thread(FuncPtr _Nonnull with);
    ~Thread();
    void run(void (*_Nonnull callback)(void const *_Nonnull value), const void *_Nonnull value) SWIFT_MUTATING;
    static void Run(void(callback)(void const *_Nonnull value, void const *_Nonnull newValue), void const *_Nonnull value, void const *_Nonnull newValue);
    static void RunOnce(void(callback)(void const *_Nonnull value), void const *_Nonnull value);
    void swap_with(FuncPtr _Nonnull with);
    static Thread *_Nonnull create(FuncPtr _Nonnull with);
    void dynamicallyCall(vector<int> withArguments);
    void join_all();
    void detach();
    void yield();
} SWIFT_SENDABLE SWIFT_NAME(CXX_Thread);

inline void retain(Thread *_Nonnull ref)
{
    ref->addref();
}

inline void release(Thread *_Nonnull ref)
{
    ref->delref();
}

struct ThreadPool : NonCopyable, ReferenceCounted<ThreadPool>
{
private:
    uint value;

public:
    static auto create() -> ThreadPool *_Nonnull
    {
        return new ThreadPool();
    }
} SWIFT_SHARED_REFERENCE(retain_pool, release_pool);

inline void retain_pool(ThreadPool *_Nonnull ref)
{
    ref->addref();
}

inline void release_pool(ThreadPool *_Nonnull ref)
{
    ref->delref();
}