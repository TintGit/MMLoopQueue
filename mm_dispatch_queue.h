#ifndef TUTU_CORE_DISPATCH_QUEUE_H_
#define TUTU_CORE_DISPATCH_QUEUE_H_

#include <thread>
#include <mutex>
#include <condition_variable>
#include <deque>
#include <functional>
#include <memory>

namespace mm {

using DispatchTaskFunctor = std::function<void()>;

struct DispatchTask {

    DispatchTaskFunctor functor = nullptr;

    std::mutex lock;
    std::condition_variable cond_complete;
    bool complete {false};

    void wait();
    void signal();
};


using DispatchTaskPtr = std::shared_ptr<DispatchTask>;

class DispatchQueue final {
public:
    DispatchQueue();
    ~DispatchQueue();
    
    DispatchQueue(const DispatchQueue& other) = delete;
    DispatchQueue& operator=(const DispatchQueue& other) = delete;
    
    void create();
    void destroy();
    void setName(const char* name);
    
    void runSync(DispatchTaskFunctor&& t);
    DispatchTaskPtr runAsync(DispatchTaskFunctor&& t);

private:
    void work_proc();
        
private:
    
    std::thread _thread;
    std::thread::id _thread_id;
    std::string _name;
    bool _ready{false};
    
    std::mutex _lock;
    std::condition_variable _cond;
    //std::condition_variable _cond_complete;

    std::deque<DispatchTaskPtr> _tasks;
    bool _should_exit{false};
    
};

}

#endif
