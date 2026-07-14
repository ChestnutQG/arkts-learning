/**
 * =============================================================================
 *  ClothesDataSource - 服装分类瀑布流数据源
 * =============================================================================
 * 【作用】
 *   为"服装"分类下的 WaterFlow 瀑布流提供商品数据，实现 IDataSource 接口。
 *   数据通过 GoodsInfo.getDefaultClot() 静态工厂方法获取 23 条服装记录。
 *   配合 LazyForEach 实现懒加载：只渲染可见区域内的 FlowItem。
 *
 * 【数据流】
 *   GoodsInfo.getDefaultClot()                    ← 静态工厂方法
 *     → ClothesDataSource.dataArray              ← 在声明时初始化
 *       → LazyForEach + WaterFlow                ← 按需读取数据
 *         → FlowItem { Image + Text }            ← 渲染每个服装商品
 *
 * 【为什么用 IDataSource？】
 *   WaterFlow 必须配合 LazyForEach 使用，LazyForEach 必须接收 IDataSource 类型。
 *   不能用普通数组 + ForEach 替代，否则 WaterFlow 无法实现懒加载。
 * =============================================================================
 */

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，提供各区域预设数据的静态工厂方法

/**
 * 服装瀑布流数据源类
 * 为 WaterFlow 组件提供 23 件服装商品的懒加载数据
 */
export class ClothesDataSource implements IDataSource {
  /**
   * 服装商品数据数组
   * 在声明时直接通过 GoodsInfo.getDefaultClot() 初始化
   * getDefaultClot() 内部遍历 stagImageArray（23 张 skirt01~skirt23 图片路径）
   * 和 stagNameArray（23 个趣味名称），组装成 GoodsInfo[] 返回
   */
  private dataArray: GoodsInfo[] = GoodsInfo.getDefaultClot();

  /**
   * 构造函数
   * dataArray 已在声明时完成初始化，无需额外逻辑
   */
  constructor() {
    // 空实现：数据已在声明时初始化
  }

  /**
   * 获取数据源中的服装商品总条目数
   *
   * @returns {number} 服装商品数量，固定为 23
   */
  totalCount(): number {
    return this.dataArray.length;  // 返回 23
  }

  /**
   * 根据索引获取对应的服装商品数据
   * WaterFlow 在滚动时按需调用此方法读取数据项
   *
   * @param index - 要获取的商品索引，从 0 开始
   * @returns {GoodsInfo} 指定索引的服装商品信息（含 pic/name/desc/price）
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
