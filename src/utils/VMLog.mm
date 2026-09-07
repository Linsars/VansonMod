#import "VMLog.h"
#import <string.h>
#import <sys/stat.h>

static NSString *const kVMDebugKey = @"vmDebugLog";
static const uint64_t kVMLogRotateBytes = 256 * 1024; // 256KB 截半
static const uint64_t kVMLogKeepBytes = 128 * 1024;

#ifndef VM_BUILD_COMMIT
#define VM_BUILD_COMMIT "unknown"
#endif

static dispatch_queue_t VMLogQueue(void) {
  static dispatch_queue_t q;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ q = dispatch_queue_create("vm.log.sink", DISPATCH_QUEUE_SERIAL); });
  return q;
}

@implementation VMLog

+ (NSString *)logFilePath {
  static NSString *path;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSString *docs = [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    path = [docs stringByAppendingPathComponent:@"vm_debug.log"];
  });
  return path;
}

// 文件为空或不存在时打 build marker + 会话头 (每次启动都会留一行, 假包一眼现形)
+ (void)writeBuildMarkerIfNeeded {
  dispatch_async(VMLogQueue(), ^{
    NSString *path = [self logFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
    if ([attr fileSize] > 0) {
      // 已有内容: 只补一行会话头, 保持可追溯
      [self writeLineLocked:[NSString
          stringWithFormat:@"--- session %s build=%s ---", __DATE__, VM_BUILD_COMMIT]];
      return;
    }
    [self writeLineLocked:[NSString
        stringWithFormat:@"vm-build-%s (%s)", VM_BUILD_COMMIT, __DATE__]];
  });
}

// 核心写出口: 串行队列, 直接 fwrite 文件 (禁 NSLog)
+ (void)writeLineLocked:(NSString *)line {
  static int writeCount = 0;
  if (++writeCount % 32 == 0)
    [self rotateLocked];

  static NSDateFormatter *fmt;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM-dd HH:mm:ss";
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  });

  NSString *out = [NSString stringWithFormat:@"[%@] %@\n",
                                            [fmt stringFromDate:[NSDate date]],
                                            line];
  FILE *fp = fopen([[self logFilePath] fileSystemRepresentation], "a");
  if (!fp)
    return; // 打不开就不打, 不崩不卡
  fwrite(out.UTF8String, 1, strlen(out.UTF8String), fp);
  fclose(fp);
}

+ (void)log:(NSString *)level format:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  dispatch_async(VMLogQueue(), ^{
    [self writeLineLocked:[NSString stringWithFormat:@"%@ %@", level, msg]];
  });
}

// debug 级: vmDebugLog=OFF 直接丢弃
+ (void)debug:(NSString *)fmt, ... {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kVMDebugKey])
    return;
  va_list args;
  va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  dispatch_async(VMLogQueue(), ^{
    [self writeLineLocked:[@"DEBUG " stringByAppendingString:msg]];
  });
}

+ (void)rotateIfNeeded {
  dispatch_async(VMLogQueue(), ^{
    [self rotateLocked];
  });
}

+ (void)rotateLocked {
  NSString *path = [self logFilePath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
  uint64_t size = [attr fileSize];
  if (size <= kVMLogRotateBytes)
    return;

  // 截半: 保留尾部一半
  NSFileHandle *h = [NSFileHandle fileHandleForReadingAtPath:path];
  if (!h)
    return;
  [h seekToFileOffset:size - kVMLogKeepBytes];
  NSData *tail = [h readDataToEndOfFile];
  [h closeFile];

  NSString *tmp = [path stringByAppendingString:@".tmp"];
  [tail writeToFile:tmp atomically:YES];
  [fm removeItemAtPath:path error:nil];
  [fm moveItemAtPath:tmp toPath:path error:nil];
  [self writeLineLocked:@"--- rotated ---"];
}

+ (uint64_t)purgeAll {
  __block uint64_t freed = 0;
  dispatch_sync(VMLogQueue(), ^{
    NSString *path = [self logFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
    freed = [attr fileSize];
    [fm removeItemAtPath:path error:nil];
    [fm removeItemAtPath:[path stringByAppendingString:@".tmp"] error:nil];
  });
  return freed;
}

@end
