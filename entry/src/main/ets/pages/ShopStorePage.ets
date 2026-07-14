/**
 * =============================================================================
 *  ShopStorePage - 手机商城页面（@Entry 独立路由页面）
 * =============================================================================
 * 【作用】
 *   手机商品展示商城页面，用户可浏览 6 款品牌手机并添加到购物车。
 *   与 DepartmentCartView 购物车页面通过路由相互跳转。
 *   同时使用 RDB + Preferences 双存储添加商品。
 *
 * 【页面跳转关系】
 *   Index.ets (主页) → shopStorePage.ets (商城)
 *                   ← router.back() 返回
 *   Index.ets 的购物车 Tab → onPageShow() 触发刷新
 *
 * 【功能】
 *   1. 展示 6 款品牌手机（图片/名称/价格/描述）
 *   2. 添加商品到购物车（双存储：Preferences + RDB）
 *   3. 购物车入口右上角徽标显示当前商品数量
 *   4. 添加成功 Toast 提示（2 秒自动隐藏）
 * =============================================================================
 */

import { router } from '@kit.ArkUI';
// router: 页面路由模块，用于返回主页（router.back()）

import { GoodsInfo } from '../entity/GoodsInfo';
import { CartItem } from '../entity/CartItem';
import { CartPreferencesUtil } from '../entity/CartPreferencesUtil';
import { CartRdbUtil } from '../entity/CartRdbUtil';
import { ImageCacheManager } from '../entity/ImageCacheManager';

import { BusinessError } from '@kit.BasicServicesKit';

/** 日志标签，用于 console 输出时标识日志来源 */
const TAG: string = 'ShopStorePage';

/**
 * 手机商城页面
 * @Entry 标记为可路由页面（已在 main_pages.json 中注册 'pages/ShopStorePage'）
 */
@Entry
@Component
struct ShopStorePage {
  // ════════════════════════════════════════════
  //  @State 状态变量
  // ════════════════════════════════════════════

  /** 手机商品列表（通过 GoodsInfo.getDefaultPhone() 加载 6 款手机） */
  @State private phoneGoods: GoodsInfo[] = [];

  /** 购物车商品总量（用于右上角徽标显示） */
  @State private cartCount: number = 0;

  /** 是否正在加载中（加载时显示 LoadingProgress） */
  @State private isLoading: boolean = true;

  /** Toast 提示消息文本 */
  @State private toastMessage: string = '';

  /** 是否显示 Toast（true 显示，2 秒后 false 隐藏） */
  @State private showToast: boolean = false;

  // ──── 单例实例 ────

  /** Preferences 存储工具单例 */
  private preferencesUtil: CartPreferencesUtil = CartPreferencesUtil.getInstance();

  /** RDB 存储工具单例 */
  private rdbUtil: CartRdbUtil = CartRdbUtil.getInstance();

  /** 图片缓存管理器单例（虽未直接使用，但保持与 DepartmentCartView 一致的架构） */
  private imageCache: ImageCacheManager = ImageCacheManager.getInstance();

  // ════════════════════════════════════════════
  //  生命周期
  // ════════════════════════════════════════════

  /**
   * aboutToAppear：页面首次创建时触发
   * 执行初始化：双存储 → 加载手机数据 → 获取购物车数量
   */
  async aboutToAppear(): Promise<void> {
    try {
      // 初始化 Preferences 存储
      await this.preferencesUtil.init(getContext(this));
      // 初始化 RDB 存储
      await this.rdbUtil.init(getContext(this));
      // 设置图片缓存上下文
      this.imageCache.setContext(getContext(this));

      // 加载 6 款手机商品数据
      this.phoneGoods = GoodsInfo.getDefaultPhone();

      // 获取当前购物车总数量（用于顶部徽标）
      this.cartCount = await this.preferencesUtil.getTotalQuantity();

      console.info(TAG + ': 商城页面初始化完成，共 ' + this.phoneGoods.length + ' 款手机');
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': 初始化失败, code=' + error.code + ', msg=' + error.message);
    } finally {
      this.isLoading = false;  // 结束加载状态
    }
  }

  /**
   * onPageShow：页面显示时触发（@Entry 专有生命周期）
   * 从购物车页面返回时重新刷新购物车数量
   * 触发场景：
   *   1. 首次进入页面时（在 aboutToAppear 之后触发）
   *   2. 从其他页面 router.back() 返回时
   */
  async onPageShow(): Promise<void> {
    try {
      // 重新获取购物车数量（从购物车返回时数量可能已变化）
      this.cartCount = await this.preferencesUtil.getTotalQuantity();
    } catch (err) {
      console.error(TAG + ': 刷新购物车数量失败');
    }
  }

  // ════════════════════════════════════════════
  //  操作方法
  // ════════════════════════════════════════════

  /**
   * 添加商品到购物车
   * 同时写入两种存储方式：
   *   1. Preferences（首选项）：轻量键值对存储
   *   2. RDB（关系型数据库）：结构化 SQL 存储
   *
   * @param goods - 要添加的手机商品
   */
  private async addToCart(goods: GoodsInfo): Promise<void> {
    try {
      // 创建 CartItem 实例
      // id 使用 "store_" + 商品名称 + 时间戳，确保每次添加生成唯一的 ID
      // 这样同一商品添加多次会产生不同 ID 的条目（各自独立）
      const cartItem = new CartItem(
        'store_' + goods.name + '_' + Date.now(),  // 唯一 ID：store_iPhone11_1712345678000
        goods.name,                                  // 商品名称：'iPhone11'
        goods.price,                                 // 商品价格：4999.00
        1,                                           // 初始数量：1
        goods.pic,                                   // 图片路径：'app.media.iphone'
        goods.desc                                   // 商品描述：完整型号参数
      );

      // 方式一：存入 Preferences
      await this.preferencesUtil.addItem(cartItem);
      // 方式二：存入 RDB
      await this.rdbUtil.addItem(cartItem);

      // 更新购物车总数量（用于顶部徽标和底部文本）
      this.cartCount = await this.preferencesUtil.getTotalQuantity();

      // 显示添加成功的 Toast 提示
      this.showAddSuccess(goods.name + ' 已加入购物车');

      console.info(TAG + ': 商品 ' + goods.name + ' 已通过 RDB + Preferences 双存储添加');
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': 添加商品失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 返回主页（调用 router.back() 回到 Index）
   * Index 的 onPageShow() 捕获到此返回事件，递增 cartRefreshCounter 触发购物车刷新
   */
  private navigateToCart(): void {
    router.back();  // 返回上一页（Index.ets）
  }

  /**
   * 显示添加成功的 Toast 提示
   * 设置 showToast = true 显示，2 秒后 setTimeout 设为 false 隐藏
   *
   * @param message - 提示消息，如 "iPhone11 已加入购物车"
   */
  private showAddSuccess(message: string): void {
    this.toastMessage = message;
    this.showToast = true;

    // 2 秒后自动隐藏 Toast
    setTimeout(() => {
      this.showToast = false;
    }, 2000);
  }

  // ════════════════════════════════════════════
  //  UI 构建
  // ════════════════════════════════════════════

  build() {
    Column() {
      // ════════════════════════════════════════════
      //  顶部导航栏：返回按钮 | 标题 | 购物车入口（带徽标）
      // ════════════════════════════════════════════
      Row() {
        Button('< 返回')                          // 返回上一页按钮
          .fontSize(15).fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => { router.back(); })

        Text('📱 手机商城')                        // 页面标题
          .fontSize(20).fontWeight(FontWeight.Bold)
          .layoutWeight(1)                         // 占据中间剩余空间
          .textAlign(TextAlign.Center)             // 文字居中

        Stack() {                                  // Stack 叠加：购物车图标 + 数量徽标
          Button('🛒')                             // 购物车入口图标
            .fontSize(20).backgroundColor(Color.Transparent)
            .width(44).height(44)
            .onClick(() => this.navigateToCart())   // 点击返回主页

          if (this.cartCount > 0) {
            Text('' + this.cartCount)              // 数量徽标（红色小圆点）
              .fontSize(10).fontColor(Color.White)
              .backgroundColor('#FF4444')           // 红色背景
              .borderRadius(10)                     // 圆形
              .width(18).height(18)
              .textAlign(TextAlign.Center)
              .position({ x: 28, y: 0 })            // 定位到购物车图标右上角
          }
        }
        .width(44).height(44)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 12, bottom: 12 })
      .backgroundColor(Color.White)

      // 分割线
      Divider().strokeWidth(0.5).color('#E8E8E8')

      // ════════════════════════════════════════════
      //  内容区域：加载中 / 商品列表
      // ════════════════════════════════════════════
      if (this.isLoading) {
        // 加载中 → 转圈动画
        Column() {
          LoadingProgress().width(40).height(40).color('#007DFF')
          Text('加载商品数据...').fontSize(14).fontColor('#999999').margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else {
        // 商品列表 → Scroll 滚动容器
        Scroll() {
          Column({ space: 12 }) {                  // space=12：商品卡片间距 12
            // 页面标题区域
            Column() {
              Text('精选手机')
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333333')

              Text('6 款热门品牌手机，总有一款适合你')
                .fontSize(13).fontColor('#999999').margin({ top: 4 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 20, bottom: 16 })

            // 遍历 6 款手机，使用 @Builder GoodsCard 渲染每个商品卡片
            ForEach(this.phoneGoods, (goods: GoodsInfo, index: number) => {
              this.GoodsCard(goods, index)
            }, (goods: GoodsInfo) => goods.name)   // key 生成：用商品名称作为唯一标识
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 30 })
        }
        .layoutWeight(1)                           // 占据顶部导航栏下方的所有空间
        .backgroundColor('#F5F5F5')
      }

      // ════════════════════════════════════════════
      //  Toast 提示（条件渲染，仅 showToast=true 时显示）
      //  悬浮在页面底部上方 15% 位置
      // ════════════════════════════════════════════
      if (this.showToast) {
        Text(this.toastMessage)
          .fontSize(14).fontColor(Color.White)
          .backgroundColor('rgba(0, 0, 0, 0.75)')   // 75% 透明度的黑色背景
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .borderRadius(20)                          // 圆角胶囊形状
          .position({ x: '10%', y: '85%' })          // 定位到页面底部
          .width('80%')                              // 宽度为屏幕的 80%
          .textAlign(TextAlign.Center)
      }

      // ════════════════════════════════════════════
      //  底部操作栏：商品数量 + 查看购物车按钮
      // ════════════════════════════════════════════
      Row() {
        Text('已有 ' + this.cartCount + ' 件商品在购物车中')
          .fontSize(13).fontColor('#999999')

        Blank()  // 弹性空间

        Button('查看购物车 🛒')                      // 返回购物车的操作按钮
          .fontSize(14).fontColor(Color.White)
          .backgroundColor('#FF4444').borderRadius(18)
          .width(130).height(36)
          .onClick(() => this.navigateToCart())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ════════════════════════════════════════════
  //  @Builder 商品卡片组件
  // ════════════════════════════════════════════

  /**
   * 单个手机商品卡片
   *
   * 卡片布局：
   *   ┌──────────────────────────────────┐
   *   │  ┌──────┐  商品名称              │
   *   │  │ 图片  │  商品描述（最多2行）    │
   *   │  │ 区域  │  ¥价格  [加入购物车]   │
   *   │  └──────┘                        │
   *   └──────────────────────────────────┘
   *
   * @param goods - 商品信息（pic/name/desc/price）
   * @param index - 在商品列表中的索引
   */
  @Builder
  GoodsCard(goods: GoodsInfo, index: number) {
    Row() {
      // ── 左侧：手机图片区域（100x100 圆角，灰底占位） ──
      Stack() {
        // 通过 getImageResource() 映射函数加载图片
        // 不能用 $r(goods.pic)，因为 goods.pic 是运行时字符串
        Image(this.getImageResource(goods.pic))
          .width(90).height(90)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
      }
      .width(100).height(100)
      .borderRadius(10)
      .backgroundColor('#F0F0F0')        // 浅灰底色

      // ── 右侧：商品信息区 ──
      Column() {
        Text(goods.name)                                   // 商品名称（如 'iPhone11'）
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (goods.desc && goods.desc.length > 0) {
          Text(goods.desc)                                 // 商品描述（最多2行）
            .fontSize(12).fontColor('#999999')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .lineHeight(18)
        }

        Row() {
          Text('¥' + goods.price.toFixed(2))               // 价格（红色加粗）
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FF4444')

          Blank()                                          // 弹性空间

          Button('加入购物车')                               // 加入购物车按钮
            .fontSize(12).fontColor(Color.White)
            .backgroundColor('#007DFF').borderRadius(15)
            .height(30).padding({ left: 12, right: 12 })
            .onClick(() => this.addToCart(goods))
        }
        .width('100%')
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)                                     // 占据右侧剩余空间
      .alignItems(HorizontalAlign.Start)                   // 左对齐
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)                                      // 卡片圆角
    .shadow({                                              // 卡片阴影（浅色）
      radius: 4,
      color: 'rgba(0, 0, 0, 0.06)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 根据资源名称字符串获取对应的 Resource 对象
   *
   * 原理同 DepartmentCartView.getImageResource()：
   * $r() 是编译期函数，不能接受运行时字符串，需要用 switch 映射表。
   *
   * @param resName - 资源名称字符串（如 'app.media.iphone'）
   * @returns {Resource} 编译期确定的 Resource 对象
   */
  private getImageResource(resName: string): Resource {
    const key: string = resName.startsWith('app.media.') ? resName.substring(10) : resName;
    switch (key) {
      case 'iphone':  return $r('app.media.iphone');
      case 'huawei':  return $r('app.media.huawei');
      case 'xiaomi':  return $r('app.media.xiaomi');
      case 'oppo':    return $r('app.media.oppo');
      case 'vivo':    return $r('app.media.vivo');
      case 'rongyao': return $r('app.media.rongyao');
      default:        return $r('app.media.iphone');  // 默认占位
    }
  }
}
