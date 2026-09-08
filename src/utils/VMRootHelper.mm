// P0.5: persona 提权 one-shot root 执行助手
// 用途: kill 按钮/JS killPid 对 uid0 目标 EPERM+kr5 时的最终手段
// 纪律: 一次性子进程杀完即退, 不做守护驻留
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/wait.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import "VMLog.h"

// persona API 不在公开 SDK 头文件 — 符号在 libsystem_kernel 里, 手动声明 (值抄 XNU spawn_internal.h)
extern "C" {
int posix_spawnattr_set_persona_np(posix_spawnattr_t *, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(posix_spawnattr_t *, uid_t);
int posix_spawnattr_set_persona_gid_np(posix_spawnattr_t *, gid_t);
}
#define POSIX_SPAWN_PERSONA_FLAGS_NONE   0x00000001
#define POSIX_SPAWN_PERSONA_FLAGS_VERIFY 0x00010000

extern char **environ;

@interface VMRootHelper : NSObject
// 返回: 0=已杀 / 负=spawn 失败 / 3=子进程 kill 失败
+ (int)spawnRootKill:(pid_t)pid;
@end

@implementation VMRootHelper

+ (int)spawnOne:(BOOL)verifyPersona pid:(pid_t)pid exePath:(char *)exe {
  posix_spawnattr_t attr;
  posix_spawnattr_init(&attr);
  // RealBackstage 同款三件套: persona 99 + uid/gid 0 (VM 有 persona-mgmt entitlement)
  unsigned flags = verifyPersona ? POSIX_SPAWN_PERSONA_FLAGS_VERIFY
                                 : POSIX_SPAWN_PERSONA_FLAGS_NONE;
  posix_spawnattr_set_persona_np(&attr, 99, flags);
  posix_spawnattr_set_persona_uid_np(&attr, 0);
  posix_spawnattr_set_persona_gid_np(&attr, 0);

  char pidStr[16];
  snprintf(pidStr, sizeof(pidStr), "%d", pid);
  char *args[] = {exe, (char *)"-vmkill", pidStr, NULL};

  pid_t child = 0;
  int rc = posix_spawn(&child, exe, NULL, &attr, args, environ);
  posix_spawnattr_destroy(&attr);
  if (rc != 0) {
    VMLOG_ERROR(@"[rootspawn] posix_spawn rc=%d verify=%d", rc, verifyPersona);
    return -1;
  }

  int st = 0;
  waitpid(child, &st, 0);
  int code = WIFEXITED(st) ? WEXITSTATUS(st) : -2;
  VMLOG_INFO(@"[rootspawn] child=%d exit=%d verify=%d", child, code, verifyPersona);
  return code;
}

+ (int)spawnRootKill:(pid_t)pid {
  char exe[4096];
  uint32_t sz = sizeof(exe);
  if (_NSGetExecutablePath(exe, &sz) != 0)
    return -1;

  int r = [self spawnOne:YES pid:pid exePath:exe];
  if (r != 0)
    r = [self spawnOne:NO pid:pid exePath:exe]; // VERIFY 失败换 NONE 兜底
  return r;
}

@end
