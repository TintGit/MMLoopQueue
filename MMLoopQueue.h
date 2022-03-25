//
//  MMLoopThread.h
//  OpenGLES
//
//  Created by 言有理 on 2022/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^thread_block_t)(void);

@interface MMLoopQueue : NSObject
- (instancetype)initWithName:(NSString *)name;

- (void)dispatch_sync:(thread_block_t)block;

- (void)dispatch_async:(thread_block_t)block;
@end

NS_ASSUME_NONNULL_END
