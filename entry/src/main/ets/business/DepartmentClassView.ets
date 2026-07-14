/**
 * =============================================================================
 *  DepartmentClassView - 分类页视图组件（内嵌二级 Tabs）
 * =============================================================================
 * 【作用】
 *   商城"分类"页签的内容视图，内部嵌套二级 Tabs 页签，
 *   提供"服装"和"电器"两个子分类切换，使用 SubTabBarStyle 顶部子页签样式。
 *
 * 【Tabs 嵌套层级】
 *   主 Tabs（Index.ets）：首页 | 分类 | 购物车
 *       ↓
 *   子 Tabs（本组件）：服装 | 电器
 *       ↓
 *   ClassClothesView（服装 WaterFlow 瀑布流）
 *   ClassAppliancesView（电器 WaterFlow 瀑布流）
 *
 * 【SubTabBarStyle】
 *   使用 SubTabBarStyle.of('服装') 创建带下划线指示器的子页签样式，
 *   与底部主 Tabs（LightFlowTabBar）的样式风格不同，便于视觉区分。
 * =============================================================================
 */

import { ClassClothesView } from '../business/ClassClothesView';
// ClassClothesView: 服装分类瀑布流视图组件，使用 WaterFlow 展示 23 件服装商品

import { ClassAppliancesView } from '../business/ClassAppliancesView';
// ClassAppliancesView: 电器分类瀑布流视图组件，使用 WaterFlow 展示 15 件电器商品

/**
 * 分类页视图组件
 * 内嵌二级 Tabs：服装 / 电器，每个 Tab 展示对应的 WaterFlow 瀑布流商品
 */
@Component
export struct DepartmentClassView {
  /**
   * 当前选中的子页签序号
   * 0 = 服装，1 = 电器
   * @State 装饰：值变化时自动刷新 UI
   * $$this.current 双向绑定：Tabs 滑动/点击时自动更新 current
   */
  @State current: number = 0;

  /**
   * 构建二级分类 UI
   * Tabs(BarPosition.Start)：页签栏放在内容区域顶部
   * SubTabBarStyle.of()：创建带下划线指示器的子页签样式
   */
  build() {
    // Tabs 容器：barPosition=Start → 页签栏在顶部
    // index=$$this.current → 双向绑定，用户滑动或点击时自动更新
    Tabs({ barPosition: BarPosition.Start, index: $$this.current }) {
      // === 子页签一：服装 ===
      TabContent() {
        // 服装瀑布流视图（WaterFlow + ClothesDataSource）
        ClassClothesView()
      }
      .tabBar(SubTabBarStyle.of('服装'))  // 使用 SubTabBarStyle 创建"服装"子页签

      // === 子页签二：电器 ===
      TabContent() {
        // 电器瀑布流视图（WaterFlow + AppliancesDataSource）
        ClassAppliancesView()
      }
      .tabBar(SubTabBarStyle.of('电器'))  // "电器"子页签，带下划线指示器
    }
    .vertical(false)                  // 水平方向排列页签（左右滑动切换）
    .width('100%').height('100%')     // 宽度和高度均撑满父容器
    .barWidth('100%').barHeight(60)   // 页签栏宽度 100%，高度 60
  }
}
