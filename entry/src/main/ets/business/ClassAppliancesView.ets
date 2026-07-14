/**
 * =============================================================================
 *  ClassAppliancesView - 电器分类瀑布流视图组件
 * =============================================================================
 * 【作用】
 *   展示"电器"分类下的商品列表，使用 WaterFlow 瀑布流实现高度自适应、错落布局。
 *
 * 【与 ClassClothesView 的区别】
 *   ┌────────────────┬────────────────────┬──────────────────────┐
 *   │                │  ClassClothesView   │  ClassAppliancesView │
 *   ├────────────────┼────────────────────┼──────────────────────┤
 *   │ 数据源          │  ClothesDataSource │  AppliancesDataSource│
 *   │ 数据量          │  23 件服装          │  15 件电器            │
 *   │ 背景色          │  黄色(Yellow)       │  粉色(Pink)           │
 *   └────────────────┴────────────────────┴──────────────────────┘
 *
 * 【WaterFlow 使用要点】
 *   1. 必须使用 LazyForEach 驱动数据渲染（不能用 ForEach）
 *   2. columnsTemplate 定义列数（3 列等宽）
 *   3. 每个 FlowItem 的高度由内容自动决定（自适应）
 *   4. columnsGap / rowsGap 控制条目间距
 * =============================================================================
 */

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，包含 pic/name/desc/price 四个属性

import { AppliancesDataSource } from '../entity/AppliancesDataSource';
// AppliancesDataSource: 电器商品数据源，实现 IDataSource 接口
// 内部通过 GoodsInfo.getDefaultAppi() 获取 15 条电器商品数据

/**
 * 电器分类瀑布流视图组件
 * 使用 WaterFlow 展示 15 件电器商品的瀑布流列表
 */
@Component
export struct ClassAppliancesView {
  /**
   * 电器商品瀑布流数据源实例
   * 在声明时直接初始化，AppliancesDataSource 内部调用 GoodsInfo.getDefaultAppi()
   * 获取 15 件电器商品（图片命名 dian01~dian15，名称如"双十一""大聚惠"）
   */
  private dataSource: AppliancesDataSource = new AppliancesDataSource();

  /**
   * 构建 UI
   * 三列瀑布流布局，展示电器商品图片和名称
   */
  build() {
    // WaterFlow 瀑布流容器
    WaterFlow() {
      /**
       * LazyForEach 懒加载循环
       * WaterFlow 必须使用 LazyForEach 实现懒加载：
       *   - 只渲染屏幕上可见的 FlowItem
       *   - 滚动时动态创建新条目、回收离开可见区域的条目
       *
       * 参数说明：
       *   dataSource - AppliancesDataSource 实例（实现 IDataSource）
       *   (item: GoodsInfo) => { ... } - 每个条目的 UI 构建函数
       */
      LazyForEach(this.dataSource, (item: GoodsInfo) => {
        // FlowItem：单个瀑布流条目
        FlowItem() {
          // Column 容器：纵向排列图片 + 名称
          Column() {
            // 电器商品图片
            Image($r(item.pic))               // 通过 $r() 编译期引用加载图片
              .width('100%')                   // 宽度撑满列宽
              .objectFit(ImageFit.Contain)     // Contain：保持比例完整显示

            // 电器商品名称（如"双十一""大聚惠"等趣味名称）
            Text(item.name)
              .fontSize(18)   // 字号 18
          }
        }
        .width('100%')                         // 宽度撑满列宽
        .padding(0)                            // 无边距
        .backgroundColor(Color.White)          // 白色背景
      })
    }
    .columnsTemplate('1fr 1fr 1fr')  // 等宽三列瀑布流（1:1:1）
    .columnsGap(2)                   // 列间距 2
    .rowsGap(2)                      // 行间距 2
    .padding(2)                      // 外边距 2
    .backgroundColor(Color.Pink)     // 粉色背景（便于与服装分类的黄色区分）
    .scrollBar(BarState.Auto)        // 滚动条自动显示
  }
}
