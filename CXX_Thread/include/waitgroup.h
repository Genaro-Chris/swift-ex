#include <mutex>
#include <condition_variable>
#include "swift/bridging"
#include "Ref.h"

#pragma once

struct waitgroup : public NonCopyableClass, public ReferenceCountedClass<waitgroup>
{
private:
    mutex mtx;
    condition_variable cv;
    int count;

public:
    waitgroup() : mtx{mutex{}}, cv{condition_variable{}}, count{0} {}
    void enter();
    void done();
    void wait();
    static waitgroup *_Nonnull init();
} SWIFT_SHARED_REFERENCE(retain_group, release_group);

inline void retain_group(waitgroup *_Nonnull ref)
{
    retained(ref);
}

inline void release_group(waitgroup *_Nonnull ref)
{
    released(ref);
}
