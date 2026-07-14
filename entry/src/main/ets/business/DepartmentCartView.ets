/**
 * =============================================================================
 *  DepartmentCartView - 购物车视图组件（RDB + Preferences 双存储 + 图片缓存）
 * =============================================================================
 * 【作用】
 *   商城"购物车"页签的内容视图，集成 Preferences 和 RDB 两种持久化方案的完整购物车功能。
 *
 * 【双存储架构】
 *   ┌───────────────────┐    ┌───────────────────┐
 *   │  Preferences       │    │  RDB              │
 *   │  (首选项 - K-V)     │    │  (关系型数据库 - SQL)│
 *   └────────┬──────────┘    └────────┬───────────┘
 *            │                        │
 *            └──────────┬─────────────┘
 *                       ▼
 *            ┌───────────────────┐
 *            │  DepartmentCartView│
 *            │  (统一 UI 展示)    │
 *            └───────────────────┘
 *
 * 【功能列表】
 *   1. 商品列表展示（图片/名称/价格/描述/数量）
 *   2. 数量加减控制（+ / - 按钮，同步更新双存储）
 *   3. 删除单个商品 + 一键清空（双存储同步删除）
 *   4. RDB + Preferences 双读双写（读取时 RDB 优先，回退 Preferences）
 *   5. ImageCacheManager 图片缓存（PixelMap 内存缓存）
 *   6. 总价统计（双存储：优先 RDB，回退 Preferences）
 *   7. 空购物车提示 + 去商城入口
 *   8. 添加示例商品功能（测试用）
 *
 * 【刷新机制】
 *   1. aboutToAppear()：首次加载时调用 loadCartData()
 *   2. @Watch('onRefreshTriggerChanged')：父组件切换 Tab 时触发 refreshCart()
 *   3. onPageShow()：已移除——@Component 没有此生命周期，由 Index.onPageShow() 驱动
 * =============================================================================
 */

import { router } from '@kit.ArkUI';
// router: 页面路由模块，用于跳转到 ShopStorePage

import { CartItem } from '../entity/CartItem';
// CartItem: 购物车商品项数据模型（id/name/price/quantity/image/desc）

import { CartPreferencesUtil } from '../entity/CartPreferencesUtil';
// CartPreferencesUtil: Preferences 存储工具类（单例）

import { CartRdbUtil } from '../entity/CartRdbUtil';
// CartRdbUtil: RDB 存储工具类（单例）

import { ImageCacheManager } from '../entity/ImageCacheManager';
// ImageCacheManager: 图片缓存管理器（单例）

import { GoodsInfo } from '../entity/GoodsInfo';
// GoodsInfo: 商品数据实体，用于 addSampleItems() 添加示例商品

import { BusinessError } from '@kit.BasicServicesKit';
// BusinessError: 业务错误类型

/**
 * 购物车视图组件
 * @Component 装饰（非 @Entry），由 Index.ets 的 TabContent 包含
 * 集成 RDB + Preferences 双存储，支持图片缓存
 */
@Component
export struct DepartmentCartView {
  // ════════════════════════════════════════════
  //  @State 状态变量（值变化时自动刷新 UI）
  // ════════════════════════════════════════════

  /** 购物车商品列表（驱动 List 渲染的核心数据） */
  @State private cartItems: CartItem[] = [];

  /** 购物车总价（实时计算，底部统计栏显示） */
  @State private totalPrice: number = 0;

  /** 购物车总件数（标题栏显示如"购物车(3件)"） */
  @State private totalQuantity: number = 0;

  /** 是否正在加载中（加载时显示 LoadingProgress 组件） */
  @State private isLoading: boolean = true;

  /** 当前存储模式标签（UI 右上角显示"RDB + Preferences"标识） */
  @State private storageLabel: string = 'RDB + Preferences';

  /**
   * 从父组件（Index）传入的刷新触发器
   * @Prop：父组件单向传入，本组件不能修改
   * @Watch('onRefreshTriggerChanged')：值变化时自动调用 onRefreshTriggerChanged() 方法
   * 每次父组件切换到购物车 Tab 或从 ShopStorePage 返回时递增，触发数据重新加载
   */
  @Prop @Watch('onRefreshTriggerChanged') refreshTrigger: number = 0;

  /** 上次刷新时的 trigger 值，用于检测是否是真正的变化 */
  private lastRefreshTrigger: number = 0;

  // ──── 三个单例实例 ────

  /** Preferences 存储工具单例 */
  private preferencesUtil: CartPreferencesUtil = CartPreferencesUtil.getInstance();

  /** RDB 存储工具单例 */
  private rdbUtil: CartRdbUtil = CartRdbUtil.getInstance();

  /** 图片缓存管理器单例 */
  private imageCache: ImageCacheManager = ImageCacheManager.getInstance();

  // ════════════════════════════════════════════
  //  生命周期
  // ════════════════════════════════════════════

  /**
   * aboutToAppear：组件即将挂载时触发
   * 执行初始化：初始化双存储 → 设置图片缓存上下文 → 加载购物车数据
   * async 异步方法，可以在此执行 await 初始化操作
   */
  async aboutToAppear(): Promise<void> {
    try {
      // 第一步：初始化 Preferences 存储（获取 Preferences 实例）
      await this.preferencesUtil.init(getContext(this));

      // 第二步：初始化 RDB 存储（获取 RdbStore 实例 + 创建表）
      await this.rdbUtil.init(getContext(this));

      // 第三步：设置图片缓存管理器的上下文（用于读取资源文件）
      this.imageCache.setContext(getContext(this));

      // 第四步：加载购物车数据（RDB 优先 → Preferences 回退）
      await this.loadCartData();

      console.info('DepartmentCartView: 购物车初始化完成（RDB + Preferences 双存储）');
    } catch (err) {
      let error = err as BusinessError;
      console.error('DepartmentCartView: 初始化失败, code=' + error.code + ', msg=' + error.message);
    } finally {
      // 无论成功还是失败，结束加载状态
      this.isLoading = false;
    }
  }

  // ════════════════════════════════════════════
  //  @Watch 回调 + 数据加载方法
  // ════════════════════════════════════════════

  /**
   * @Watch 回调：当 refreshTrigger 属性变化时自动调用
   * 触发场景：
   *   1. 父组件 Tabs.onChange 切换到购物车 Tab(index=2)
   *   2. 父组件 onPageShow() 从 ShopStorePage 返回时
   *
   * 先检查值是否真的变了（避免 @Watch 在组件初始化时误触发），
   * 然后调用 refreshCart() 重新加载数据
   */
  private async onRefreshTriggerChanged(): Promise<void> {
    if (this.refreshTrigger !== this.lastRefreshTrigger) {
      this.lastRefreshTrigger = this.refreshTrigger;  // 记录本次值
      try {
        await this.refreshCart();  // 重新加载购物车数据
        console.info('DepartmentCartView: 购物车数据已刷新');
      } catch (err) {
        console.error('DepartmentCartView: 刷新购物车数据失败');
      }
    }
  }

  /**
   * 加载购物车数据（首次加载用）
   * 优先级：RDB > Preferences
   *   1. 优先从 RDB 获取数据
   *   2. RDB 为空时回退到 Preferences（兼容旧版本数据）
   *   3. 如果 Preferences 有数据但 RDB 没有，将 Preferences 数据同步到 RDB
   */
  private async loadCartData(): Promise<void> {
    try {
      // 第一步：从 RDB 查询购物车数据
      const rdbItems = await this.rdbUtil.getAllItems();

      if (rdbItems.length > 0) {
        // RDB 有数据：直接使用 RDB 数据
        this.cartItems = rdbItems;
      } else {
        // RDB 为空：尝试从 Preferences 加载（数据迁移兼容旧版本）
        const prefItems = await this.preferencesUtil.getAllItems();
        if (prefItems.length > 0) {
          // Preferences 有数据：使用 Preferences 数据
          this.cartItems = prefItems;
          // 将 Preferences 数据同步到 RDB（完成数据迁移）
          for (const item of prefItems) {
            await this.rdbUtil.addItem(item);
          }
          console.info('购物车数据已从 Preferences 同步到 RDB');
        }
      }

      // 更新总价和总数量
      await this.refreshTotal();
    } catch (err) {
      console.error('加载购物车数据失败');
    }
  }

  /**
   * 刷新购物车数据（刷新时用，与 loadCartData 保持相同的双读逻辑）
   * 保证在 RDB 初始化失败或数据不一致时，仍能从 Preferences 获取到数据
   */
  private async refreshCart(): Promise<void> {
    try {
      // 优先从 RDB 查询
      const rdbItems = await this.rdbUtil.getAllItems();

      if (rdbItems.length > 0) {
        this.cartItems = rdbItems;
      } else {
        // RDB 为空 → 回退到 Preferences（兼容 RDB 初始化失败的场景）
        const prefItems = await this.preferencesUtil.getAllItems();
        this.cartItems = prefItems;
      }

      await this.refreshTotal();
    } catch (err) {
      console.error('刷新购物车数据失败');
    }
  }

  /**
   * 刷新总价和总数量
   * 使用双存储合计：优先 RDB，若 RDB 无数据则用 Preferences 的合计
   * 防止 RDB 数据为空时总价显示 0
   */
  private async refreshTotal(): Promise<void> {
    // 从 RDB 获取合计
    let price = await this.rdbUtil.getTotalPrice();
    let quantity = await this.rdbUtil.getTotalQuantity();

    // 如果 RDB 合计为 0 但购物车列表有数据（说明数据来自 Preferences），
    // 则改用 Preferences 的合计
    if ((price === 0 || quantity === 0) && this.cartItems.length > 0) {
      price = await this.preferencesUtil.getTotalPrice();
      quantity = await this.preferencesUtil.getTotalQuantity();
    }

    this.totalPrice = price;
    this.totalQuantity = quantity;
  }

  // ════════════════════════════════════════════
  //  购物车操作方法（所有操作都同步更新双存储）
  // ════════════════════════════════════════════

  /**
   * 添加示例商品到购物车（测试/演示用）
   * 从 GoodsInfo 中取前 3 个网格商品 + 1 款手机作为示例
   */
  private async addSampleItems(): Promise<void> {
    try {
      const gridGoods: GoodsInfo[] = GoodsInfo.getDefaultGrid();    // 10 个网格商品
      const phoneGoods: GoodsInfo[] = GoodsInfo.getDefaultPhone();  // 6 款手机

      // 取前 3 个网格商品的名称/图片/描述/价格
      const sampleNames: string[] = [gridGoods[0].name, gridGoods[1].name, gridGoods[2].name];
      const samplePics: string[] = [gridGoods[0].pic, gridGoods[1].pic, gridGoods[2].pic];
      const sampleDescs: string[] = [gridGoods[0].desc, gridGoods[1].desc, gridGoods[2].desc];
      const samplePrices: number[] = [29.90, 15.50, 9.90];  // 模拟价格

      // 添加 3 个网格商品
      for (let i = 0; i < sampleNames.length; i++) {
        const cartItem = new CartItem(
          'cart_' + i,          // id：固定前缀 + 索引（示例数据用固定 id，多次添加会累加数量）
          sampleNames[i],       // name：如"商场""超市"
          samplePrices[i],      // price：29.90 / 15.50 / 9.90
          1,                    // quantity：默认 1
          samplePics[i],        // image：如 'app.media.pic_01'
          sampleDescs[i]        // desc：空字符串
        );
        // 双存储：同时写入 RDB 和 Preferences
        await this.rdbUtil.addItem(cartItem);
        await this.preferencesUtil.addItem(cartItem);
      }

      // 添加一款手机（取第 1 款：iPhone11）
      if (phoneGoods.length > 0) {
        const phoneItem = new CartItem(
          'cart_phone',              // id：固定标识
          phoneGoods[0].name,        // name：'iPhone11'
          phoneGoods[0].price,       // price：4999.00
          1,                         // quantity：1
          phoneGoods[0].pic,         // image：'app.media.iphone'
          phoneGoods[0].desc         // desc：完整型号描述
        );
        await this.rdbUtil.addItem(phoneItem);
        await this.preferencesUtil.addItem(phoneItem);
      }

      // 刷新购物车显示
      await this.refreshCart();
    } catch (err) {
      let error = err as BusinessError;
      console.error('添加示例商品失败: ' + error.message);
    }
  }

  /** 增加商品数量（同步更新双存储）+1 */
  private async increaseQuantity(item: CartItem): Promise<void> {
    try {
      // 从当前购物车列表中查找商品，确保使用最新的数量
      const currentItem = this.cartItems.find(cartItem => cartItem.id === item.id);
      const currentQuantity = currentItem ? currentItem.quantity : item.quantity;
      const newQuantity: number = currentQuantity + 1;
      
      // 先更新本地数组，实现UI即时响应
      const itemIndex = this.cartItems.findIndex(cartItem => cartItem.id === item.id);
      if (itemIndex !== -1) {
        // 创建新的CartItem对象，确保ArkUI检测到变化
        const updatedItem = new CartItem(
          this.cartItems[itemIndex].id,
          this.cartItems[itemIndex].name,
          this.cartItems[itemIndex].price,
          newQuantity,
          this.cartItems[itemIndex].image,
          this.cartItems[itemIndex].desc
        );
        // 创建新数组以触发UI更新
        const newCartItems = [...this.cartItems];
        newCartItems[itemIndex] = updatedItem;
        this.cartItems = newCartItems;
      }
      
      // 然后更新数据库
      await this.rdbUtil.updateQuantity(item.id, newQuantity);
      await this.preferencesUtil.updateQuantity(item.id, newQuantity);
      
      // 最后刷新总价和总数量
      await this.refreshTotal();
    } catch (err) {
      console.error('增加数量失败');
    }
  }

  /** 减少商品数量（同步更新双存储）-1，最少为 0（=删除） */
  private async decreaseQuantity(item: CartItem): Promise<void> {
    try {
      // 从当前购物车列表中查找商品，确保使用最新的数量
      const currentItem = this.cartItems.find(cartItem => cartItem.id === item.id);
      const currentQuantity = currentItem ? currentItem.quantity : item.quantity;
      const newQuantity: number = Math.max(0, currentQuantity - 1);
      
      // 先更新本地数组，实现UI即时响应
      const itemIndex = this.cartItems.findIndex(cartItem => cartItem.id === item.id);
      if (itemIndex !== -1) {
        if (newQuantity === 0) {
          // 数量为0，从购物车中移除
          const newCartItems = [...this.cartItems];
          newCartItems.splice(itemIndex, 1);
          this.cartItems = newCartItems;
        } else {
          // 创建新的CartItem对象，确保ArkUI检测到变化
          const updatedItem = new CartItem(
            this.cartItems[itemIndex].id,
            this.cartItems[itemIndex].name,
            this.cartItems[itemIndex].price,
            newQuantity,
            this.cartItems[itemIndex].image,
            this.cartItems[itemIndex].desc
          );
          // 创建新数组以触发UI更新
          const newCartItems = [...this.cartItems];
          newCartItems[itemIndex] = updatedItem;
          this.cartItems = newCartItems;
        }
      }
      
      // 然后更新数据库
      await this.rdbUtil.updateQuantity(item.id, newQuantity);
      await this.preferencesUtil.updateQuantity(item.id, newQuantity);
      
      // 最后刷新总价和总数量
      await this.refreshTotal();
    } catch (err) {
      console.error('减少数量失败');
    }
  }

  /** 删除单个商品（同步从双存储移除） */
  private async removeItem(itemId: string): Promise<void> {
    try {
      // 先更新本地数组，实现UI即时响应
      const itemIndex = this.cartItems.findIndex(cartItem => cartItem.id === itemId);
      if (itemIndex !== -1) {
        const newCartItems = [...this.cartItems];
        newCartItems.splice(itemIndex, 1);
        this.cartItems = newCartItems;
      }
      
      // 然后更新数据库
      await this.rdbUtil.removeItem(itemId);
      await this.preferencesUtil.removeItem(itemId);
      
      // 最后刷新总价和总数量
      await this.refreshTotal();
    } catch (err) {
      console.error('删除商品失败');
    }
  }

  /** 清空购物车（同步清空双存储） */
  private async clearCart(): Promise<void> {
    try {
      // 先更新本地数组，实现UI即时响应
      this.cartItems = [];
      
      // 然后更新数据库
      await this.rdbUtil.clearCart();
      await this.preferencesUtil.clearCart();
      
      // 最后刷新总价和总数量
      await this.refreshTotal();
    } catch (err) {
      console.error('清空购物车失败');
    }
  }

  /** 跳转到手机商城页面（router.pushUrl） */
  private navigateToStore(): void {
    router.pushUrl({ url: 'pages/ShopStorePage' });
  }

  // ════════════════════════════════════════════
  //  UI 构建
  // ════════════════════════════════════════════

  build() {
    Column() {
      // ════════════════════════════════════════════
      //  顶部：标题栏（图标 + 标题 + 数量 + 标签 + 操作按钮）
      // ════════════════════════════════════════════
      Row() {
        Text('🛒')                          // 购物车图标 emoji
          .fontSize(22)
          .margin({ right: 8 })

        Text('购物车')                       // "购物车" 标题
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        if (this.totalQuantity > 0) {
          // 显示商品数量，如"(3件)"
          Text('(' + this.totalQuantity + '件)')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 4 })
        }

        // 弹性空间：将右侧按钮推到右边
        Blank().layoutWeight(1)

        // 存储方式标签（蓝色小圆点标识）
        Text(this.storageLabel)
          .fontSize(9).fontColor('#007DFF')
          .backgroundColor('#E8F4FF')
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .borderRadius(3)
          .margin({ right: 6 })

        // "📱 商城" 跳转按钮（透明背景，只有文字）
        Button('📱 商城')
          .fontSize(12).fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .margin({ right: 4 })
          .padding({ left: 6, right: 6 })
          .onClick(() => this.navigateToStore())

        // "🗑 清空" 按钮（仅购物车有商品时显示）
        if (this.cartItems.length > 0) {
          Button('🗑 清空')
            .fontSize(12).fontColor('#FF4444')
            .backgroundColor(Color.Transparent)
            .padding({ left: 6, right: 6 })
            .onClick(() => this.clearCart())
        }

        // "➕ 添加示例" 按钮（测试用）
        Button('➕ 示例')
          .fontSize(12).fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .padding({ left: 6, right: 6 })
          .onClick(() => this.addSampleItems())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)

      // 标题栏下方的分割线
      Divider().strokeWidth(0.5).color('#E8E8E8')

      // ════════════════════════════════════════════
      //  内容区域：三态显示（加载中 / 空购物车 / 商品列表）
      // ════════════════════════════════════════════
      if (this.isLoading) {
        // 状态一：正在加载中 → 显示 LoadingProgress 转圈动画
        Column() {
          LoadingProgress().width(40).height(40).color('#007DFF')
          Text('加载购物车数据...').fontSize(14).fontColor('#999999').margin({ top: 12 })
        }
        .layoutWeight(1)                // 占据剩余所有垂直空间
        .justifyContent(FlexAlign.Center)  // 垂直居中

      } else if (this.cartItems.length === 0) {
        // 状态二：购物车为空 → 显示空状态提示
        Column() {
          Text('🛒').fontSize(60).opacity(0.3)          // 大号半透明购物车图标

          Text('购物车是空的').fontSize(16).fontColor('#CCCCCC').margin({ top: 12 })

          Text('去手机商城挑选商品吧').fontSize(13).fontColor('#CCCCCC').margin({ top: 6 })

          // "📱 去手机商城" 主按钮（蓝色圆角）
          Button('📱 去手机商城')
            .width(180).height(40).fontSize(15)
            .backgroundColor('#007DFF').borderRadius(20)
            .margin({ top: 24 })
            .onClick(() => this.navigateToStore())

          // "添加示例商品" 副按钮（灰色）
          Button('添加示例商品')
            .width(180).height(40).fontSize(14)
            .backgroundColor('#F0F0F0').borderRadius(20)
            .fontColor('#666666')
            .margin({ top: 12 })
            .onClick(() => this.addSampleItems())
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else {
        // 状态三：购物车有商品 → 显示 List 列表
        List({ space: 2 }) {              // space=2：列表项之间间距 2
          ForEach(this.cartItems, (item: CartItem, index: number) => {
            ListItem() {
              // 使用 @Builder CartItemRow 渲染每个商品行
              this.CartItemRow(item, index)
            }
          }, (item: CartItem) => item.id)  // key 生成：用商品 id 作为唯一标识
        }
        .layoutWeight(1)                  // 占据剩余所有垂直空间（撑满列表区域）
        .width('100%')
      }

      // ════════════════════════════════════════════
      //  底部：总价统计栏 + 操作按钮（仅购物车有商品时显示）
      // ════════════════════════════════════════════
      if (this.cartItems.length > 0) {
        Divider().strokeWidth(0.5).color('#E8E8E8')  // 分割线

        Row() {
          Text('合计：').fontSize(16).fontColor('#333333')

          // 总价金额（红色加粗）
          Text('¥' + this.totalPrice.toFixed(2))
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FF4444')

          Blank()  // 弹性空间

          // "去商城 📱" 按钮
          Button('去商城 📱')
            .fontSize(13).fontColor('#007DFF')
            .backgroundColor('#E8F4FF').borderRadius(16)
            .height(32).margin({ right: 8 })
            .padding({ left: 12, right: 12 })
            .onClick(() => this.navigateToStore())

          // "去结算" 按钮（红色）
          Button('去结算')
            .width(110).height(42).fontSize(16)
            .backgroundColor('#FF4444').borderRadius(21)
            .onClick(() => {
              console.info('结算按钮被点击');
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 110 })      // 底部留白 110，避免被导航栏遮挡
    .backgroundColor('#F5F5F5')    // 浅灰背景
  }

  // ════════════════════════════════════════════
  //  @Builder 商品行组件
  //  使用 @Builder 装饰器定义可复用的 UI 构建函数
  // ════════════════════════════════════════════

  /**
   * 单个购物车商品行 UI
   * 布局：左侧图片 | 中间信息（名称/描述/价格） | 右侧数量控制 | 删除按钮
   *
   * @param item  - 购物车商品项
   * @param index - 在列表中的索引（用于背景色）
   */
  @Builder
  CartItemRow(item: CartItem, index: number) {
    Row() {
      // ── 左侧：商品图片（64x64 圆角矩形） ──
      Stack() {
        if (item.image && item.image.length > 0) {
          // 有图片：通过 getImageResource() 映射函数加载 Resource 对象
          // 不能直接用 $r(item.image) 因为 item.image 是运行时变量
          Image(this.getImageResource(item.image))
            .width(64).height(64)
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
        } else {
          // 无图片：显示商品名称首字作为占位符
          Text(item.name.substring(0, 1))
            .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
        }
      }
      .width(64).height(64).borderRadius(8)
      .backgroundColor(this.getColorByIndex(index))  // 根据索引取不同颜色

      // ── 中间：商品信息区（名称 + 描述 + 价格） ──
      Column() {
        Text(item.name)                                                           // 商品名称
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333333')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })          // 超长显示...

        if (item.desc && item.desc.length > 0) {
          Text(item.desc)                                                         // 商品描述
            .fontSize(11).fontColor('#999999')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 1 })
        }

        Text('¥' + item.price.toFixed(2))                                        // 商品单价
          .fontSize(13).fontColor('#FF4444').fontWeight(FontWeight.Medium)
          .margin({ top: 2 })
      }
      .layoutWeight(1)              // 占据剩余所有水平空间
      .alignItems(HorizontalAlign.Start)  // 左对齐
      .margin({ left: 8, right: 6 })

      // ── 右侧：数量控制区（- 数量 +） ──
      Row() {
        Button('-')
          .width(28).height(28).fontSize(16)
          .fontColor('#333333').backgroundColor('#F0F0F0')
          .borderRadius(14).padding(0)
          .onClick(() => this.decreaseQuantity(item))

        Text('' + item.quantity)                                                   // 当前数量
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
          .width(36).textAlign(TextAlign.Center)

        Button('+')
          .width(28).height(28).fontSize(16)
          .fontColor(Color.White).backgroundColor('#007DFF')
          .borderRadius(14).padding(0)
          .onClick(() => this.increaseQuantity(item))
      }
      .alignItems(VerticalAlign.Center)

      // ── 删除按钮 ──
      Button('✕')
        .width(32).height(32).fontSize(14)
        .fontColor('#CCCCCC').backgroundColor(Color.Transparent)
        .borderRadius(16).padding(0).margin({ left: 4 })
        .onClick(() => this.removeItem(item.id))
    }
    .width('100%')
    .height(88)                     // 商品行高度 88
    .padding({ left: 12, right: 16 })  // 增加右侧内边距，确保删除按钮完全显示
    .backgroundColor(Color.White)
  }

  // ════════════════════════════════════════════
  //  工具方法
  // ════════════════════════════════════════════

  /**
   * 根据资源名称字符串获取对应的 Resource 对象
   *
   * 【为什么需要这个方法？】
   * $r() 是编译期函数，不能接受运行时字符串作为参数。
   * 而购物车中商品的图片路径是运行时从存储中读取的字符串，
   * 所以需要用 switch 映射表，将已知的资源名称字符串
   * 映射到编译期确定的 $r() 调用上。
   *
   * @param resName - 资源名称字符串（如 'app.media.iphone'）
   * @returns {Resource} 编译期确定的 Resource 对象
   */
  private getImageResource(resName: string): Resource {
    // 去掉 'app.media.' 前缀，只保留纯文件名，用于 switch 匹配
    const key: string = resName.startsWith('app.media.') ? resName.substring(10) : resName;
    switch (key) {
      // ── 6 款手机图片映射 ──
      case 'iphone':  return $r('app.media.iphone');  // Apple iPhone11 图片
      case 'huawei':  return $r('app.media.huawei');  // 华为 Mate30 图片
      case 'xiaomi':  return $r('app.media.xiaomi');  // 小米10 图片
      case 'oppo':    return $r('app.media.oppo');    // OPPO Reno3 图片
      case 'vivo':    return $r('app.media.vivo');    // vivo X30 图片
      case 'rongyao': return $r('app.media.rongyao'); // 荣耀30S 图片

      // ── 10 个网格普通商品图片映射（pic_01 ~ pic_10） ──
      case 'pic_01':  return $r('app.media.pic_01');
      case 'pic_02':  return $r('app.media.pic_02');
      case 'pic_03':  return $r('app.media.pic_03');
      case 'pic_04':  return $r('app.media.pic_04');
      case 'pic_05':  return $r('app.media.pic_05');
      case 'pic_06':  return $r('app.media.pic_06');
      case 'pic_07':  return $r('app.media.pic_07');
      case 'pic_08':  return $r('app.media.pic_08');
      case 'pic_09':  return $r('app.media.pic_09');
      case 'pic_10':  return $r('app.media.pic_10');

      default:
        // 未知图片：用 iPhone 图片作为默认占位
        return $r('app.media.iphone');
    }
  }

  /**
   * 根据索引获取对应的背景颜色（循环使用 12 种颜色）
   * 用于商品图片占位区的背景色，让每件商品视觉上可区分
   *
   * @param index - 商品在列表中的索引
   * @returns {ResourceColor} 颜色值（十六进制格式）
   */
  private getColorByIndex(index: number): ResourceColor {
    const colors: ResourceColor[] = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',  // 红 / 青 / 蓝 / 绿
      '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F',  // 黄 / 紫 / 青绿 / 金
      '#BB8FCE', '#85C1E9', '#F0B27A', '#82E0AA'   // 紫罗兰 / 天蓝 / 橙 / 薄荷
    ];
    // 用取模运算循环使用颜色（index=12 回到第 1 种颜色）
    return colors[index % colors.length];
  }
}
