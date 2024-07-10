#include "my_thread.h"
#include <utility>

auto make_handler(TSQueue<threadpool::TaskTypeForPoolX> &queue) -> ::thread
{
    return thread([&queue]()
                    {
                           while (true)
                           {
                               auto elem = queue.dequeue();
                               if (elem.has_value())
                               {
                                   auto elem_ = (*elem);
                                   switch (elem_.type)
                                   {
                                   case threadpool::TaskTypeForPoolX::TaskType::execute:
                                    elem_.task();
                                    break;
                                   
                                   default:
                                    return;
                                   }
                               }
                               
                           } });
}

threadpool::threadpool(uint count) : queues{}, count{count}, indexer{atomic_int(0)}, barrier_{count + 1}
{
    queues.reserve(count);
    threads.reserve(count);
    for (size_t i = 0; i < count; i++)
    {
        queues.push_back(::make_unique<TSQueue<threadpool::TaskTypeForPoolX>>());
    }

    for (size_t i = 0; i < count; i++)
    {
        threads.push_back(make_handler(*queues[i].get()));
    }
}

threadpool *threadpool::create(uint count)
{
    return new threadpool(count);
}

auto bar(TSQueue<threadpool::TaskTypeForPoolX> &queue, barrier<> &barrier_) -> void
{
    queue << (threadpool::TaskTypeForPoolX{
        .type = threadpool::TaskTypeForPoolX::TaskType::execute, .task = [&]()
                                                                 { barrier_.arrive_and_wait(); }});
}

void threadpool::wait_for_all()
{

    for (size_t i = 0; i < count; i++)
    {
        bar(*queues[i].get(), barrier_);
    }
    barrier_.arrive_and_wait();
}

void threadpool::submit_with(const void *value, void (*callback)(void const *value))
{
    queues[indexer.exchange((indexer.load() + 1) % count)]->enqueue(TaskTypeForPoolX{.task = [value, callback]()
                                                                                     { callback(value); }});
}

void threadpool::submit(void (*func)(void))
{
    queues[indexer.exchange((indexer.load() + 1) % count)]->enqueue(TaskTypeForPoolX{.task = [func]()
                                                                                     { func(); }});
}

threadpool threadpool::shared{threadpool(thread::hardware_concurrency())};

threadpool const *const threadpool::global_pool = []
{
    return &threadpool::shared;
}();

threadpool::~threadpool()
{
    for (size_t i = 0; i < count; i++)
    {
        queues[i]->enqueue(TaskTypeForPoolX{.type = threadpool::TaskTypeForPoolX::TaskType::stop, .task = []() {}});
        threads[i].join();
    }
}

void retain_thread_(threadpool *ref)
{
    ref->addref();
}

void release_thread_(threadpool *ref)
{
    ref->delref();
}
