#import <UIKit/UIKit.h>
#import "src/core/VMAppDelegate.h"
#import "src/utils/VMLog.h"
#import "src/utils/VMRootHelper.h"
#import "src/utils/managers/VMInboxBridge.h"
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

// ===== P0.6 daemon 分支: persona spawn 的 root 子进程从这进 =====
// 职责: 唯一职责 = 远程调试桥. 无 UI 无 scene, 音频保活不需要 (root 不受
// app 生命周期管辖). 心跳文件 5s 一跳; 收到 stop 文件 → 清场自杀.

#define VM_DAEMON_HEARTBEAT "/var/mobile/Documents/vm_daemon.heartbeat"
#define VM_DAEMON_STOP      "/var/mobile/Documents/vm_daemon.stop"

static NSTimer *vmDaemonHeartbeatTimer = nil;
int vmDaemonMode = 0; // VMScriptManager toast 等查此标志在 daemon 中禁 UI

static void vmDaemonHeartbeat(void) {
  FILE *f = fopen(VM_DAEMON_HEARTBEAT, "w");
  if (f) {
    fprintf(f, "pid=%d\nbuild=" VM_BUILD_COMMIT "\nboot=%lld\n", getpid(),
            (long long)time(NULL));
    fclose(f);
  }
}

static void vmDaemonStopWatch(void) {
  struct stat st;
  if (stat(VM_DAEMON_STOP_CSTR, &st) == 0) {
    VMLOG_INFO(@"[daemon] stop file seen, exiting");
    unlink(VM_DAEMON_STOP_CSTR);
    unlink(VM_DAEMON_HB_CSTR);
    exit(0);
  }
}

static int vmDaemonBranch(void) {
  vmDaemonMode = 1;
  VMLOG_INFO(@"[daemon] enter root daemon branch, pid=%d", getpid());
  // 守护进程独立 defaults 域内存注册 (plist 未落键时默认全 ON)
  [[NSUserDefaults standardUserDefaults]
      registerDefaults:@{@"vmBridgeEnabled" : @YES, @"vmDaemonEnabled" : @YES}];
  [[VMInboxBridge shared] start];

  vmDaemonHeartbeat();
  [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES
                                   block:^(NSTimer *){ vmDaemonHeartbeat(); }];
  [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES
                                   block:^(NSTimer *){ vmDaemonStopWatch(); }];
  // 偏好开关变更传导: start 幂等, 每 10s 补拉
  [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:YES
                                   block:^(NSTimer *){
                                     [[VMInboxBridge shared] start];
                                   }];

  // root 进程也要跑 runloop (dispatch/timer 源在这上面活)
  [[NSRunLoop mainRunLoop] run];
  return 0;
}

// ===== one-shot root kill 分支 =====
static int vmRootExecBranch(int argc, char *argv[]) {
  for (int i = 1; i < argc - 1; i++) {
    if (strcmp(argv[i], "-vmkill") == 0) {
      pid_t target = (pid_t)atoi(argv[i + 1]);
      int rc = kill(target, SIGKILL);
      VMLOG_INFO(@"[vmkill-child] pid=%d rc=%d errno=%d(%s)", target, rc,
                 rc ? errno : 0, rc ? strerror(errno) : "ok");
      return rc == 0 ? 0 : 3;
    }
  }
  return -1;
}

int main(int argc, char * argv[]) {
    int branchRc = vmRootExecBranch(argc, argv);
    if (branchRc >= 0)
        return branchRc;
    if (argc > 1 && strcmp(argv[1], "-daemon") == 0) {
        @autoreleasepool {
            return vmDaemonBranch();
        }
    }
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([VMAppDelegate class]));
    }
}
