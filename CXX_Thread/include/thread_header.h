#pragma once

#include "swift/bridging"
#include <vector>
#include <threads.h>
#include <thread>
#include "Ref.h"

using std::thread;

using FuncPtr = void (*)(void);

struct
    CXX_Thread : NonCopyableClass,
             public ReferenceCountedClass<CXX_Thread>
{
private:
    thread my_thread;
    CXX_Thread() = default;

public:
    static CXX_Thread *_Nonnull new_thread();
    CXX_Thread(FuncPtr _Nonnull with);
    ~CXX_Thread();
    void run(void (*_Nonnull callback)(void const *_Nonnull value), const void *_Nonnull value) SWIFT_MUTATING;
    static void Run(void(callback)(void const *_Nonnull value, void const *_Nonnull newValue), void const *_Nonnull value, void const *_Nonnull newValue);
    static void RunOnce(void(callback)(void const *_Nonnull value), void const *_Nonnull value);
    void swap_with(FuncPtr _Nonnull with);
    static CXX_Thread *_Nonnull create(FuncPtr _Nonnull with);
    void dynamicallyCall(vector<int> withArguments);
    void join_all();
    void detach();
    void yield();
} SWIFT_SHARED_REFERENCE(retain_thread, release_thread) SWIFT_UNCHECKED_SENDABLE;

inline void retain_thread(CXX_Thread *_Nonnull ref)
{
    ref->addref();
    // retained(ref);
}

inline void release_thread(CXX_Thread *_Nonnull ref)
{
    ref->delref();
    // released(ref);
}