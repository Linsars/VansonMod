#import <UIKit/UIKit.h>
#import "src/core/VMAppDelegate.h"
#import "src/utils/VMLog.h"
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>

// P0.5: one-shot root 执行分支 — persona spawn 的子进程从这进, 杀完即退不驻留
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
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([VMAppDelegate class]));
    }
}
