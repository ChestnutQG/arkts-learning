/**
 * =============================================================================
 *  NavigationItem - 导航项的数据模型类
 * =============================================================================
 * 【作用】
 *   定义底部导航栏中每个 Tab 所需的数据结构：id（唯一标识）、text（显示文本）、
 *   icon（未选中图标）、activeIcon（选中图标）。
 *   一个 NavigationItem 实例就代表导航栏中的一个 Tab（如"首页""分类""购物车"）。
 *
 * 【使用场景】
 *   在 Index.ets 中创建 NavigationItem[] 数组，传递给 LightFlowTabBar 组件，
 *   驱动其渲染对应的 Tab 图标和文字。
 *
 * 【Resource 类型】
 *   Resource 是 HarmonyOS 中引用资源文件的编译期类型（如 $r('app.media.xxx')），
 *   指向 resources 目录下的媒体/字符串/颜色等资源文件。
 * =============================================================================
 */

/**
 * 导航项数据模型类
 * 每条记录包含：id、text、icon（未选中）、activeIcon（选中）
 */
export class NavigationItem {
  /** 唯一标识符，用于区分不同的 Tab（如 'home'/'category'/'cart'），也用于 ForEach key 绑定 */
  id: string = '';

  /** 页签的显示文本，直接显示在图标下方，如 "首页"、"分类"、"购物车" */
  text: string = '';

  /**
   * 未选中状态下的图标资源引用
   * 如 $r('app.media.tab_first_normal') 指向 resources/base/media/ 中的灰显图标
   * 默认值为 'app.media.startIcon'（仅占位，实际由父组件传入）
   */
  icon: Resource = $r('app.media.startIcon');

  /**
   * 选中状态下的图标资源引用
   * 如 $r('app.media.tab_first_pressed') 指向 resources 中的高亮图标
   * 默认值为 'app.media.startIcon'（仅占位，实际由父组件传入）
   */
  activeIcon: Resource = $r('app.media.startIcon');

  /**
   * 构造一个导航项实例
   *
   * @param id         - 唯一标识符，用于 key 值绑定和调试区分
   * @param text       - 页签显示文本，渲染在图标下方
   * @param icon       - 未选中时的图标资源（灰显/非激活态）
   * @param activeIcon - 选中时的图标资源（高亮/激活态）
   */
  constructor(id: string, text: string, icon: Resource, activeIcon: Resource) {
    this.id = id;               // 保存唯一标识
    this.text = text;           // 保存显示文本
    this.icon = icon;           // 保存未选中图标
    this.activeIcon = activeIcon; // 保存选中图标
  }
}
