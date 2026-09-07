#import "VMInboxBridge.h"
#import "../VMLog.h"
#import "include/VMMemoryEngine.h"
#import "VMScriptManager.h"
#import <fcntl.h>
#import <unistd.h>

static const NSTimeInterval kStableAge = 1.5;        // 文件静置阈值(s): scp 写完才算
static const NSTimeInterval kStaleRunning = 600.0;   // .running 超时视为死任务(s)
static const NSUInteger kHeaderScanLines = 12;       // vm-target 头扫描行数

static NSString *VMInboxPrefKey = @"vmBridgeEnabled";
static const void *VMInboxQueueKey = &VMInboxQueueKey;

@implementation VMInboxBridge {
  dispatch_queue_t _q;
  dispatch_source_t _src;
  NSTimer *_safetyTimer;
  BOOL _busy;
  NSString *_busyJob;
  NSDate *_busySince;
  NSUInteger _jobsDone;
  NSString *_lastJobName;
  NSString *_lastJobState;
  NSString *_lastJobTime;
}

+ (instancetype)shared {
  static VMInboxBridge *s;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ s = [[self alloc] initPrivate]; });
  return s;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _q = dispatch_queue_create("vm.inbox.bridge", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_q, VMInboxQueueKey, (void *)1, NULL);
    _jobsDone = 0;
  }
  return self;
}

- (instancetype)init {
  return [self initPrivate];
}

+ (NSString *)inboxPath {
  static NSString *path;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSString *docs = [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    path = [docs stringByAppendingPathComponent:@"vm_inbox"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
  });
  return path;
}

#pragma mark - Lifecycle

- (void)start {
  dispatch_async(_q, ^{
    if (self->_src)
      return; // 已在跑
    if (![[NSUserDefaults standardUserDefaults] boolForKey:VMInboxPrefKey])
      return;

    NSString *dir = [VMInboxBridge inboxPath];
    int fd = open(dir.fileSystemRepresentation, O_EVTONLY);
    if (fd >= 0) {
      dispatch_source_t src = dispatch_source_create(
          DISPATCH_SOURCE_TYPE_VNODE, fd,
          DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, self->_q);
      dispatch_source_set_event_handler(src, ^{
        [self scanWithDelay:0.0]; // VNODE 事件: 立即扫
      });
      dispatch_source_set_cancel_handler(src, ^{ close(fd); });
      dispatch_resume(src);
      self->_src = src;
    }

    // 2s 兜底扫描: VNODE 丢事件/外部直写都救得回
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_safetyTimer = [NSTimer
          scheduledTimerWithTimeInterval:2.0
                                 repeats:YES
                                   block:^(NSTimer *t) {
                                     dispatch_async(self->_q, ^{
                                       [self scanNow];
                                     });
                                   }];
    });

    [self recoverStaleLocked];
    VMLOG_INFO(@"[bridge] inbox ready %@", dir);
    dispatch_async(self->_q, ^{ [self scanNow]; });
  });
}

- (void)stop {
  dispatch_async(_q, ^{
    if (self->_src) {
      dispatch_source_cancel(self->_src);
      self->_src = nil;
    }
    if (self->_safetyTimer) {
      [self->_safetyTimer invalidate];
      self->_safetyTimer = nil;
    }
    VMLOG_INFO(@"[bridge] inbox stopped");
  });
}

- (void)scanWithDelay:(NSTimeInterval)delay {
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), _q, ^{
        [self scanNow];
      });
}

#pragma mark - Scan & Claim

- (void)scanNow {
  NSString *dir = [VMInboxBridge inboxPath];
  NSArray<NSString *> *names =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
  NSMutableArray<NSString *> *candidates = [NSMutableArray array];
  NSDate *now = [NSDate date];

  for (NSString *name in names) {
    if (![name hasSuffix:@".js"] || [name hasSuffix:@".js.done"])
      continue;
    NSString *full = [dir stringByAppendingPathComponent:name];
    NSDictionary *attr =
        [[NSFileManager defaultManager] attributesOfItemAtPath:full error:nil];
    NSDate *mod = [attr fileModificationDate];
    // 静置检测: scp/WebDAV 写完后才认领, 防读半截文件
    if (mod && [now timeIntervalSinceDate:mod] >= kStableAge)
      [candidates addObject:name];
  }
  [candidates sortUsingSelector:@selector(compare:)];

  for (NSString *name in candidates) {
    if (_busy)
      break; // 一次一个, 剩下的下轮扫
    [self claimJob:name];
  }
}

// 死任务恢复: 启动时把超时 .running 退回 .js
- (void)recoverStaleLocked {
  NSString *dir = [VMInboxBridge inboxPath];
  NSArray<NSString *> *names =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
  NSDate *now = [NSDate date];
  NSFileManager *fm = [NSFileManager defaultManager];
  for (NSString *name in names) {
    if (![name hasSuffix:@".js.running"])
      continue;
    NSString *full = [dir stringByAppendingPathComponent:name];
    NSDictionary *attr = [fm attributesOfItemAtPath:full error:nil];
    NSDate *mod = [attr fileModificationDate];
    NSString *base = [name substringToIndex:name.length - 8]; // 去 .running
    if (mod && [now timeIntervalSinceDate:mod] >= kStaleRunning) {
      NSString *back = [dir stringByAppendingPathComponent:base];
      [fm removeItemAtPath:back error:nil]; // 覆盖可能残留的 .js
      [fm moveItemAtPath:full toPath:back error:nil];
      VMLOG_WARN(@"[bridge] stale .running recovered: %@", base);
    } else {
      _busy = YES;
      _busyJob = [dir stringByAppendingPathComponent:base];
      _busySince = mod;
      [self armWatchdog];
      VMLOG_INFO(@"[bridge] adopt in-flight job %@", base);
    }
  }
}

#pragma mark - Job Pipeline

// 认领: job.js → job.running (原子), 桥唯一写手
- (void)claimJob:(NSString *)jsName {
  NSString *dir = [VMInboxBridge inboxPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *src = [dir stringByAppendingPathComponent:jsName];
  NSString *running = [src stringByAppendingString:@".running"];

  if (![fm moveItemAtPath:src toPath:running error:nil]) {
    return; // 别的写手抢先/已删, 下轮再看
  }

  NSString *base = [jsName substringToIndex:jsName.length - 3]; // 去 .js
  NSData *data = [NSData dataWithContentsOfFile:running];
  _busy = YES;
  _busyJob = [dir stringByAppendingPathComponent:base];
  _busySince = [NSDate date];
  _lastJobName = base;
  _lastJobState = @"running";

  VMLOG_INFO(@"[bridge] job claim %@ bytes=%lu", base, (unsigned long)data.length);

  if (!data) {
    [self finishJob:base log:@"[error] inbox file unreadable" ok:NO];
    return;
  }

  // 解析 vm-target 头: "// vm-target: <pid|auto>"
  NSString *body = [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
  if (!body)
    body = [[NSString alloc] initWithData:data
                                 encoding:NSUTF16StringEncoding];
  if (!body) {
    [self finishJob:base log:@"[error] not UTF-8/UTF-16 text" ok:NO];
    return;
  }

  pid_t pid = [self parseTargetPid:body];
  VMMemoryEngine *engine = [VMMemoryEngine shared];

  if (pid > 0 && pid != engine.targetPid) {
    BOOL ok = [engine attachToPid:pid];
    VMLOG_INFO(@"[bridge] attach pid=%d %@", pid, ok ? @"ok" : @"FAIL");
    if (!ok) {
      [self finishJob:base
                  log:[NSString stringWithFormat:
                                   @"[error] attach pid=%d failed "
                                   @"(task_for_pid denied or dead target)",
                                   pid]
                   ok:NO];
      return;
    }
  } else if (engine.targetPid == 0) {
    [self finishJob:base
                log:@"[error] no vm-target in header and nothing attached"
                ok:NO];
    return;
  }

  NSString *target = [NSString stringWithFormat:@"pid=%d", engine.targetPid];

  // 脚本体去掉头注释行再跑? 不去 — JS 注释无害, 原样执行保持行为一致
  __weak typeof(self) wself = self;
  NSString *job = base;
  [VMScriptManager.shared runScript:body
                         completion:^(NSString *log) {
                           typeof(wself) sself = wself;
                           [sself finishJob:job
                                        log:(log ?: @"(empty output)")
                                        ok:YES];
                         }];
  VMLOG_INFO(@"[bridge] job run %@ target=%@", job, target);
  [self armWatchdog];
}

- (pid_t)parseTargetPid:(NSString *)script {
  NSArray<NSString *> *lines =
      [script componentsSeparatedByCharactersInSet:
                  [NSCharacterSet newlineCharacterSet]];
  NSUInteger scanned = 0;
  for (NSString *raw in lines) {
    if (++scanned > kHeaderScanLines)
      break;
    NSString *line = [raw stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
    if (!line.length)
      continue;
    NSRange r = [line rangeOfString:@"vm-target:"];
    if (r.location == NSNotFound)
      continue;
    NSString *val =
        [[line substringFromIndex:NSMaxRange(r)]
            stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceCharacterSet]];
    if (val.length == 0 || [val.lowercaseString isEqualToString:@"auto"])
      return 0; // 用当前已挂目标
    return (pid_t)[val integerValue];
  }
  return 0;
}

// 看门狗: JS 死循环救不了, 但至少把 .running 落成 .done 别卡死队列
- (void)armWatchdog {
  __weak typeof(self) wself = self;
  NSString *job = _busyJob;
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kStaleRunning * NSEC_PER_SEC)),
      _q, ^{
        typeof(wself) sself = wself;
        if (!sself || !sself->_busy || ![sself->_busyJob isEqualToString:job])
          return;
        VMLOG_ERROR(@"[bridge] job TIMEOUT %@", job);
        [sself finishJob:[job lastPathComponent]
                     log:@"[error] watchdog timeout (script still running "
                         @"or hung; JS cannot be interrupted)"
                      ok:NO];
      });
}

// 收尾: 写 job.log + .running → .js.done + 清理旧产物
// (completion 回调在主线程, 统一折回 _q 保证 ivar 无竞争)
- (void)finishJob:(NSString *)base log:(NSString *)log ok:(BOOL)ok {
  if (!dispatch_get_specific(VMInboxQueueKey)) {
    dispatch_async(_q, ^{ [self finishJob:base log:log ok:ok]; });
    return;
  }
  NSString *dir = [VMInboxBridge inboxPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *running = [[dir stringByAppendingPathComponent:base]
      stringByAppendingString:@".js.running"];

  NSString *logPath = [[dir stringByAppendingPathComponent:base]
      stringByAppendingString:@".log"];
  [log writeToFile:logPath
          atomically:YES
            encoding:NSUTF8StringEncoding
               error:nil];

  [fm removeItemAtPath:running error:nil];
  NSString *done = [[dir stringByAppendingPathComponent:base]
      stringByAppendingString:@".js.done"];
  [fm createFileAtPath:done contents:[@"" dataUsingEncoding:NSUTF8StringEncoding]
             attributes:nil];

  _busy = NO;
  _busyJob = nil;
  _busySince = nil;
  _jobsDone++;
  _lastJobState = ok ? @"done" : @"failed";

  static NSDateFormatter *fmt;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss";
  });
  _lastJobTime = [fmt stringFromDate:[NSDate date]];

  VMLOG_INFO(@"[bridge] job %@ %@ (%@)", base, ok ? @"done" : @"FAILED",
             _lastJobTime);

  [VMInboxBridge trimArtifacts:dir];
}

// 产物轮转: .log/.done 按名字保留最近 50 对
+ (void)trimArtifacts:(NSString *)dir {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray<NSString *> *names = [fm contentsOfDirectoryAtPath:dir error:nil];
  NSMutableArray<NSString *> *artifacts = [NSMutableArray array];
  for (NSString *n in names) {
    if ([n hasSuffix:@".log"] || [n hasSuffix:@".js.done"] ||
        [n hasSuffix:@".js.running"])
      [artifacts addObject:n];
  }
  // 名字含时间戳时字典序=时间序
  [artifacts sortUsingSelector:@selector(compare:)];
  while (artifacts.count > 50) {
    NSString *n = artifacts.firstObject;
    [artifacts removeObjectAtIndex:0];
    [fm removeItemAtPath:[dir stringByAppendingPathComponent:n] error:nil];
  }
}

+ (NSUInteger)purgeArtifacts {
  NSString *dir = [self inboxPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray<NSString *> *names = [fm contentsOfDirectoryAtPath:dir error:nil];
  NSUInteger n = 0;
  for (NSString *name in names) {
    if ([name hasSuffix:@".log"] || [name hasSuffix:@".js.running"] ||
        [name hasSuffix:@".js.done"]) {
      if ([fm removeItemAtPath:[dir stringByAppendingPathComponent:name]
                         error:nil])
        n++;
    }
  }
  return n;
}

#pragma mark - Status

- (NSUInteger)jobsDone { return _jobsDone; }
- (NSString *)lastJobName { return _lastJobName ?: @"—"; }
- (NSString *)lastJobState { return _lastJobState ?: @"—"; }
- (NSString *)lastJobTime { return _lastJobTime ?: @"—"; }

@end
