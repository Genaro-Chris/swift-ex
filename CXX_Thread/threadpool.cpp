#include "include/threadpool.h"
#include "threadpool.h"
#include <functional>
#include <sstream>

auto make_thread_handler(TaskQueueForPool &queue, barrier<> &_barrier)
{
    return thread{[&queue, &_barrier]()
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

                              case TaskTypeForPool::Wait:
                                  _barrier.arrive_and_wait();
                                  break;
                              }
                          }
                      }
                  }};
}

CXX_ThreadPool::CXX_ThreadPool(uint count) : threads{}, _barrier{std::barrier(count == 0 ? 2 : count + 1)}, thread_count{count == 0 ? 1 : count}
{
    threads.reserve(thread_count);
    for (int i = 0; i < thread_count; i++)
    {
        threads.push_back(make_thread_handler(queue, _barrier));
    }
}

void CXX_ThreadPool::submit(Task_Pool task)
{
    queue << task;
}

void CXX_ThreadPool::waitForAll()
{
    Task_Pool const wait_task{TaskTypeForPool::Wait, {}};
    for (size_t i = 0; i < thread_count; i++)
    {
        queue << wait_task;
    }
    _barrier.arrive_and_wait();
}

CXX_ThreadPool::~CXX_ThreadPool()
{
    Task_Pool const stop_task{TaskTypeForPool::Stop, {}};
    for (size_t i = 0; i < thread_count; i++)
    {
        queue << stop_task;
    }

    for (size_t i = 0; i < thread_count; i++)
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

void CXX_ThreadPool::submitTaskWithExecutor(const void *_Nonnull job, const void *_Nonnull executor, void (*_Nonnull callback)(void const *_Nonnull job, void const *_Nonnull executor))
{
    queue << Task_Pool{TaskTypeForPool::Execute, [callback, job, executor]()
                       {
                           callback(job, executor);
                       }};
}

void CXX_ThreadPool::submit(const void *value, void (*_Nonnull callback)(void const *value))
{
    queue << Task_Pool{TaskTypeForPool::Execute, [callback, value]()
                       {
                           callback(value);
                       }};
}

void CXX_ThreadPool::submitTasks(function<void()> task)
{
    queue << Task_Pool{.type = TaskTypeForPool::Execute, .task = task};
}

CXX_ThreadPool *CXX_ThreadPool::create(uint count)
{
    return new CXX_ThreadPool(count);
}

void CXX_ThreadPool::submit(TaskFuncPtr f)
{
    queue << Task_Pool{TaskTypeForPool::Execute, [f]()
                       {
                           f();
                       }};
}

CXX_ThreadPool CXX_ThreadPool::shared{CXX_ThreadPool(CPU_Count)};

CXX_ThreadPool const *_Nonnull const CXX_ThreadPool::globalPool = []
{
    // CXX_ThreadPool::shared.addref();
    return &CXX_ThreadPool::shared;
}();

string getThreadID()
{

    ostringstream ss;
    auto id{this_thread::get_id()};
    ss << "#" << id;
    auto d = ss.str();
    return d;
}

CXX_ThreadPool *_Nonnull CXX_ThreadPool::global()
{
    return CXX_ThreadPool::create();
}