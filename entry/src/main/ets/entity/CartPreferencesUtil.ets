/**
 * =============================================================================
 *  CartPreferencesUtil - 购物车数据持久化工具类（首选项存储）
 * =============================================================================
 * 【作用】
 *   基于 HarmonyOS 用户首选项（Preferences）实现购物车数据的持久化存储。
 *   将 CartItem[] 序列化为 JSON 字符串后以 Key-Value 形式存入首选项文件。
 *
 * 【数据存储方案】
 *   存储方式：Preferences（用户首选项，内存缓存 + 文件持久化）
 *   存储键名：'cart_items'（文件内存储的 Key 名称）
 *   文件名称：'cart_store'（首选项文件名称）
 *   存储格式：CartItem[] → JSON.stringify → 字符串
 *
 * 【为什么选择 Preferences】
 *   1. 轻量级：购物车通常只有几十件商品，无需关系型数据库的复杂度
 *   2. 快速读写：数据缓存在内存中，get() 操作几乎是瞬间完成
 *   3. 简单可靠：Key-Value 结构 + flush() 确保持久化
 *
 * 【核心方法】
 *   查 - getAllItems()  读取全部购物车数据
 *   增 - addItem()      添加商品（已存在则增加数量）
 *   改 - updateQuantity() 更新指定商品数量
 *   删 - removeItem()   移除指定商品
 *   清 - clearCart()    清空全部数据
 *   统 - getTotalPrice()  计算总价
 *   统 - getTotalQuantity() 计算总数量
 *
 * 【单例模式】
 *   整个应用共享同一个 CartPreferencesUtil 实例，避免重复创建 Preferences 对象。
 * =============================================================================
 */

import { preferences } from '@kit.ArkData';
// preferences: 用户首选项模块，提供 getPreferences / put / get / delete / flush 等 API

import { BusinessError } from '@kit.BasicServicesKit';
// BusinessError: 业务错误类型，含 code（错误码）和 message（错误描述）

import { CartItem } from './CartItem';
// CartItem: 购物车商品项数据模型，包含 id/name/price/quantity/image/desc 六个字段

/** 日志标签，用于 console 输出时标识日志来源 */
const TAG: string = 'CartPreferencesUtil';

/** Preferences 持久化文件的名称（一个文件对应一个 Preferences 实例） */
const PREFERENCES_NAME: string = 'cart_store';

/** 购物车数据在 Preferences 中对应的键名 */
const CART_ITEMS_KEY: string = 'cart_items';

/**
 * 购物车数据持久化工具类（单例模式）
 * 封装了对购物车数据的完整 CRUD 操作，所有数据通过 Preferences 实现持久化
 */
export class CartPreferencesUtil {
  /** 唯一的单例实例（static 类级别变量，所有地方共用同一个实例） */
  private static instance: CartPreferencesUtil;

  /** Preferences 实例（被缓存在内存中，避免重复读取文件） */
  private dataPreferences: preferences.Preferences | null = null;

  /** 应用上下文，用于获取 Preferences 实例（通过 getPreferences(context, name)） */
  private context: Context | null = null;

  /** 是否已初始化的标记，防止重复调用 init() */
  private isInitialized: boolean = false;

  /**
   * 私有构造函数（单例模式不允许外部使用 new 实例化）
   * 必须通过 CartPreferencesUtil.getInstance() 获取实例
   */
  private constructor() {}

  /**
   * 获取 CartPreferencesUtil 单例实例
   * 第一次调用时创建实例，后续复用该实例
   *
   * @returns {CartPreferencesUtil} 工具类单例
   */
  public static getInstance(): CartPreferencesUtil {
    if (!CartPreferencesUtil.instance) {
      // 首次调用：创建新实例并缓存到静态变量中
      CartPreferencesUtil.instance = new CartPreferencesUtil();
    }
    // 后续调用：直接返回已缓存的实例
    return CartPreferencesUtil.instance;
  }

  /**
   * 初始化 Preferences 实例
   * 通过 preferences.getPreferences() 获取指定名称的 Preferences 对象。
   * 可多次调用，只有首次调用会真正执行初始化（已初始化时直接返回）。
   *
   * @param context - 应用上下文，从 @Entry 页面通过 getContext(this) 获取
   * @returns {Promise<void>} 初始化完成的 Promise
   */
  public async init(context: Context): Promise<void> {
    if (this.isInitialized && this.dataPreferences) {
      // 已初始化：直接返回，避免重复读取文件
      return;
    }

    try {
      // getPreferences(context, fileName)：
      // 第一个参数是应用上下文，第二个参数是首选项文件名称（不含路径）
      // 返回值是 Promise<Preferences>
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      // 缓存上下文（部分高级操作可能需要用到）
      this.context = context;
      // 标记为已初始化
      this.isInitialized = true;
      console.info(`${TAG}: Preferences 初始化成功`);
    } catch (err) {
      // 将 err 断言为 BusinessError 类型，获取 code 和 message
      let error = err as BusinessError;
      console.error(`${TAG}: Preferences 初始化失败, code=${error.code}, msg=${error.message}`);
      // 向上抛出异常，由调用方处理（如 DepartmentCartView.aboutToAppear）
      throw new Error('Preferences 初始化失败');
    }
  }

  /**
   * 获取购物车中所有商品（查询全部）
   * 从 Preferences 中读取持久化的 JSON 字符串，反序列化为 CartItem[]。
   *
   * @returns {Promise<CartItem[]>} 购物车商品列表，无数据或出错时返回空数组
   */
  public async getAllItems(): Promise<CartItem[]> {
    try {
      if (!this.dataPreferences) {
        // Preferences 未初始化：给出警告并返回空数组（避免调用方崩溃）
        console.warn(`${TAG}: Preferences 未初始化，返回空数组`);
        return [];
      }

      // get(key, defaultValue)：
      // 从 Preferences 中读取指定键的值，第二个参数是默认值（键不存在时返回）
      // 返回值是 Promise<ValueType>，需要 await 获取实际值
      const jsonStr = await this.dataPreferences.get(CART_ITEMS_KEY, '[]');

      // 将 ValueType 转为 string 类型
      const jsonStrValue = jsonStr as string;
      // JSON.parse 将 JSON 字符串解析为 JavaScript 对象/数组
      const parsed = JSON.parse(jsonStrValue) as CartItem[];

      // 防御性检查：确保 parsed 确实是数组（JSON.parse 可能返回非数组类型）
      let cartItems: CartItem[] = [];
      if (Array.isArray(parsed)) {
        // 只有 parsed 是数组时才赋值，否则保持空数组
        cartItems = parsed;
      }

      console.info(TAG + ': 获取购物车数据成功，共 ' + cartItems.length + ' 件商品');
      return cartItems;
    } catch (err) {
      // 出错了（如 JSON 格式错误）：返回空数组，避免 UI 崩溃
      let error = err as BusinessError;
      console.error(`${TAG}: 获取购物车数据失败, code=${error.code}, msg=${error.message}`);
      return [];
    }
  }

  /**
   * 添加商品到购物车
   * 如果商品 ID 已存在则增加数量，否则新增一条记录。
   * 操作完成后自动调用 saveItems() 持久化到磁盘。
   *
   * @param item - 要添加的购物车商品项
   * @returns {Promise<boolean>} true=操作成功，false=操作失败
   */
  public async addItem(item: CartItem): Promise<boolean> {
    try {
      // 第一步：获取现有购物车数据
      const items: CartItem[] = await this.getAllItems();

      // 第二步：查找是否已存在该商品（根据 id 判断）
      let found: boolean = false;
      for (let i = 0; i < items.length; i++) {
        if (items[i].id === item.id) {
          // 已存在：增加数量（如从 1 加到 2）
          items[i].quantity += item.quantity;
          found = true;
          console.info(`${TAG}: 商品 ${item.name} 已存在，数量增加至 ${items[i].quantity}`);
          break;  // 找到后立即跳出循环
        }
      }

      if (!found) {
        // 不存在：将新商品追加到数组末尾
        items.push(item);
        console.info(`${TAG}: 新增商品 ${item.name} 到购物车`);
      }

      // 第三步：持久化保存到磁盘
      await this.saveItems(items);
      return true;  // 操作成功
    } catch (err) {
      let error = err as BusinessError;
      console.error(`${TAG}: 添加商品失败, code=${error.code}, msg=${error.message}`);
      return false; // 操作失败
    }
  }

  /**
   * 更新购物车中某商品的数量
   * 如果新数量 <= 0，则从购物车中移除该商品。
   *
   * @param itemId      - 要更新的商品 id
   * @param newQuantity - 新的数量（<=0 时删除该商品）
   * @returns {Promise<boolean>} true=操作成功，false=操作失败（商品不存在）
   */
  public async updateQuantity(itemId: string, newQuantity: number): Promise<boolean> {
    try {
      const items: CartItem[] = await this.getAllItems();

      if (newQuantity <= 0) {
        // 数量 <= 0：调用 removeItem() 移除该商品
        return await this.removeItem(itemId);
      }

      // 查找目标商品并更新数量
      let found: boolean = false;
      for (let i = 0; i < items.length; i++) {
        if (items[i].id === itemId) {
          items[i].quantity = newQuantity;  // 更新数量为新值
          found = true;
          break;  // 找到后立即退出循环
        }
      }

      if (!found) {
        // 未找到指定 id 的商品
        console.warn(`${TAG}: 未找到商品 id=${itemId}`);
        return false;
      }

      // 持久化保存
      await this.saveItems(items);
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`${TAG}: 更新数量失败, code=${error.code}, msg=${error.message}`);
      return false;
    }
  }

  /**
   * 从购物车中移除指定商品
   *
   * @param itemId - 要移除的商品 id
   * @returns {Promise<boolean>} true=操作成功，false=操作失败（商品不存在）
   */
  public async removeItem(itemId: string): Promise<boolean> {
    try {
      const items: CartItem[] = await this.getAllItems();

      // 查找目标商品的索引位置
      let index: number = -1;  // -1 表示未找到
      for (let i = 0; i < items.length; i++) {
        if (items[i].id === itemId) {
          index = i;  // 记录找到的索引
          break;
        }
      }

      if (index === -1) {
        // 未找到要移除的商品
        console.warn(`${TAG}: 未找到要移除的商品 id=${itemId}`);
        return false;
      }

      // splice(index, 1)：从数组中删除 index 位置的 1 个元素
      items.splice(index, 1);
      console.info(`${TAG}: 移除商品成功，剩余 ${items.length} 件`);

      // 持久化保存
      await this.saveItems(items);
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`${TAG}: 移除商品失败, code=${error.code}, msg=${error.message}`);
      return false;
    }
  }

  /**
   * 清空购物车（删除所有数据）
   *
   * @returns {Promise<boolean>} true=操作成功，false=操作失败
   */
  public async clearCart(): Promise<boolean> {
    try {
      if (!this.dataPreferences) {
        return false;
      }

      // delete(key)：从 Preferences 缓存中删除指定键值对
      await this.dataPreferences.delete(CART_ITEMS_KEY);

      // flush()：将内存中的变更写入磁盘文件（关键步骤！必须调用）
      await this.dataPreferences.flush();
      console.info(`${TAG}: 购物车已清空`);
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`${TAG}: 清空购物车失败, code=${error.code}, msg=${error.message}`);
      return false;
    }
  }

  /**
   * 计算购物车中所有商品的总价
   *
   * @returns {Promise<number>} 总价（保留两位小数），如 847.30
   */
  public async getTotalPrice(): Promise<number> {
    try {
      const items: CartItem[] = await this.getAllItems();
      let total: number = 0;
      for (let i = 0; i < items.length; i++) {
        total += items[i].getSubtotal();  // 累加每个商品的小计
      }
      return Math.round(total * 100) / 100;  // 保留两位小数
    } catch (err) {
      console.error(`${TAG}: 计算总价失败`);
      return 0;  // 出错时返回 0，避免 UI 显示 NaN
    }
  }

  /**
   * 获取购物车中商品的总数量
   *
   * @returns {Promise<number>} 商品总件数（合并所有商品的 quantity）
   */
  public async getTotalQuantity(): Promise<number> {
    try {
      const items: CartItem[] = await this.getAllItems();
      let total: number = 0;
      for (let i = 0; i < items.length; i++) {
        total += items[i].quantity;  // 累加每个商品的数量
      }
      return total;
    } catch (err) {
      return 0;  // 出错时返回 0
    }
  }

  /**
   * 将购物车数据持久化到磁盘（内部工具方法）
   *
   * 核心三步：
   *   1. JSON.stringify(items)：将 CartItem[] 序列化为 JSON 字符串
   *   2. put(key, jsonStr)：写入 Preferences 内存缓存
   *   3. flush()：将内存数据写入磁盘文件（关键！不调用则数据丢失）
   *
   * @param items - 要保存的购物车商品列表
   * @returns {Promise<void>}
   */
  private async saveItems(items: CartItem[]): Promise<void> {
    if (!this.dataPreferences) {
      console.error(`${TAG}: Preferences 未初始化，无法保存数据`);
      return;
    }

    try {
      // 第一步：将 CartItem[] 序列化为 JSON 字符串
      // JSON.stringify 会序列化所有 public 属性的值
      const jsonStr: string = JSON.stringify(items);

      // 第二步：写入 Preferences 内存缓存（put 操作很快）
      await this.dataPreferences.put(CART_ITEMS_KEY, jsonStr);

      // 第三步：持久化到磁盘文件（flush 是确保数据不丢失的关键）
      await this.dataPreferences.flush();

      console.info(`${TAG}: 购物车数据持久化成功，共 ${items.length} 件商品`);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`${TAG}: 数据持久化失败, code=${error.code}, msg=${error.message}`);
    }
  }
}
