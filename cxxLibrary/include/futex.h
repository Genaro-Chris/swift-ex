#pragma once

#include "Ref.h"
#include <atomic>
#include <swift/bridging>

struct FutexLock : public ReferenceCountedClass1<FutexLock>, NonCopyableClass1
{
public:
    FutexLock() = default; // Default constructor
    FutexLock(const FutexLock &FLCopy) = delete; // Copy constructor
    FutexLock(FutexLock &&FLCopy) noexcept; // Move constructor
    ~FutexLock() = default;                 // Destructor (implicitly noexcept)

    auto operator=(const FutexLock &FLCopy) -> FutexLock & = delete; // Copy assignment operator
    auto operator=(FutexLock &&FLCopy) noexcept -> FutexLock &; // Move assignment operator

    void lock();

    void unlock();

    void wake();

    void wait();

    static FutexLock *_Nonnull create()
    {
        return new FutexLock();
    }

private:
    std::atomic<int> atom = {0};
} SWIFT_SHARED_REFERENCE(retain_f, release_f);

void retain_f(FutexLock *_Nonnull ref);

void release_f(FutexLock *_Nonnull ref);