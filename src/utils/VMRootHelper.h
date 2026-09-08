// VMRootHelper — persona 提权 spawn + root 守护对账 (P0.6)
#import <Foundation/Foundation.h>

#define VM_DAEMON_HB_CSTR   "/var/mobile/Documents/vm_daemon.heartbeat"
#define VM_DAEMON_STOP_CSTR "/var/mobile/Documents/vm_daemon.stop"

@interface VMRootHelper : NSObject

// spawn 自身 exe + args, persona uid=root. verify=YES 校验 persona 存在.
// 返回 child pid, -1 失败
+ (pid_t)spawnSelf:(NSArray<NSString *> *)args verify:(BOOL)verify;

// 便捷: spawn 守护分支 (-daemon), VERIFY→NONE 自动兜底, 返回 child pid 或 -1
+ (pid_t)spawnSelfDaemon;

// one-shot root 杀手: spawn (-vmkill <pid>), 返回 exit code (0=已杀)
+ (int)spawnRootKill:(pid_t)pid;

// 自身可执行文件路径
+ (BOOL)selfPath:(char *)out size:(uint32_t)size;

// ===== 守护对账 (GUI 侧) =====
// 读心跳: 新鲜(≤25s)且 pid 活 → @{pid, path, build}; 否则 nil
+ (NSDictionary *)readDaemonHeartbeat;
// 写 stop 文件让 daemon 自杀 (2s 内生效)
+ (void)requestDaemonStop;

@end
