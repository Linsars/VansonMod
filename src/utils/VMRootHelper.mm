// VMRootHelper — persona 提权 spawn 通用件 (P0.6)
#import "VMRootHelper.h"
#import "VMLog.h"
#import <spawn.h>
#import <sys/wait.h>
#import <mach-o/dyld.h>
#import <sys/stat.h>
#import <signal.h>
#import <unistd.h>

// persona API 不在公开 SDK 头文件 — 符号在 libsystem_kernel, 值抄 XNU spawn_internal.h
extern "C" {
int posix_spawnattr_set_persona_np(posix_spawnattr_t *, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(posix_spawnattr_t *, uid_t);
int posix_spawnattr_set_persona_gid_np(posix_spawnattr_t *, gid_t);
}
#define POSIX_SPAWN_PERSONA_FLAGS_NONE   0x00000001
#define POSIX_SPAWN_PERSONA_FLAGS_VERIFY 0x00010000

extern char **environ;

@implementation VMRootHelper

+ (BOOL)selfPath:(char *)out size:(uint32_t)size {
  return _NSGetExecutablePath(out, &size) == 0;
}

+ (pid_t)spawnSelf:(NSArray<NSString *> *)args verify:(BOOL)verify {
  char exe[4096];
  if (![self selfPath:exe size:sizeof(exe)]) {
    VMLOG_ERROR(@"[rootspawn] self path FAIL");
    return -1;
  }

  posix_spawnattr_t attr;
  posix_spawnattr_init(&attr);
  uint32_t flags = verify ? POSIX_SPAWN_PERSONA_FLAGS_VERIFY
                          : POSIX_SPAWN_PERSONA_FLAGS_NONE;
  posix_spawnattr_set_persona_np(&attr, 99, flags);
  posix_spawnattr_set_persona_uid_np(&attr, 0);
  posix_spawnattr_set_persona_gid_np(&attr, 0);

  // argv: exe + args (all cstrings)
  const char *argv[args.count + 2];
  argv[0] = exe;
  for (NSUInteger i = 0; i < args.count; i++)
    argv[i + 1] = args[i].fileSystemRepresentation;
  argv[args.count + 1] = NULL;

  pid_t child = 0;
  int rc = posix_spawn(&child, exe, NULL, &attr, (char *const *)argv, environ);
  posix_spawnattr_destroy(&attr);
  if (rc != 0) {
    VMLOG_ERROR(@"[rootspawn] posix_spawn rc=%d verify=%d", rc, verify);
    return -1;
  }
  return child;
}

+ (pid_t)spawnSelfDaemon {
  pid_t c = [self spawnSelf:@[ @"-daemon" ] verify:YES];
  if (c > 0) {
    VMLOG_INFO(@"[rootspawn] daemon child=%d (verify)", c);
    return c;
  }
  c = [self spawnSelf:@[ @"-daemon" ] verify:NO];
  VMLOG_INFO(@"[rootspawn] daemon child=%d (none)", c);
  return c;
}

+ (int)spawnRootKill:(pid_t)pid {
  int r = -1;
  pid_t c = [self spawnSelf:@[ @"-vmkill", [NSString stringWithFormat:@"%d", pid] ]
                     verify:YES];
  if (c > 0) {
    int st = 0;
    waitpid(c, &st, 0);
    r = WIFEXITED(st) ? WEXITSTATUS(st) : -2;
  }
  if (r != 0) {
    c = [self spawnSelf:@[ @"-vmkill",
                           [NSString stringWithFormat:@"%d", pid] ]
                 verify:NO];
    if (c > 0) {
      int st = 0;
      waitpid(c, &st, 0);
      r = WIFEXITED(st) ? WEXITSTATUS(st) : -2;
    }
  }
  VMLOG_INFO(@"[rootspawn] vmkill pid=%d exit=%d", pid, r);
  return r;
}

#pragma mark - Daemon Heartbeat

+ (NSDictionary *)readDaemonHeartbeat {
  FILE *f = fopen(VM_DAEMON_HB_CSTR, "r");
  if (!f)
    return nil;
  char line[256];
  int pid = 0;
  char build[64] = "";
  char path[1024] = "";
  long long boot = 0;
  while (fgets(line, sizeof(line), f)) {
    sscanf(line, "pid=%d", &pid);
    sscanf(line, "build=%63s", build);
    sscanf(line, "boot=%lld", &boot);
  }
  fclose(f);

  // pid 活性 + 心跳新鲜 (25s = 5s 周期 × 5 容忍)
  if (pid <= 0 || kill(pid, 0) != 0)
    return nil;
  struct stat st;
  if (stat(VM_DAEMON_HB_CSTR, &st) != 0 ||
      time(NULL) - st.st_mtime > 25)
    return nil;

  // 二进制路径反查 (识别旧版本孤儿)
  char pbuf[PROC_PIDPATHINFO_MAXSIZE];
  if (proc_pidpath(pid, pbuf, sizeof(pbuf)) > 0)
    strlcpy(path, pbuf, sizeof(path));

  return @{ @"pid" : @(pid),
            @"build" : [NSString stringWithUTF8String:build],
            @"path" : [NSString stringWithUTF8String:path] };
}

+ (void)requestDaemonStop {
  FILE *f = fopen(VM_DAEMON_STOP_CSTR, "w");
  if (f)
    fclose(f);
}

@end
