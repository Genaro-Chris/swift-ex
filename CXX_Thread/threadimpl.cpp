#include "thread_header.h"
#include "stdlib.h"
#include "vector"



using namespace std;

uint zeroed()
{
    return 0;
}

Thread::Thread(FuncPtr _Nonnull with)
{
    this->my_thread = std::thread(
        [with]()
        {
            with();
        });
    std::cout << "Constructor called with " << zeroed() << std::endl;
}

void Thread::dynamicallyCall(vector<int> withArguments)
{
    std::cout << "Dynamically called this with " << zeroed() << std::endl;
}

Thread::~Thread()
{
    this->join_all();

    std::cout << "Destructor called with " << zeroed() << std::endl;
}

/// @brief  the thread ie wait for the thread to finish its execution
void Thread::join_all()
{
    if (this->my_thread.joinable())
    {
        try
        {
            this->my_thread.join();
        }
        catch (const std::exception &e)
        {
            std::cerr << e.what() << '\n';
        }
    }
}

Thread *_Nonnull Thread::create(FuncPtr _Nonnull with)
{
    return new Thread(with);
}

void Thread::run(void(callback)(void const *value), void const *value)
{   
    //this->detach();
    auto new_thread = std::thread(callback, value);
    this->my_thread.swap(new_thread);
}

void Thread::Run(void(callback)(void const *value, void const *newValue), void const *value, void const *newValue)
{
    std::thread(callback, value, newValue).join();
    
}

void Thread::RunOnce(void(callback)(void const *value), void const *value)
{
    std::thread(callback, value).join();
    
}

void Thread::swap_with(FuncPtr _Nonnull with)
{
    this->detach();
    auto new_thread = thread(
        [with]()
        {
            with();
        });
    this->my_thread.swap(new_thread);
}

Thread *_Nonnull Thread::new_thread()
{
    return new Thread();
}

void Thread::yield()
{
    thrd_yield();
}

void Thread::detach()
{
    this->my_thread.detach();
}