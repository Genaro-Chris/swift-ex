#include "singlethread.h"

auto make_thread_handler(TaskQueue &queue, SingleThread &pool)
{
    return thread([&queue, &pool]()
                  {
        while (true)
        {
            auto const elem = queue.dequeue();
            if (elem.has_value())
            {
                auto const element = elem.value();
                switch (element.type)
                {
                case TaskTypeForSingle::Execute:
                    switch (pool.getDone())
                    {
                    case DoneType::First:
                        element.task();
                        pool.setDone(DoneType::Ready);
                        continue;
                    case DoneType::Ready:
                        pool.setDone(DoneType::Notyet);
                        element.task();
                        pool.setDone(DoneType::Ready);
                        continue;
                    case DoneType::Notyet:
                        pool.submit(element);
                        continue;
                    }

                case TaskTypeForSingle::Stop:
                    return;
                }
            }
        } });
}

SingleThread::SingleThread()
{
    setDone(DoneType::First);
    m_thread = make_thread_handler(queue, *this);
}

DoneType SingleThread::getDone() const
{
    return done;
}

void SingleThread::setDone(DoneType value)
{
    done = value;
}

void SingleThread::submit(const void *value, void (*_Nonnull callback)(void const *value))
{
    queue << Task_Empty{TaskTypeForSingle::Execute, [callback, value]()
                        {
                            callback(value);
                        }};
}

SingleThread *SingleThread::create()
{
    return new SingleThread();
}

SingleThread::~SingleThread()
{
    auto stop_task = Task_Empty{
        TaskTypeForSingle::Stop, {}};
    queue << stop_task;
    if (m_thread.joinable())
    {
        m_thread.join();
    }
    else
    {
        m_thread.detach();
    }
}

void SingleThread::submit(TaskFuncPtr task)
{
    queue << Task_Empty{TaskTypeForSingle::Execute, [task]()
                        {
                            task();
                        }};
}

void SingleThread::submit(Task_Empty task)
{
    queue << task;
}

void SingleThread::submitTaskWithExecutor(const void *job, const void *executor, void (*callback)(const void *job, const void *executor))
{
    queue << Task_Empty{TaskTypeForSingle::Execute, [callback, job, executor]()
                        {
                            callback(job, executor);
                        }};
}
