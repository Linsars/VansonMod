#import <Foundation/Foundation.h>

@interface VMRootHelper : NSObject
+ (int)spawnRootKill:(pid_t)pid;
@end
