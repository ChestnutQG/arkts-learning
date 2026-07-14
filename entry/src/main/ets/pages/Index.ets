/**
 * =============================================================================
 *  Index.ets - 应用主入口页面（@Entry 路由入口）
 * =============================================================================
 * 【作用】
 *   应用启动后加载的第一个页面（EntryAbility 中通过 loadContent('pages/Index') 加载）。
 *   使用底部 Tabs 实现「首页/分类/购物车」三个主要导航模块，
 *   底部导航栏采用悬浮玻璃流光效果（LightFlowTabBar），替代原生 Tabs 页签栏。
 *
 * 【布局架构】
 *   Stack（叠加布局）
 *   ├── Tabs（底层：铺满全屏，实现三个页面的滑动切换）
 *   │   ├── TabContent：DepartmentHomeView（首页内容）
 *   │   ├── TabContent：DepartmentClassView（分类页）
 *   │   └── TabContent：DepartmentCartView（购物车页，接收 refreshTrigger）
 *   └── Column（顶层：覆盖整个屏幕，底部悬浮导航栏）
 *       ├── Row（占位空间，layoutWeight=1，hitTest=None 不拦截事件）
 *       └── LightFlowTabBar（玻璃流光导航栏）
 *
 * 【刷新机制】
 *   1. Tabs.onChange：切换到购物车 Tab(index=2) 时递增 cartRefreshCounter
 *   2. onPageShow()：从 ShopStorePage 返回时递增 cartRefreshCounter
 *   3. cartRefreshCounter 通过 @Prop 传给 DepartmentCartView
 *   4. DepartmentCartView 的 @Watch('onRefreshTriggerChanged') 捕获变化后刷新数据
 *
 * 【数据流】
 *   current ← $$ 双向绑定 → Tabs.index
 *   current ← onTabClick 回调 ← LightFlowTabBar
 *   cartRefreshCounter → @Prop → DepartmentCartView
 * =============================================================================
 */

import { router } from '@kit.ArkUI';
// router: 页面路由模块，用于 pushUrl 跳转到 LifeCycleDemo / ShopStorePage

import { DepartmentHomeView } from '../business/DepartmentHomeView';
// 首页视图：轮播图 + 多级 Grid 网格商品

import { DepartmentClassView } from '../business/DepartmentClassView';
// 分类视图：内嵌服装/电器二级 Tabs 瀑布流

import { DepartmentCartView } from '../business/DepartmentCartView';
// 购物车视图：RDB + Preferences 双存储购物车功能

import { LightFlowTabBar } from './LightFlowTabBar';
// 玻璃流光导航栏：毛玻璃效果 + 磁吸高亮 + 流光动画

import { NavigationItem } from './NavigationItem';
// 导航项数据模型：id / text / icon / activeIcon

/**
 * 应用主入口页面
 * @Entry 标记为该组件是路由页面（自动注册进 main_pages.json）
 * @Component 标记为可复用组件（虽然 @Entry 组件通常不直接复用）
 */
@Entry
@Component
struct Index {
  // ──────────────────── 状态变量 ────────────────────

  /**
   * 当前选中的底部页签序号
   * 0 = 首页，1 = 分类，2 = 购物车
   *
   * @State 装饰器核心功能：
   *   1. current 值变化时，自动重新渲染依赖它的 UI 组件
   *   2. $$this.current 双向绑定：Tabs 滑动时自动更新 current
   *   3. LightFlowTabBar 的 currentIndex 通过 @Prop 接收变化
   *
   * 联动机制：
   *   - 点击 LightFlowTabBar → onTabClick 回调 → this.current = index
   *   - this.current 变化 → $$this.current → Tabs 切换到对应 TabContent
   *   - 滑动 Tabs → $$this.current 更新 → LightFlowTabBar 高亮同步
   */
  @State current: number = 0;

  /**
   * 购物车刷新计数器
   * 递增后传给 DepartmentCartView 触发 @Watch 回调刷新数据
   * 触发递增的场景：
   *   1. Tabs.onChange 检测到切换到购物车 Tab(index=2)
   *   2. onPageShow() 检测到从 ShopStorePage 返回
   */
  @State cartRefreshCounter: number = 0;

  /**
   * onPageShow：@Entry 页面专有的生命周期钩子
   * 页面显示时触发（首次加载 + 从其他页面返回时均会触发）
   *
   * 关键作用：当用户从 ShopStorePage 添加商品后返回 Index 时，
   * 递增 cartRefreshCounter 触发 DepartmentCartView 的数据刷新。
   * 这解决了"商城添加后返回不刷新"的问题。
   *
   * 注意：DepartmentCartView 是 @Component，没有 onPageShow 生命周期，
   * 所以此刷新逻辑必须在 @Entry 级别的 Index 中实现。
   */
  onPageShow(): void {
    // 递增计数器 → DepartmentCartView.@Watch 回调 → refreshCart()
    this.cartRefreshCounter++;
  }

  // ──────────────────── 导航栏配置数据 ────────────────────

  /**
   * 玻璃流光导航栏的 Tab 配置项数组
   * 为每个页签创建 NavigationItem：
   *   - id: 唯一标识符
   *   - text: 显示文本（"首页"/"分类"/"购物车"）
   *   - icon: 未选中状态的灰显图标（_normal）
   *   - activeIcon: 选中状态的高亮图标（_pressed）
   *
   * 图标文件位于 resources/base/media/ 目录下：
   *   tab_first_normal/pressed.png    → 首页灰显/高亮
   *   tab_second_normal/pressed.png   → 分类灰显/高亮
   *   tab_third_normal/pressed.png    → 购物车灰显/高亮
   */
  private navItems: NavigationItem[] = [
    new NavigationItem('home', '首页',
      $r('app.media.tab_first_normal'),    // 未选中：灰色轮廓图标
      $r('app.media.tab_first_pressed')    // 选中：蓝色高亮图标
    ),
    new NavigationItem('category', '分类',
      $r('app.media.tab_second_normal'),   // 未选中：灰色轮廓图标
      $r('app.media.tab_second_pressed')   // 选中：蓝色高亮图标
    ),
    new NavigationItem('cart', '购物车',
      $r('app.media.tab_third_normal'),    // 未选中：灰色轮廓图标
      $r('app.media.tab_third_pressed')    // 选中：蓝色高亮图标
    ),
  ];

  // ──────────────────── UI 构建 ────────────────────

  /**
   * 构建页面 UI
   * Stack 叠加布局：底层 Tabs（内容）+ 顶层 Column（导航栏悬浮）
   */
  build() {
    Stack() {
      // ═══════════════════════════════════════════════════
      //  底层：页面内容区域（Tabs 铺满全屏）
      //  延伸到玻璃导航栏下方，这样 backdropBlur 才能模糊到商品内容
      // ═══════════════════════════════════════════════════
      Tabs({ barPosition: BarPosition.End, index: $$this.current }) {
        // === Tab 1: 首页（0） ===
        TabContent() {
          Stack() {
            DepartmentHomeView()  // 首页视图（轮播图 + 各级网格商品）

            // 首页右上角悬浮按钮：生命周期演示入口
            Button('🔄 生命周期演示')
              .position({ x: '80%', y: 60 })    // 定位：水平 80%，垂直 60（避免遮挡标题）
              .width(120).height(36)
              .fontSize(14)
              .backgroundColor('#007DFF')         // 蓝色背景
              .onClick(() => {
                router.pushUrl({ url: 'pages/LifeCycleDemo' });
              })

            // 首页右上角悬浮按钮：手机商城入口（在"生命周期演示"左侧）
            Button('📱 手机商城')
              .position({ x: '50%', y: 60 })    // 定位：水平 50%，垂直 60（避免遮挡标题）
              .width(100).height(36)
              .fontSize(14)
              .backgroundColor('#FF6B6B')          // 红色背景
              .onClick(() => {
                router.pushUrl({ url: 'pages/ShopStorePage' });
              })
          }
          .width('100%').height('100%')
        }

        // === Tab 2: 分类（1） ===
        TabContent() {
          Column() {
            DepartmentClassView()  // 分类视图（服装/电器二级 Tabs + 瀑布流）
          }.width('100%').height('100%')
        }

        // === Tab 3: 购物车（2） ===
        TabContent() {
          Column() {
            // 传入 cartRefreshCounter 作为 @Prop refreshTrigger
            // 当父组件切换 Tab 或返回页面时，通过递增此值触发购物车数据刷新
            DepartmentCartView({ refreshTrigger: this.cartRefreshCounter })
          }.width('100%').height('100%')
        }
      }
      .vertical(false)               // 水平方向切换页签（左右滑动切换）
      .width('100%').height('100%')  // 撑满父容器
      .barWidth('100%').barHeight(0) // 隐藏原生底部 Tabs 页签栏（由 LightFlowTabBar 接管）

      // Tabs 切换事件监听：切换到购物车 Tab(index=2) 时刷新购物车数据
      .onChange((index: number) => {
        if (index === 2) {
          this.cartRefreshCounter++;  // 递增计数器，触发 DepartmentCartView 刷新
        }
      })

      // ═══════════════════════════════════════════════════
      //  顶层：玻璃导航栏悬浮覆盖在底部
      //
      //  触摸事件穿透策略：
      //     1. Column.hitTestBehavior(Transparent)
      //        - Column 自身"透明"，不拦截触摸事件
      //        - 触摸事件穿透 Column 到达底层 Tabs
      //        - 子节点 LightFlowTabBar 正常响应触摸
      //     2. Row().hitTestBehavior(None)
      //        - 占位 Row 彻底不响应触摸
      //        - 底层 Tabs 中的内容可以正常滚动/点击
      // ═══════════════════════════════════════════════════
      Column() {
        // 透明占位 Row：layoutWeight=1 占据导航栏上方所有空间
        // hitTestBehavior(None)：不响应任何触摸，穿透到底层 Tabs 内容
        Row() {}.layoutWeight(1).hitTestBehavior(HitTestMode.None)

        // 玻璃流光导航栏组件
        LightFlowTabBar({
          tabs: this.navItems,           // 三个导航项：首页/分类/购物车
          currentIndex: this.current,    // 当前选中索引，与 Tabs 同步
          onTabClick: (index: number): void => {
            this.current = index;        // 点击 Tab 时更新 current 切换页面
          }
        })
      }
      .width('100%').height('100%')
      .alignItems(HorizontalAlign.Center)       // 水平居中（导航栏 92% 宽度）
      .hitTestBehavior(HitTestMode.Transparent) // Column 自身穿透，子节点正常响应
    }
    .width('100%').height('100%')
  }
}
