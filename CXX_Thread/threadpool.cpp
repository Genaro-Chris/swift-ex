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

CXX_ThreadPool::CXX_ThreadPool(uint count)
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

void CXX_ThreadPool::submit(Task_Pool task)
{
    queue << task;
}

CXX_ThreadPool::~CXX_ThreadPool()
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

static auto pool = new CXX_ThreadPool{CPU_Count};

CXX_ThreadPool *_Nonnull CXX_ThreadPool::getGlobalPool()
{
    pool->addref();
    return pool;
}

string getThreadID()
{
    
    ostringstream ss;
    ss << "#" << this_thread::get_id();
    auto d = ss.str();
    return d;
}
