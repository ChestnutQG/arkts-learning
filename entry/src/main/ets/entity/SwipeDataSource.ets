/**
 * =============================================================================
 *  SwipeDataSource - 轮播图（Swiper）数据源
 * =============================================================================
 * 【作用】
 *   为首页 Swiper 轮播组件提供图片数据，实现 IDataSource 接口，
 *   配合 LazyForEach 实现懒加载渲染（仅渲染可见的轮播项）。
 *
 * 【IDataSource 接口要求实现的 4 个方法】
 *   1. totalCount()                    - 返回数据总数
 *   2. getData(index)                  - 根据索引获取数据项
 *   3. registerDataChangeListener()    - 注册数据变化监听器
 *   4. unregisterDataChangeListener()  - 注销数据变化监听器
 *
 * 【为什么用 IDataSource + LazyForEach 而不是直接 ForEach？】
 *   1. LazyForEach 只渲染屏幕上可见的部分（懒加载），适合少量几项的数据
 *   2. 数据变化时只更新差异部分（Diff 算法），而非整体刷新
 *   3. 本例中数据为 5 张静态图片，主要目的是演示 IDataSource 接口的实现方式
 *
 * 【使用场景】
 *   DepartmentHomeView.ets 中的 Swiper 组件通过 LazyForEach 消费此数据源
 * =============================================================================
 */

/**
 * 轮播图数据源类
 * 提供 5 张横幅广告图（banner_1 ~ banner_5）的 Resource 引用列表
 * implements IDataSource：标记此类实现了 IDataSource 接口
 */
export class SwipeDataSource implements IDataSource {
  /**
   * 轮播图图片资源数组，存储 5 张横幅广告图的 Resource 编译期引用
   * 图片文件位于 resources/base/media/ 目录下，命名规则 banner_1 ~ banner_5
   * $r('app.media.banner_1')：编译期引用，运行时直接读取打包资源的 Resource 对象
   */
  private dataArray: Array<Resource> = [
    $r("app.media.banner_1"),  // 第一张横幅广告图：banner_1.png
    $r("app.media.banner_2"),  // 第二张横幅广告图：banner_2.png
    $r("app.media.banner_3"),  // 第三张横幅广告图：banner_3.png
    $r("app.media.banner_4"),  // 第四张横幅广告图：banner_4.png
    $r("app.media.banner_5"),  // 第五张横幅广告图：banner_5.png
  ];

  /**
   * 构造函数
   * dataArray 已在声明时完成初始化，此处无需额外逻辑
   */
  constructor() {
    // 空实现：数据已在声明时赋值，无需再次初始化
  }

  /**
   * 获取数据源中的数据总条目数
   * LazyForEach 在初始化时会调用此方法确定渲染范围
   *
   * @returns {number} dataArray 数组的长度，固定为 5
   */
  totalCount(): number {
    return this.dataArray.length;  // 返回 5，代表 5 张轮播图
  }

  /**
   * 根据索引获取对应的图片资源
   * LazyForEach 在渲染每个轮播项时按需调用此方法
   *
   * @param index - 要获取的数据索引，从 0 开始
   * @returns {Resource} 指定索引位置的 Resource 对象（编译期确定的图片资源引用）
   */
  getData(index: number): Resource {
    return this.dataArray[index];  // 返回指定索引的 Resource 引用，如 $r('app.media.banner_1')
  }

  /**
   * 注册数据变化监听器
   * 当数据源发生增删改时，需调用 listener.onDataReloaded() 通知 LazyForEach 刷新 UI。
   * 当前数据为静态数据（运行期间不会变化），方法体留空。
   *
   * @param listener - DataChangeListener 实例，由 LazyForEach 自动传入
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    // 静态数据无需监听变化，留空
  }

  /**
   * 注销数据变化监听器
   * 组件销毁时由 LazyForEach 自动调用，清理监听器引用避免内存泄漏。
   * 当前数据为静态数据，无需注销逻辑。
   */
  unregisterDataChangeListener() {
    // 静态数据无需注销监听，留空
  }
}
