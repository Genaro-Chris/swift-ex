#include <vector>
#include <mutex>
#include <optional>
#include <condition_variable>
#include <Ref.h>

#pragma once

using namespace std;

template <typename T>
class ThreadSafeQueue
{
private:
    vector<T> buffer;
    mutex mtx;
    int index;
    int current_index;
    condition_variable cv;

public:
    ThreadSafeQueue(const ThreadSafeQueue &) = delete;
    ThreadSafeQueue operator&=(const ThreadSafeQueue &) = delete;
    void operator<<(T with)
    {
        this->enqueue(with);
    }
    ThreadSafeQueue() : index(0), current_index(0)
    {
        vector<T> buf{};
        buffer = {};
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
        if (buffer.empty() || index == 0)
            return nullopt;
        auto val = buffer[current_index];
        ++current_index;
        index--;
        return val;
    }
    int length()
    {
        lock_guard lg{mtx};
        return buffer.size();
    }
};
