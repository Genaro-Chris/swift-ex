#include "include/threadpool.h"
#include <sstream>

auto make_thread_handler(TaskQueueForPool &queue)
{
    return thread{[&queue]()
                   {
                       while (true)
                       {
                           auto const elem = queue.dequeue();
                           if (elem.has_value())
                           {
                               auto const element = (*elem);
                               switch (element.type)
                               {
                               case TaskTypeForPool::Execute:
                                   element.task();
                                   break;

                               case TaskTypeForPool::Stop:
                                   return;
                               }
                           }
                       }
                   }};
}

ThreadPool::ThreadPool(uint count)
{
    if (count == 0)
    {
        count = 1;
    }
    threads.reserve(count);
    thread_count = count;
        for (int i = 0; i < count; i++)
        {
            threads.push_back(make_thread_handler(queue));
        }
}

void ThreadPool::submit(Task_Pool task)
{
    queue << task;
}

ThreadPool::~ThreadPool()
{
    Task_Pool const stop_task{TaskTypeForPool::Stop, {}};
    for (size_t i = 0; i < threads.size(); i++)
    {
        queue << stop_task;
    }

    for (size_t i = 0; i < threads.size(); i++)
    {
        if (threads[i].joinable())
        {
            threads[i].join();
        }
        else
        {
            threads[i].detach();
        }
    }
}

void ThreadPool::submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor))
{
    queue << Task_Pool{TaskTypeForPool::Execute, [callback, job, executor]()
                       {
                           callback(job, executor);
                       }};
}

void ThreadPool::submit(const void *value, void (*_Nonnull callback)(void const *value))
{
    queue << Task_Pool{TaskTypeForPool::Execute, [callback, value]()
                       {
                           callback(value);
                       }};
}

ThreadPool *ThreadPool::create(uint count)
{
    return new ThreadPool(count);
}

void ThreadPool::submit(TaskFuncPtr f)
{
    queue << Task_Pool{TaskTypeForPool::Execute, [f]()
                       {
                           f();
                       }};
}

string getThreadID()
{
    ostringstream ss;
    ss << "#" << this_thread::get_id();
    return ss.str();
}
