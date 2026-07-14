/**
 * =============================================================================
 *  DepartmentStorePage - 商城主页面（@Component 组件版封装）
 * =============================================================================
 * 【作用】
 *   将完整的商城页面（含底部玻璃流光导航栏）封装为一个可复用的 @Component。
 *   与 Index.ets 功能结构相同（Tabs + LightFlowTabBar），但不带 @Entry 标记，
 *   不包含生命周期演示按钮和手机商城入口按钮，适合嵌入其他页面中复用。
 *
 * 【与 Index.ets 的区别】
 *   Index.ets              = @Entry 页面入口 + 浮动按钮（生命周期演示/手机商城）
 *   DepartmentStorePage.ets = @Component 可复用组件（纯布局，无浮动按钮）
 *
 * 【布局结构】
 *   Stack（叠加布局）
 *   ├── Tabs（底层：铺满全屏，barHeight=0 隐藏原生页签栏）
 *   │   ├── TabContent：DepartmentHomeView（首页）
 *   │   ├── TabContent：DepartmentClassView（分类）
 *   │   └── TabContent：DepartmentCartView（购物车，不带 refreshTrigger）
 *   └── Column（顶层：悬浮覆盖底部）
 *       ├── Row（占位，layoutWeight=1 撑满，hitTestMode=None 不拦截触摸）
 *       └── LightFlowTabBar（玻璃流光导航栏）
 * =============================================================================
 */

import { DepartmentHomeView } from './DepartmentHomeView';
// 首页视图：轮播图 + 多级 Grid 网格商品

import { DepartmentClassView } from './DepartmentClassView';
// 分类视图：内嵌服装/电器二级 Tabs 瀑布流

import { DepartmentCartView } from './DepartmentCartView';
// 购物车视图：RDB + Preferences 双存储购物车

import { LightFlowTabBar } from '../pages/LightFlowTabBar';
// 玻璃流光导航栏：毛玻璃 + 磁吸高亮 + 流光动画

import { NavigationItem } from '../pages/NavigationItem';
// 导航项数据模型：id/text/icon/activeIcon

/**
 * 商城主页面（组件版封装）
 * Stack 叠加布局：内容铺满全屏，玻璃导航栏悬浮覆盖底部
 * 注意：此组件的 DepartmentCartView 未传入 refreshTrigger 参数，
 * 因此购物车 Tab 的刷新需依赖 aboutToAppear 初始加载。
 */
@Component
export struct DepartmentStorePage {
  /**
   * 当前选中的底部页签序号
   * 0 = 首页，1 = 分类，2 = 购物车
   * @State 装饰：值变化时自动刷新 UI
   * $$this.current 双向绑定：与 Tabs.index 和 LightFlowTabBar 联动
   */
  @State current: number = 0;

  /**
   * 玻璃流光导航栏的 Tab 配置项数组
   * 三个 Tab：首页(tab_first)、分类(tab_second)、购物车(tab_third)
   * 每个 Tab 分别指定未选中图标（_normal）和选中图标（_pressed）
   */
  private navItems: NavigationItem[] = [
    new NavigationItem('home', '首页',
      $r('app.media.tab_first_normal'),    // 首页灰显图标
      $r('app.media.tab_first_pressed')    // 首页高亮图标
    ),
    new NavigationItem('category', '分类',
      $r('app.media.tab_second_normal'),   // 分类灰显图标
      $r('app.media.tab_second_pressed')   // 分类高亮图标
    ),
    new NavigationItem('cart', '购物车',
      $r('app.media.tab_third_normal'),    // 购物车灰显图标
      $r('app.media.tab_third_pressed')    // 购物车高亮图标
    ),
  ];

  /**
   * 构建 UI
   * Stack 叠加布局：底层 Tabs（内容）+ 顶层 Column（导航栏）
   */
  build() {
    Stack() {
      // ── 底层：Tabs 铺满全屏内容区域 ──
      Tabs({ barPosition: BarPosition.End, index: $$this.current }) {
        TabContent() {
          Column() {
            DepartmentHomeView()    // 首页视图（轮播图 + 网格）
          }.width('100%').height('100%')
        }

        TabContent() {
          Column() {
            DepartmentClassView()   // 分类视图（服装/电器瀑布流）
          }.width('100%').height('100%')
        }

        TabContent() {
          Column() {
            // 注意：此处未传入 refreshTrigger，约车页的刷新依赖 aboutToAppear 初始加载
            DepartmentCartView()
          }.width('100%').height('100%')
        }
      }
      .vertical(false)               // 水平方向切换页签
      .width('100%').height('100%')  // 撑满父容器
      .barWidth('100%').barHeight(0) // 隐藏原生页签栏（由 LightFlowTabBar 接管）

      // ── 顶层：导航栏悬浮覆盖 ──
      Column() {
        // 透明占位 Row，layoutWeight=1 占据导航栏上方所有空间
        // hitTestBehavior(None)：不响应触摸事件，穿透到底层 Tabs
        Row() {}.layoutWeight(1).hitTestBehavior(HitTestMode.None)

        // 玻璃流光导航栏
        LightFlowTabBar({
          tabs: this.navItems,
          currentIndex: this.current,
          onTabClick: (index: number): void => {
            this.current = index;  // 更新当前选中页签索引
          }
        })
      }
      .width('100%').height('100%')
      .alignItems(HorizontalAlign.Center)       // 水平居中
      .hitTestBehavior(HitTestMode.Transparent)  // Column 穿透，子节点正常响应
    }
    .width('100%').height('100%')
  }
}
