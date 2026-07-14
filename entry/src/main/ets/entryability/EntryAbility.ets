/**
 * =============================================================================
 *  EntryAbility - 应用主 Ability（功能入口）
 * =============================================================================
 * 【作用】
 *   Ability 是 HarmonyOS 应用的基本功能单元（类似 Android 的 Activity）。
 *   EntryAbility 作为应用的主入口，负责应用初始化、窗口创建和页面加载。
 *
 * 【生命周期顺序】
 *   onCreate → onWindowStageCreate → onForeground（正常运行）
 *       ↓
 *   onBackground → onWindowStageDestroy → onDestroy
 *
 * 【日志说明】
 *   使用 hilog（HarmonyOS 高性能日志系统）在各生命周期中输出日志，
 *   开发阶段可通过 DevEco Studio 的 Logcat 面板观察执行顺序。
 * =============================================================================
 */

// ──── 导入 HarmonyOS SDK 模块 ────
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
// UIAbility:          Ability 基类，提供 onCreate/onForeground 等生命周期回调
// AbilityConstant:    Ability 相关常量（如 LaunchParam 启动原因）
// ConfigurationConstant: 配置相关常量（如 ColorMode 配色模式枚举）
// Want:               描述 Ability 启动参数的对象（类似 Intent）

import { hilog } from '@kit.PerformanceAnalysisKit';
// hilog: 高性能日志系统，支持格式化输出，比 console 更适合生产环境

import { window } from '@kit.ArkUI';
// window: 窗口管理模块，用于 loadContent（加载页面）和窗口属性设置

// ──── 日志常量 ────
/** 日志域标识，固定为 0x0000（系统预留域名，hilog 要求必须指定） */
const DOMAIN = 0x0000;

/** hilog 标签，用于在 Logcat 中过滤该 Ability 的日志 */
const TAG = 'EntryAbility';

/**
 * 应用主 Ability 类
 * 继承 UIAbility，实现应用级别的生命周期管理
 * default export 表示此文件导出默认类，被 module.json5 中的 abilities 引用
 */
export default class EntryAbility extends UIAbility {
  /**
   * Ability 创建时触发（整个生命周期只调用一次）
   * 在此做全局初始化：设置配色模式为"跟随系统"，支持亮/暗色自动切换
   *
   * @param want        - 启动当前 Ability 的 Want 信息（含 bundleName、abilityName 等参数）
   * @param launchParam - 启动参数（cold 冷启动 / warm 热启动）
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      // setColorMode：设置应用的配色模式
      // COLOR_MODE_NOT_SET：不固定，跟随系统设置自动切换亮色/暗色
      // COLOR_MODE_LIGHT：始终亮色模式  |  COLOR_MODE_DARK：始终暗色模式
      // getApplicationContext() 获取应用级上下文（生命周期与应用进程一致）
      this.context.getApplicationContext().setColorMode(
        ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      );
    } catch (err) {
      // hilog 格式化：%{public}s 表示该参数可公开打印（无隐私脱敏）
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // 输出 Ability 创建日志，%{public}s 格式化占位符
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  /**
   * Ability 销毁时触发（整个生命周期只调用一次）
   * 在此释放全局资源、取消全局订阅、清理图片缓存等
   */
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  /**
   * WindowStage 创建完成时触发
   * WindowStage 是窗口的阶段管理器，在此进行：
   *   1. loadContent：加载首屏页面（必须是 @Entry 页面）
   *   2. 设置窗口属性（方向、大小、全屏等）
   *   3. 注册窗口大小变化等事件监听
   *
   * @param windowStage - 窗口阶段管理器实例，负责页面的加载与窗口管理
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    // loadContent：将指定页面加载到窗口上
    // 第一个参数是页面路径（对应 main_pages.json 中注册的 pages 路由）
    // 第二个参数是回调函数，接收 { code, message } 错误对象
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        // 加载失败：输出错误详情，code 为错误码，message 为错误描述
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // 加载成功：输出成功日志，确认页面加载完成
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  /**
   * WindowStage 销毁时触发
   * 在此释放与窗口相关的 UI 资源和监听器（如窗口大小变化监听）
   */
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  /**
   * Ability 切换到前台时触发
   * 应用从后台回到前台时执行，适合在此恢复动画、重新获取焦点数据
   */
  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  /**
   * Ability 切换到后台时触发
   * 用户按 Home 键或切换到其他应用时执行，适合在此暂停动画、保存草稿数据
   */
  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
