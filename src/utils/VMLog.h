// VMLog — 单点日志出口 (P0 红线: 全部落盘只走这里, 禁 NSLog)
// 沙盒 Documents/vm_debug.log; >256KB 截半轮转; vmDebugLog 开关控全量/精简
#import <Foundation/Foundation.h>

#define VMLOG_INFO(fmt, ...)  [VMLog log:@"INFO" fmt:(fmt), ##__VA_ARGS__]
#define VMLOG_WARN(fmt, ...)  [VMLog log:@"WARN" fmt:(fmt), ##__VA_ARGS__]
#define VMLOG_ERROR(fmt, ...) [VMLog log:@"ERROR" fmt:(fmt), ##__VA_ARGS__]
// debug 级: 仅 vmDebugLog=ON 时落盘 (全量操作边界)
#define VMLOG_DEBUG(fmt, ...) [VMLog debug:(fmt), ##__VA_ARGS__]

@interface VMLog : NSObject

+ (void)log:(NSString *)level fmt:(NSString *)fmt, ...NS_FORMAT_FUNCTION(2, 3);
+ (void)debug:(NSString *)fmt, ...NS_FORMAT_FUNCTION(1, 2);

// 落盘路径 (沙盒 Documents/vm_debug.log)
+ (NSString *)logFilePath;

// 手动截半轮转 (设置页清理按钮复用)
+ (void)rotateIfNeeded;

// 一键清理 (返回删除字节数)
+ (uint64_t)purgeAll;

// build marker (防装旧包): 首行 vm-build-<commit>
+ (void)writeBuildMarkerIfNeeded;

@end
