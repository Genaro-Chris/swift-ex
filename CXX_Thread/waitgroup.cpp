#include "waitgroup.h"

void waitgroup::enter()
{
    auto lock = unique_lock{this->mtx};
    this->count++;
}

void waitgroup::done()
{
    auto lock = unique_lock{this->mtx};
    if (this->count < 1)
        return;
    this->count--;
    if (this->count == 0)
        this->cv.notify_all();
}

void waitgroup::wait()
{
    auto lock = unique_lock{this->mtx};
    this->cv.wait(lock, [&]()
                  { return this->count == 0; });
}

waitgroup *_Nonnull waitgroup::init()
{
    return new waitgroup();
}