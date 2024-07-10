#include <atomic>

struct barrier
{
private:
    std::atomic_int counter;
    int max;

public:
    barrier(const barrier &) = delete;
    barrier&operator=(const barrier &) = delete;
    void arrive_and_wait() noexcept;
    barrier(int count);
};
