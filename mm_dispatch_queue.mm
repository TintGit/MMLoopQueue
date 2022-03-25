
#include "mm_dispatch_queue.h"
#include <stdint.h>
#include <sstream>
#include <Foundation/Foundation.h>
namespace mm {

void DispatchTask::wait()
{
    std::unique_lock<std::mutex> lg(lock);
    cond_complete.wait(lg, [&](){
        return complete;
    });
}

void DispatchTask::signal()
{
    std::unique_lock<std::mutex> lg(lock);
    complete = true;
    cond_complete.notify_one();
}

DispatchQueue::DispatchQueue() = default;
DispatchQueue::~DispatchQueue() = default;

void DispatchQueue::create()
{
    if (_ready)
        return;
    
    _thread = std::thread(std::bind(&DispatchQueue::work_proc, this));
    _ready = true;
    _thread_id = _thread.get_id();
    
    printf("MMDispatchQueue::create() at : <%p>", std::this_thread::get_id());
}


void DispatchQueue::destroy()
{
    if (!_ready)
        return;
    {
        std::unique_lock<std::mutex> lg(_lock);
        _should_exit = true;
        _cond.notify_one();
    }
    _thread.join();
    
    _ready = false;
}

void DispatchQueue::runSync(DispatchTaskFunctor&& t)
{
    if (!_ready || !t)
        return;
    
    if (std::this_thread::get_id() == _thread_id) {
        t();
        return;
    }
    
    auto task = std::make_shared<DispatchTask>();
    task->functor = std::move(t);
    
    {
        std::unique_lock<std::mutex> lg(_lock);
        _tasks.emplace_back(task);
        _cond.notify_one();
    }
    
    task->wait();
}


DispatchTaskPtr DispatchQueue::runAsync(DispatchTaskFunctor&& t)
{
    if (!_ready || !t)
        return nullptr;
    
    auto task = std::make_shared<DispatchTask>();
    task->functor = std::move(t);
    
    {
        std::unique_lock<std::mutex> lg(_lock);
        _tasks.emplace_back(task);
        _cond.notify_one();
    }
    
    return task;
}


void DispatchQueue::setName(const char* name)
{
    _name = std::string("MMDispatchQueue_") + name;
}



void DispatchQueue::work_proc() {
    //    ThreadUtil::SetThreadName(_name.c_str());
    [[NSThread currentThread] setName:@(_name.c_str())];
    
    printf("MMDispatchQueue::work_proc() at : <%p>", std::this_thread::get_id());
    
    while (true) {
        
        DispatchTaskPtr ptask;
        {
            std::unique_lock<std::mutex> lg(_lock);
            _cond.wait(lg, [&](){
                return !_tasks.empty() || _should_exit;
            });
            
            if (_should_exit) {
                break;
            }
            
            ptask = _tasks.front();
            _tasks.pop_front();
        }
        ptask->functor();
        
        
        ptask->signal();
        
    }
}

}
