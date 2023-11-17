// #include "threadqueue.h"

// this too
/* template <typename T>
optional<T> ThreadSafeQueue<T>::dequeue()
{ */
    /* unique_lock ul{mtx};
    cv.wait(ul, [&]()
            { return !list.empty(); });
    if (list.empty())
        return nullopt;
    auto val = list.front();
    index--;
    list.pop();
    return val; */
    /*  lock_guard lg{mtx};
     if (list.size() == 0)
         finished = true;
     return nullopt;
     auto val = list.front();
     index--;
     list.pop();
      //pop front for vector
      //pop front
      //list.erase(list.begin());
     return val; */
//}

/* template <typename T>
void ThreadSafeQueue<T>::enqueue(T value)
{
    lock_guard lg{mtx};
    list.push(value);
    cv.notify_one();
    index++;
} */

// caused an erroe
/* template <typename T>
int ThreadSafeQueue<T>::length()
{
    lock_guard lg{mtx};
    return list.size();
} */
