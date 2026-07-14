/**
 * =============================================================================
 *  DepartmentHomeView - 商城首页视图组件
 * =============================================================================
 * 【作用】
 *   商城首页的内容视图，整体包裹在 Scroll 中支持垂直滚动。
 *   从上到下依次展示 5 个区域：标题 → 轮播图 → 5列网格 → 4列合并网格 → 3列手机网格。
 *
 * 【布局层次】
 *   Scroll（垂直滚动）
 *     └── Column（纵向排列各区域）
 *           ├── Text（"商城首页"标题）
 *           ├── Swiper（轮播图：5 张横幅广告，自动循环）
 *           ├── Grid（5 列常规网格：10 个商品）
 *           ├── Grid（4 列合并网格：6 个商品，前 2 项跨两列）
 *           └── Grid（3 列手机网格：6 款手机）
 *
 * 【数据来源】
 *   所有数据均通过 GoodsInfo 的静态工厂方法获取：
 *     GoodsInfo.getDefaultGrid()    - 10 个网格商品
 *     GoodsInfo.getDefaultCombine() - 6 个合并网格商品
 *     GoodsInfo.getDefaultPhone()   - 6 款手机商品
 *     SwipeDataSource               - 5 张轮播图（实现 IDataSource 接口）
 * =============================================================================
 */

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，提供各区域预设数据的静态工厂方法

import { SwipeDataSource } from '../entity/SwipeDataSource';
// SwipeDataSource: 轮播图数据源，实现 IDataSource 接口，配合 LazyForEach 使用

/**
 * 商城首页视图组件（@Component，非 @Entry，由 Index.ets 的 TabContent 包含）
 * 展示轮播图 + 多级商品网格布局
 */
@Component
export struct DepartmentHomeView {
  /** 轮播图数据源实例（提供 5 张横幅广告图的 Resource 引用） */
  private dataSource: SwipeDataSource = new SwipeDataSource();

  /**
   * 常规 5 列网格的商品列表
   * @State 装饰：当 gridArray 值变化时自动刷新 Grid UI
   * 通过 GoodsInfo.getDefaultGrid() 获取 10 个商品（商场/超市/百货…）
   */
  @State gridArray: GoodsInfo[] = GoodsInfo.getDefaultGrid();

  /**
   * 合并网格的商品列表（支持不规则跨列布局）
   * 通过 GoodsInfo.getDefaultCombine() 获取 6 个商品（猜你喜欢/大牌驾到…）
   */
  @State combineArray: GoodsInfo[] = GoodsInfo.getDefaultCombine();

  /**
   * 手机区域 3 列网格的商品列表
   * 通过 GoodsInfo.getDefaultPhone() 获取 6 款手机（iPhone11/Mate30…）
   * 含详细描述 desc 和真实价格 price
   */
  @State phoneArray: GoodsInfo[] = GoodsInfo.getDefaultPhone();

  /**
   * 合并网格的不规则布局配置（GridLayoutOptions）
   *
   * GridLayoutOptions 配置详解：
   *   regularSize: [1, 1]           - 常规网格尺寸为 1 行 × 1 列
   *   irregularIndexes: [0, 1]      - 标记索引 0 和 1 为不规则网格
   *   onGetIrregularSizeByIndex:     - 根据索引返回不规则尺寸
   *     索引 0、1 → [1, 2]（占一行两列，宽度翻倍）
   *     其他索引  → [1, 1]（标准一列宽度）
   *
   * 效果：前两个商品各占两列宽度，视觉效果突出
   */
  private layoutOptions: GridLayoutOptions = {
    regularSize: [1, 1],      // 常规项：1行 × 1列
    irregularIndexes: [0, 1], // 标记索引 0（猜你喜欢）和 1（大牌驾到）为不规则
    onGetIrregularSizeByIndex: (index: number) => {
      if (index == 0 || index == 1) {
        return [1, 2];  // 索引 0、1 占 1行 × 2列（双倍宽度）
      }
      return [1, 1];    // 其他索引占 1行 × 1列（标准宽度）
    }
  };

  /**
   * 构建首页 UI
   * 整体垂直滚动（Scroll），从上到下展示各区域内容
   */
  build() {
    // Scroll 容器：支持垂直滚动，子元素超出屏幕高度时可滚动查看
    Scroll() {
      // Column 容器：所有子元素纵向排列，从上到下展示各区域
      Column() {
        // ══════════════════════════════════════════
        //  区域一：页面标题 "商城首页"
        // ══════════════════════════════════════════
        Text('商城首页')
          .fontSize(20)     // 字号 20，适中大小的标题
          .padding(10)      // 内边距 10，与周围拉开间距

        // ══════════════════════════════════════════
        //  区域二：Swiper 轮播图
        //  水平滑动，自动循环播放，切换间隔 4 秒
        // ══════════════════════════════════════════
        Swiper() {
          // LazyForEach：懒加载轮播图数据源（只渲染当前显示的轮播项）
          // this.dataSource 是 SwipeDataSource 实例（实现 IDataSource）
          // 第二个参数 (item) => Image(item) 是组件构建函数
          LazyForEach(this.dataSource, (item: Resource) => {
            Image(item)                           // 使用 Resource 引用加载图片
              .width('100%')                      // 宽度撑满 Swiper 容器
              .height(150)                        // 高度固定 150
              .objectFit(ImageFit.Cover)          // Cover：裁剪适配，填满容器可能裁切边缘
          })
        }
        .vertical(false)         // false = 水平方向滑动（左右滑动切换）
        .indicator(true)         // true = 显示底部圆点指示器（当前第几张）
        .autoPlay(true)          // true = 自动轮播（无需用户操作）
        .loop(true)              // true = 循环播放（播完最后一张回到第一张）
        .interval(4000)          // 自动切换间隔 4000ms（4 秒）
        .duration(1000)          // 切换动画时长 1000ms（1 秒）

        // ══════════════════════════════════════════
        //  区域三：5 列常规 Grid 网格
        //  展示 10 个普通商品，等宽五列
        // ══════════════════════════════════════════
        Grid() {
          // ForEach：遍历 gridArray 中的每个商品
          // 每个商品渲染为一个 GridItem
          ForEach(this.gridArray, (item: GoodsInfo) => {
            GridItem() {
              // 纵向排列：图片在上，名称在下
              Column() {
                // $r(item.pic)：
                // item.pic 是字符串（如 'app.media.pic_01'）
                // 不能在运行时通过变量使用 $r()，但此处因为 item.pic 来自
                // 静态数据，ArkTS 编译器能推断其值，所以可以正常工作
                Image($r(item.pic))   // 商品图片
                  .width('100%')       // 宽度撑满 GridItem
                Text(item.name)        // 商品名称
                  .fontSize(18)
              }
            }
            .padding(5)                    // GridItem 内边距 5
            .backgroundColor(Color.White)  // 白色背景（商品卡片效果）
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')  // 5列等宽（每个 1fr 占 1/5）
        .columnsGap(0.5)      // 列间距 0.5（配合灰色背景形成分割线）
        .rowsGap(0.5)         // 行间距 0.5
        .backgroundColor(Color.Gray)  // 灰色背景（网格间隙显示灰色，形成分割线）

        // ══════════════════════════════════════════
        //  区域四：不规则合并网格（前两项合并两列）
        //  4 列等宽，前 2 个商品各占两列宽度
        // ══════════════════════════════════════════
        // 第二个参数传入 this.layoutOptions 实现不规则跨列布局
        Grid(undefined, this.layoutOptions) {
          ForEach(this.combineArray, (item: GoodsInfo) => {
            GridItem() {
              Column() {
                Image($r(item.pic))   // 商品图片
                  .width('100%')
                Text(item.name)        // 商品名称
                  .fontSize(18)
              }
            }
            .padding(5)
            .backgroundColor(Color.White)
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')  // 4列等宽（每个 1fr 占 1/4）
        .columnsGap(0.5)
        .rowsGap(0.5)
        .backgroundColor(Color.Gray)

        // ══════════════════════════════════════════
        //  区域五：3 列手机商品 Grid 网格
        //  展示 6 款品牌手机，等宽三列
        // ══════════════════════════════════════════
        Grid() {
          ForEach(this.phoneArray, (item: GoodsInfo) => {
            GridItem() {
              Column() {
                Image($r(item.pic))   // 手机图片（如 iphone/huawei/xiaomi）
                  .width('100%')
                Text(item.name)        // 手机型号名称（如 'iPhone11'）
                  .fontSize(18)
              }
            }
            .padding(5)
            .backgroundColor(Color.White)
          })
        }
        .columnsTemplate('1fr 1fr 1fr')  // 3列等宽（1:1:1）
        .columnsGap(0.5)
        .rowsGap(0.5)
        .backgroundColor(Color.Gray)
      }
    }
    .scrollable(ScrollDirection.Vertical)  // 仅允许垂直方向滚动
    .scrollBar(BarState.Auto)              // 滚动条状态：滚动时自动显示
  }
}
