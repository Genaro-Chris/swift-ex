#include "include/futex.h"
#include <cstdint>
#include <errno.h>
#include <linux/futex.h>
#include <sys/syscall.h>
#include <unistd.h>

static inline auto getThreadID() -> uint32_t
{
    static int tid = 0;

    if (tid == 0)
    {
        tid = syscall(SYS_gettid);
    }

    return static_cast<uint32_t>(tid);
}

static inline auto futex_lock(uint32_t *lock) -> uint32_t
{
    int ret = syscall(SYS_futex, lock, FUTEX_LOCK_PI_PRIVATE, 0, nullptr);
    if (ret == 0)
    {
        return ret;
    }

    return errno;
}

static inline auto futex_unlock(uint32_t *lock) -> uint32_t
{
    int ret = syscall(SYS_futex, lock, FUTEX_UNLOCK_PI_PRIVATE);
    if (ret == 0)
    {
        return ret;
    }

    return errno;
}

static inline auto futex_trylock(uint32_t *lock) -> uint32_t
{
    int ret = syscall(SYS_futex, lock, FUTEX_TRYLOCK_PI);
    if (ret == 0)
    {
        return ret;
    }

    return errno;
}

static inline void futex_wait(int *lock)
{
    syscall(SYS_futex, lock, FUTEX_WAIT, 2, 0, 0, 0);
}

static inline void futex_wake(int *lock)
{
    syscall(SYS_futex, lock, FUTEX_WAKE, 1, 0, 0, 0);
}

static inline void futex_wake_all(uint32_t *lock)
{
    syscall(SYS_futex, lock, FUTEX_WAKE_OP);
}

/// An atomic_compare_exchange wrapper with semantics expected by the paper's mutex
auto cmpxchg(std::atomic<int> *atom, int expected, int desired) -> int
{
    int *exp = &expected;
    std::atomic_compare_exchange_strong(atom, exp, desired);
    return *exp;
}

void retain_f(FutexLock *_Nonnull ref)
{
    retained_(ref);
}

void release_f(FutexLock *_Nonnull ref)
{
    released_(ref);
}

FutexLock::FutexLock(FutexLock &&FLCopy) noexcept : atom{FLCopy.atom.load(std::memory_order_acquire)} {
    delete &FLCopy;
}

FutexLock &FutexLock::operator=(FutexLock &&FLCopy) noexcept
{
    atom.store(FLCopy.atom.load(std::memory_order_acquire), std::memory_order_relaxed);
    return *this;
}

void FutexLock::lock()
{
    auto c = cmpxchg(&atom, 0, 1);
    if (c != 0)
    {
        do
        {
            if (c == 2 || cmpxchg(&atom, 1, 2))
            {
                futex_wait((int *)&atom);
            }

        } while ((c = cmpxchg(&atom, 0, 2)) != 0);
    }
}

void FutexLock::unlock()
{
    if (atom.fetch_sub(1) != 1)
    {
        atom.store(0);
        futex_wake((int *)&atom);
    }
}

void FutexLock::wait()
{
}

void FutexLock::wake()
{
}