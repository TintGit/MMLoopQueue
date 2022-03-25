//
//  MMLoopThread.m
//  OpenGLES
//
//  Created by 言有理 on 2022/3/25.
//

#import "MMLoopQueue.h"
#import "mm_dispatch_queue.h"
@interface MMLoopQueue() {
    mm::DispatchQueue _que;
}
@end

@implementation MMLoopQueue

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _que.setName(name.UTF8String);
        _que.create();
    }
    return self;
}

- (void)dispatch_sync:(thread_block_t)block {
    _que.runSync([&] {
        block();
    });
}

- (void)dispatch_async:(thread_block_t)block {
    _que.runAsync([&] {
        block();
    });
}

- (void)dealloc {
    _que.destroy();
}
@end
