/**
 * =============================================================================
 *  AppliancesDataSource - 电器分类瀑布流数据源
 * =============================================================================
 * 【作用】
 *   为"电器"分类下的 WaterFlow 瀑布流提供商品数据，实现 IDataSource 接口。
 *   数据通过 GoodsInfo.getDefaultAppi() 静态工厂方法获取 15 条电器记录。
 *
 * 【与 ClothesDataSource 的区别】
 *   ┌────────────────┬────────────────────┬──────────────────────┐
 *   │                │  ClothesDataSource │  AppliancesDataSource │
 *   ├────────────────┼────────────────────┼──────────────────────┤
 *   │ 数据量         │  23 件服装          │  15 件电器            │
 *   │ 工厂方法       │  getDefaultClot()   │  getDefaultAppi()     │
 *   │ 图片命名       │  skirt01~skirt23   │  dian01~dian15       │
 *   │ 使用的 View    │  ClassClothesView   │  ClassAppliancesView  │
 *   └────────────────┴────────────────────┴──────────────────────┘
 * =============================================================================
 */

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，提供各区域预设数据的静态工厂方法

/**
 * 电器瀑布流数据源类
 * 为 WaterFlow 组件提供 15 件电器商品的懒加载数据
 */
export class AppliancesDataSource implements IDataSource {
  /**
   * 电器商品数据数组
   * 在声明时直接通过 GoodsInfo.getDefaultAppi() 初始化
   * getDefaultAppi() 内部遍历 appiImageArray（dian01~dian15 图片路径）
   * 和 appiNameArray（15 个趣味名称），组装成 GoodsInfo[] 返回
   */
  private dataArray: GoodsInfo[] = GoodsInfo.getDefaultAppi();

  /**
   * 构造函数
   * dataArray 已在声明时完成初始化，无需额外逻辑
   */
  constructor() {
    // 空实现：数据已在声明时初始化
  }

  /**
   * 获取数据源中的电器商品总条目数
   *
   * @returns {number} 电器商品数量，固定为 15
   */
  totalCount(): number {
    return this.dataArray.length;  // 返回 15
  }

  /**
   * 根据索引获取对应的电器商品数据
   * WaterFlow 在滚动时按需调用此方法读取数据项
   *
   * @param index - 要获取的商品索引，从 0 开始
   * @returns {GoodsInfo} 指定索引的电器商品信息（含 pic/name/desc/price）
   */
  getData(index: number): GoodsInfo {
    return this.dataArray[index];  // 返回指定索引的 GoodsInfo 对象
  }

  /**
   * 注册数据变化监听器
   * 当前数据为静态数据，运行期间不会变化，方法体留空
   *
   * @param listener - DataChangeListener 实例，由 LazyForEach 自动传入
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    // 静态数据，无需监听
  }

  /**
   * 注销数据变化监听器
   * 组件销毁时由 LazyForEach 自动调用
   */
  unregisterDataChangeListener() {
    // 静态数据，无需注销
  }
}
