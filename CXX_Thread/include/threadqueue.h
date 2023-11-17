#include <list>
#include <mutex>
#include <optional>
#include <condition_variable>
#include <Ref.h>
#include "bridging.h"

#pragma once

using namespace std;

template <typename T>
class ThreadSafeQueue
{
private:
    list<T> buffer;
    mutex mtx;
    int index;
    condition_variable cv;

public:
    ThreadSafeQueue(const ThreadSafeQueue &) = delete;
    ThreadSafeQueue operator&=(const ThreadSafeQueue &) = delete;
    ThreadSafeQueue() : index(0) {}
    static ThreadSafeQueue *_Nonnull create()
    {
        return new ThreadSafeQueue<T>();
    }
    void enqueue(T value)
    {
        lock_guard lg{mtx};
        buffer.push_back(value);
        cv.notify_all();
        index++;
    }
    optional<T> dequeue()
    {
        unique_lock ul{mtx};
        cv.wait(ul, [&]()
                { return !buffer.empty(); });
        if (buffer.empty())
            return nullopt;
        auto val = buffer.front();
        index--;
        buffer.pop_front();
        return val;
    }
    int length()
    {
        lock_guard lg{mtx};
        return buffer.size();
    }
};
