#include "swift/bridging"
#include <vector>
#include <threads.h>
#include <thread>
#include "Ref.h"

using namespace std;

using FuncPtr = void (*)(void);

struct
    Thread : NonCopyable,
             public ReferenceCounted<Thread>
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
} SWIFT_SHARED_REFERENCE(retain_thread, release_thread) SWIFT_UNCHECKED_SENDABLE SWIFT_NAME(CXX_Thread);

inline void retain_thread(Thread *_Nonnull ref)
{
    retained(ref);
}

inline void release_thread(Thread *_Nonnull ref)
{
    released(ref);
}