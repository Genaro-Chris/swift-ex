#include "thread_header.h"
#include "stdlib.h"
#include "vector"
#include <iostream>

using namespace std;

uint zeroed()
{
    return 0;
}

CXX_Thread::CXX_Thread(FuncPtr _Nonnull with)
{
    this->my_thread = std::thread(
        [with]()
        {
            with();
        });
    std::cout << "Constructor called with " << zeroed() << std::endl;
}

void CXX_Thread::dynamicallyCall(vector<int> withArguments)
{
    std::cout << "Dynamically called this with " << zeroed() << std::endl;
}

CXX_Thread::~CXX_Thread()
{
    this->join_all();

    std::cout << "Destructor called with " << zeroed() << std::endl;
}

/// @brief  the thread ie wait for the thread to finish its execution
void CXX_Thread::join_all()
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

CXX_Thread *_Nonnull CXX_Thread::create(FuncPtr _Nonnull with)
{
    return new CXX_Thread(with);
}

void CXX_Thread::run(void(callback)(void const *value), void const *value)
{
    // this->detach();
    auto new_thread = std::thread(callback, value);
    this->my_thread.swap(new_thread);
}

void CXX_Thread::Run(void(callback)(void const *value, void const *newValue), void const *value, void const *newValue)
{
    std::thread(callback, value, newValue).join();
}

void CXX_Thread::RunOnce(void(callback)(void const *value), void const *value)
{
    std::thread(callback, value).join();
}

void CXX_Thread::swap_with(FuncPtr _Nonnull with)
{
    this->detach();
    auto new_thread = thread(
        [with]()
        {
            with();
        });
    this->my_thread.swap(new_thread);
}

CXX_Thread *_Nonnull CXX_Thread::new_thread()
{
    return new CXX_Thread();
}

void CXX_Thread::yield()
{
    thrd_yield();
}

void CXX_Thread::detach()
{
    this->my_thread.detach();
}