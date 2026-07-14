/**
 * =============================================================================
 *  ClassClothesView - 服装分类瀑布流视图组件
 * =============================================================================
 * 【作用】
 *   展示"服装"分类下的商品列表，使用 WaterFlow 瀑布流实现高度自适应、
 *   错落有致的视觉效果。配合 LazyForEach + ClothesDataSource 实现懒加载。
 *
 * 【WaterFlow 瀑布流特性】
 *   1. 高度自适应：每个 FlowItem 的高度由内容决定，自动错落排列
 *   2. 懒加载：必须使用 LazyForEach（不能用 ForEach），只渲染可见区域
 *   3. 分列布局：columnsTemplate 指定 3 列等宽
 *
 * 【数据流】
 *   GoodsInfo.getDefaultClot()           ← 静态工厂（23 条服装数据）
 *     → ClothesDataSource.dataArray      ← 声明时初始化
 *       → LazyForEach 按需读取            ← 懒加载
 *         → FlowItem { Image + Text }    ← 渲染每个商品
 * =============================================================================
 */

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，包含 pic（图片路径）/ name（名称）/ desc（描述）/ price（价格）

import { ClothesDataSource } from '../entity/ClothesDataSource';
// ClothesDataSource: 服装商品数据源，实现 IDataSource 接口
// 内部通过 GoodsInfo.getDefaultClot() 获取 23 条服装商品数据

/**
 * 服装分类瀑布流视图组件
 * 使用 WaterFlow 展示 23 件服装商品的瀑布流列表
 */
@Component
export struct ClassClothesView {
  /**
   * 服装商品瀑布流数据源实例
   * 在声明时直接初始化，ClothesDataSource 内部调用 GoodsInfo.getDefaultClot()
   * 获取 23 件服装商品（图片命名 skirt01~skirt23，名称如"促销价""惊爆价"）
   */
  private dataSource: ClothesDataSource = new ClothesDataSource();

  /**
   * 构建 UI
   * 三列瀑布流布局（WaterFlow），每个 FlowItem 展示商品图片 + 名称
   */
  build() {
    // WaterFlow 瀑布流容器：高度自动撑满父容器，内部条目高度自适应
    WaterFlow() {
      /**
       * LazyForEach 懒加载循环
       * 注意：WaterFlow 必须配合 LazyForEach 使用，不能用 ForEach！
       * ForEach 会一次性渲染所有数据，数据量大时导致性能问题。
       * LazyForEach 只渲染可见区域的 FlowItem，滚动时动态创建/回收。
       *
       * 参数说明：
       *   dataSource: IDataSource 实现类，提供 totalCount() 和 getData()
       *   回调函数: (item: GoodsInfo) => { ... } 构建每个条目的 UI
       */
      LazyForEach(this.dataSource, (item: GoodsInfo) => {
        // FlowItem：瀑布流中的单个条目
        FlowItem() {
          // Column 容器：纵向排列图片 + 名称
          Column() {
            // 商品图片
            // $r(item.pic)：item.pic 是字符串（如 'app.media.skirt01'）
            // 因为来自静态数据，编译器可推断值，所以 $r() 可以正常工作
            Image($r(item.pic))               // 加载图片资源
              .width('100%')                   // 宽度撑满列宽
              .objectFit(ImageFit.Contain)     // Contain：保持比例完整显示，不裁剪

            // 商品名称（如"促销价""惊爆价"等趣味名称）
            Text(item.name)
              .fontSize(18)   // 字号 18
          }
        }
        .width('100%')                         // FlowItem 宽度撑满列宽
        .padding(0)                            // 无边距（图片紧贴边缘）
        .backgroundColor(Color.White)          // 白色背景
      }, (item: GoodsInfo) => item.name)       // key 生成函数：用商品名称作为唯一标识
                                               // 用于 Diff 算法对比，确保列表复用优化正确
    }
    .columnsTemplate('1fr 1fr 1fr')  // 等宽三列瀑布流（1:1:1）
    .columnsGap(2)                   // 列间距 2
    .rowsGap(2)                      // 行间距 2
    .padding(2)                      // 外边距 2
    .backgroundColor(Color.Yellow)   // 黄色背景（便于与电器分类的粉色区分）
    .scrollBar(BarState.Auto)        // 滚动时自动显示滚动条
  }
}
