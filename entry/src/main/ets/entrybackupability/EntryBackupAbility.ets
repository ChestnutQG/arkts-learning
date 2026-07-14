/**
 * =============================================================================
 *  EntryBackupAbility - 应用备份恢复扩展能力
 * =============================================================================
 * 【作用】
 *   继承自 BackupExtensionAbility，提供应用数据的备份和恢复回调。
 *   当用户通过系统设置备份/恢复应用数据时，系统会触发对应的方法。
 *
 * 【BackupExtensionAbility】
 *   HarmonyOS 提供的备份扩展基类，应用只需继承并实现：
 *     onBackup(bundleVersion?)  - 数据备份时触发
 *     onRestore(bundleVersion)  - 数据恢复时触发
 *
 * 【当前实现】
 *   默认空实现，仅记录日志。若应用有重要本地数据（如购物车数据库 cart_rdb.db），
 *   可在此导出/导入数据文件，实现应用数据跨设备迁移。
 *
 * 【注册方式】
 *   此类在 module.json5 的 extensionAbilities 数组中注册，
 *   系统通过 type: 'backup' 识别此扩展能力。
 * =============================================================================
 */

// ──── 导入模块 ────
import { hilog } from '@kit.PerformanceAnalysisKit';
// hilog: 高性能日志系统，用于记录备份/恢复事件

import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
// BackupExtensionAbility: 备份扩展基类，提供 onBackup / onRestore 可重写方法
// BundleVersion: 应用版本信息对象 { versionCode: number, versionName: string }

// ──── 日志常量 ────
/** 日志域标识，固定为 0x0000 */
const DOMAIN = 0x0000;

/** hilog 标签 */
const TAG = 'EntryBackupAbility';

/**
 * 应用备份恢复扩展能力类
 * 提供 onBackup（备份）和 onRestore（恢复）两个生命周期回调
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  /**
   * 数据备份回调
   * 当系统触发应用数据备份时调用，可在此导出数据库文件、配置文件等。
   * async 表示异步方法，可以在此执行文件 I/O 等耗时操作。
   *
   * @returns {Promise<void>} 备份完成后 resolve 的 Promise 对象
   */
  async onBackup() {
    // 输出备份开始日志，确认系统已触发备份流程
    hilog.info(DOMAIN, TAG, 'onBackup ok');
    // await Promise.resolve()：显式返回一个已完成的 Promise，表示备份完成
    // 若需要导出具体文件，可在此调用 context.getBackupDir() 获取备份目录
    await Promise.resolve();
  }

  /**
   * 数据恢复回调
   * 当系统触发应用数据恢复时调用，可在此导入之前备份的数据文件。
   *
   * @param bundleVersion - 备份时的应用版本信息，包含 versionCode 和 versionName
   *                        可用于判断是否需要进行数据格式迁移（如数据库表结构变更）
   * @returns {Promise<void>} 恢复完成后 resolve 的 Promise 对象
   */
  async onRestore(bundleVersion: BundleVersion) {
    // 输出恢复事件日志，包含备份时的版本信息，便于调试
    // JSON.stringify 将 BundleVersion 对象序列化为可读字符串
    hilog.info(DOMAIN, TAG, 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
    // await Promise.resolve()：显式返回一个已完成的 Promise，表示恢复完成
    await Promise.resolve();
  }
}
