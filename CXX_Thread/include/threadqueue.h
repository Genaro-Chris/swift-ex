#include <deque>
#include <mutex>
#include <optional>
#include <condition_variable>
#include <Ref.h>

#pragma once

using namespace std;

template <typename T>
class TSQueue
{
private:
    deque<T> buffer{};
    mutex mtx;
    condition_variable cv;

public:
    TSQueue(const TSQueue &) = delete;
    TSQueue operator&=(const TSQueue &) = delete;
    void operator<<(T with)
    {
        this->enqueue(with);
    }
    TSQueue() = default;
    
    void enqueue(T value)
    {
        lock_guard lg{mtx};
        buffer.push_back(value);
        cv.notify_one();
    }
    optional<T> dequeue()
    {
        unique_lock ul{mtx};
        cv.wait(ul, [&]()
                { return !buffer.empty(); });
        if (buffer.empty())
            return nullopt;
        auto val = buffer.back();
        buffer.pop_back();
        return val;
    }
    int length()
    {
        lock_guard lg{mtx};
        return buffer.size();
    }
};
