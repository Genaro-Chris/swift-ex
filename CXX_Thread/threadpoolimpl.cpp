#include "thread_pool.h"
#include <iostream>
#include <sstream>
/* #include <algorithm>
#include <utility> */

auto make_thread_handler(TaskQueue &queue)
{
    return jthread{[&queue]()
                   {
                       while (true)
                       {
                           auto const elem = queue.dequeue();
                           if (elem.has_value())
                           {
                               auto const element = (*elem);
                               switch (element.type)
                               {
                               case TaskType::Execute:
                                   element.task(element.arguments);
                                   break;

                               case TaskType::Stop:
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
    try
    {
        for (int i = 0; i < count; i++)
        {
            threads.push_back(make_thread_handler(queue));
        }
    }
    catch (const std::exception &e)
    {
        return;
    }
}

void ThreadPool::submit(Task_ task)
{
    queue.enqueue(task);
}

ThreadPool::~ThreadPool()
{
    Task_ const stop_task{TaskType::Stop, {}, {}};
    for (size_t i = 0; i < threads.size(); i++)
    {
        queue.enqueue(stop_task);
    }
}

void ThreadPool::submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor))
{
    queue.enqueue(Task_{TaskType::Execute, [callback, job, executor](vector<Param>)
                        {
                            callback(job, executor);
                        },
                        {}});
}

void ThreadPool::submit(const void *value, void (*_Nonnull callback)(void const *value))
{
    queue.enqueue(Task_{TaskType::Execute, [callback, value](vector<Param>)
                        {
                            callback(value);
                        },
                        {}});
}

ThreadPool *ThreadPool::create(uint count)
{
    return new ThreadPool(count);
}

void ThreadPool::submit(TaskFuncPtr f)
{
    queue.enqueue(Task_{TaskType::Execute, [f](vector<Param>)
                        {
                            f();
                        },
                        {}});
}

string getThreadID()
{
    ostringstream ss;
    ss << "#" << this_thread::get_id();
    return ss.str();
}

auto make_thread_handler_for_single(TaskQueue &queue, SingleThreadedPool &pool)
{
    return jthread{[&queue, &pool]()
                   {
                       while (true)
                       {
                           auto const elem = queue.dequeue();
                           if (elem.has_value())
                           {
                               auto const element = (*elem);
                               switch (element.type)
                               {
                               case TaskType::Execute:

                                   switch (pool.getDone())
                                   {
                                   case DoneType::First:
                                       element.task(element.arguments);
                                       pool.setDone(DoneType::Ready);
                                       continue;
                                   case DoneType::Ready:
                                       pool.setDone(DoneType::Notyet);
                                       element.task(element.arguments);
                                       pool.setDone(DoneType::Ready);
                                       continue;
                                   case DoneType::Notyet:
                                       pool.submit(element);
                                       continue;
                                   }

                               case TaskType::Stop:
                                   return;
                               }
                           }
                       }
                   }};
}

SingleThreadedPool::SingleThreadedPool()
{
    threads.clear();
    auto count = 1;
    threads.reserve(count);
    setDone(DoneType::First);
    thread_count = count;

    for (int i = 0; i < count; i++)
    {
        threads.push_back(make_thread_handler_for_single(queue, *this));
    }
}

DoneType SingleThreadedPool::getDone() const
{

    return done;
}

void SingleThreadedPool::setDone(DoneType value)
{
    done = value;
}

SingleThreadedPool *SingleThreadedPool::create()
{
    return new SingleThreadedPool();
}

/* SpecialThread::SpecialThread(SpecialThread &&sp) noexcept : handle_(std::exchange(sp.handle_, {})), done(std::move(sp.getDone())) {}
SpecialThread &SpecialThread::operator=(SpecialThread &&sp) noexcept
{
    if (this != &sp)
    {
        handle_ = exchange(sp.handle_, {});
        // std::jthread(std::move(__other)).swap(*this);
        // handle_ = std::move(jthread(move(sp.handle_)).swap(handle_));
    }
    done = std::move(sp.getDone());
    return *this;
} */