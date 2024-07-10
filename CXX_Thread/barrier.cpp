#include "include/barrier.h"
#include <thread>

/* template <typename T>
barrier<T>::barrier(int count) : counter{0}, max{count} {}

template <typename T>
auto barrier<T>::arrive_and_wait() noexcept -> void
{
} */

barrier::barrier(int count) : counter{0}, max{count} {}

auto barrier::arrive_and_wait() noexcept -> void
{
    counter++;
    while (!std::atomic_compare_exchange_strong(&counter, &max, 0))
    {
        std::this_thread::yield();
    }
}