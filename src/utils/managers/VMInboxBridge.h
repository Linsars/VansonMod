// VMInboxBridge — 远程调试桥收件箱 (P0)
// 数据流: iSH scp job.js → Documents/vm_inbox/ → 稳定检测 → 认领(.running)
//        → 解析 // vm-target: <pid> → attachToPid → runScript → job.log → .js.done
// 认证层 = 通道本身 (SSH/token 能写进沙盒即已可信), 桥不加第二层
#import <Foundation/Foundation.h>

@interface VMInboxBridge : NSObject

+ (instancetype)shared;

// 幂等启动: 建目录 + 装 VNODE 监听 + 2s 兜底扫描 + 读取偏好决定启停
- (void)start;
- (void)stop;

// 收件箱绝对路径 (沙盒 Documents/vm_inbox)
+ (NSString *)inboxPath;

// 设置页状态行用
- (NSUInteger)jobsDone;
- (NSString *)lastJobName;  // 最近一次任务的文件名(不含扩展)
- (NSString *)lastJobState; // done / failed / running
- (NSString *)lastJobTime;  // HH:mm:ss

// 清理: 删除全部 .log/.done/.running 产物 (返回删除文件数)
+ (NSUInteger)purgeArtifacts;

@end
