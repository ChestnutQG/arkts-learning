/**
 * =============================================================================
 *  CartRdbUtil - 关系型数据库(RDB)购物车存储工具类
 * =============================================================================
 * 【作用】
 *   使用 HarmonyOS 关系型数据库（Relational Database, RDB）实现购物车数据的持久化。
 *   与 CartPreferencesUtil（首选项存储）形成双存储方案，共同演示两种主要持久化方式。
 *
 * 【RDB vs Preferences 对比】
 *   ┌──────────────┬────────────────────────────┬──────────────────────────┐
 *   │              │  RDB（关系型数据库）         │  Preferences（首选项）    │
 *   ├──────────────┼────────────────────────────┼──────────────────────────┤
 *   │ 存储结构      │ 表 + 行 + 列（结构化数据）   │ 键值对（Key-Value）       │
 *   │ 数据查询      │ SQL 查询（灵活强大）         │ 按 key 精确查询           │
 *   │ 适用场景      │ 结构化大数据、复杂条件查询    │ 轻量级配置/状态           │
 *   │ 性能特点      │ 适合复杂查询，写入开销较大   │ 简单读写极快             │
 *   └──────────────┴────────────────────────────┴──────────────────────────┘
 *
 * 【数据库表结构】
 *   表名：cart_items
 *   ┌──────────┬──────────┬────────────────────────────────┐
 *   │ 字段名    │ 类型     │ 说明                           │
 *   ├──────────┼──────────┼────────────────────────────────┤
 *   │ id       │ TEXT PK  │ 商品唯一标识（主键）            │
 *   │ name     │ TEXT NN  │ 商品名称                       │
 *   │ price    │ REAL     │ 商品单价（元）                  │
 *   │ quantity │ INTEGER  │ 购买数量                       │
 *   │ image    │ TEXT     │ 商品图片资源路径                 │
 *   │ desc     │ TEXT     │ 商品描述信息                   │
 *   └──────────┴──────────┴────────────────────────────────┘
 *
 * 【单例模式】
 *   整个应用共享同一个 CartRdbUtil 实例，避免重复打开数据库文件。
 * =============================================================================
 */

import { relationalStore } from '@kit.ArkData';
// relationalStore: 关系型数据库模块，提供 getRdbStore / RdbPredicates / RdbStore 等 API

import { CartItem } from './CartItem';
// CartItem: 购物车商品项数据模型

import { BusinessError } from '@kit.BasicServicesKit';
// BusinessError: 业务错误类型，用于统一的错误捕获和处理

/** 数据库文件名（存储在应用沙箱内，卸载应用时自动删除） */
const RDB_DATABASE_NAME: string = 'cart_rdb.db';

/** 数据库表名 */
const RDB_TABLE_NAME: string = 'cart_items';

/** 数据库版本号（升级表结构时递增此版本号） */
const RDB_VERSION: number = 1;

/** 日志标签，用于 console 输出时标识日志来源 */
const TAG: string = 'CartRdbUtil';

/**
 * RDB 购物车存储工具类（单例模式）
 * 提供完整的 CRUD（创建/读取/更新/删除）操作接口
 */
export class CartRdbUtil {
  /** 单例实例（static 类级别变量） */
  private static instance: CartRdbUtil;

  /** RDB 存储实例，通过 getRdbStore() 获取，用于执行 SQL 操作 */
  private rdbStore: relationalStore.RdbStore | null = null;

  /** 应用上下文，用于获取数据库路径 */
  private context: Context | null = null;

  /** 是否已初始化的标记，防止重复调用 init() */
  private isInit: boolean = false;

  /**
   * 私有构造函数（单例模式不允许外部 new 实例化）
   * 必须通过 CartRdbUtil.getInstance() 获取实例
   */
  private constructor() {}

  /**
   * 获取 CartRdbUtil 单例实例
   * 第一次调用时创建，后续复用已创建的实例
   *
   * @returns {CartRdbUtil} RDB 存储工具类实例
   */
  public static getInstance(): CartRdbUtil {
    if (!CartRdbUtil.instance) {
      // 首次调用：创建新实例
      CartRdbUtil.instance = new CartRdbUtil();
    }
    return CartRdbUtil.instance;
  }

  /**
   * 初始化 RDB 数据库（首次调用时创建表，后续调用直接返回）
   *
   * 执行流程：
   *   1. 配置 StoreConfig（数据库名称、安全等级、加密选项）
   *   2. 调用 getRdbStore() 获取（或创建）数据库实例
   *   3. 执行 CREATE TABLE IF NOT EXISTS 创建 cart_items 表
   *
   * @param context - 应用上下文，用于确定数据库文件路径
   */
  public async init(context: Context): Promise<void> {
    if (this.isInit) {
      // 已经初始化：直接返回，避免重复操作
      return;
    }

    this.context = context;

    try {
      // 配置数据库连接参数
      const config: relationalStore.StoreConfig = {
        name: RDB_DATABASE_NAME,                                              // 数据库文件名：cart_rdb.db
        securityLevel: relationalStore.SecurityLevel.S1,                       // 安全等级 S1（最低级，适合非敏感数据）
        encrypt: false,                                                        // 不加密（示例应用，不考虑数据加密）
        customDir: undefined                                                   // 使用默认数据库目录
      };

      // getRdbStore(context, config)：
      // 如果数据库文件不存在则创建，存在则直接打开
      // 返回值是 Promise<RdbStore>
      this.rdbStore = await relationalStore.getRdbStore(context, config);

      // 创建购物车表（如果不存在则创建）
      // PRIMARY KEY：设置 id 为主键（唯一标识，不允许重复）
      // NOT NULL：表示该字段不允许为空
      // DEFAULT 1：quantity 字段默认值为 1
      const createTableSql: string =
        'CREATE TABLE IF NOT EXISTS ' + RDB_TABLE_NAME + ' (' +
        'id TEXT PRIMARY KEY, ' +       // id：文本类型，主键
        'name TEXT NOT NULL, ' +         // name：文本类型，非空
        'price REAL NOT NULL, ' +        // price：实数类型，非空
        'quantity INTEGER NOT NULL DEFAULT 1, ' +  // quantity：整数类型，默认 1
        'image TEXT, ' +                 // image：文本类型，可空
        'desc TEXT' +                    // desc：文本类型，可空
        ')';

      // executeSql()：执行 SQL 建表语句
      await this.rdbStore.executeSql(createTableSql);
      this.isInit = true;  // 标记为已初始化
      console.info(TAG + ': RDB 数据库初始化成功');
    } catch (err) {
      // 初始化失败时，isInit 保持 false，后续操作通过 checkInit() 检查
      let error = err as BusinessError;
      console.error(TAG + ': RDB 数据库初始化失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 将 CartItem 转换为 RDB 行数据（ValuesBucket）
   * ValuesBucket 是 RDB 插入/更新操作所需的键值对格式
   *
   * @param item - 购物车商品项
   * @returns {relationalStore.ValuesBucket} 可用于 RDB 插入/更新的数据
   */
  private itemToValues(item: CartItem): relationalStore.ValuesBucket {
    return {
      'id': item.id,           // 主键：商品唯一标识
      'name': item.name,       // 商品名称
      'price': item.price,     // 商品价格
      'quantity': item.quantity, // 购买数量
      'image': item.image,     // 图片路径
      'desc': item.desc        // 商品描述
    };
  }

  /**
   * 将 RDB 查询结果行（ValuesBucket）转换为 CartItem 对象
   * 从 ValuesBucket 中按字段名取出数据，创建新的 CartItem 实例
   *
   * @param row - 查询结果的一行数据（ValuesBucket 格式）
   * @returns {CartItem} 购物车商品项
   */
  private rowToItem(row: relationalStore.ValuesBucket): CartItem {
    return new CartItem(
      row['id'] as string,        // 将 ValuesBucket 中的 id 字段转为 string
      row['name'] as string,      // name 字段转为 string
      row['price'] as number,     // price 字段转为 number
      row['quantity'] as number,  // quantity 字段转为 number
      row['image'] as string,     // image 字段转为 string
      row['desc'] as string       // desc 字段转为 string
    );
  }

  /**
   * 检查 RDB 是否已初始化
   * 所有 CRUD 操作前都应调用此方法检查状态
   *
   * @returns {boolean} true=已初始化，false=未初始化
   */
  private checkInit(): boolean {
    if (!this.isInit || !this.rdbStore) {
      console.error(TAG + ': RDB 未初始化，请先调用 init()');
      return false;
    }
    return true;
  }

  /**
   * 获取购物车中的所有商品（查询全部）
   * 构建空条件的 RdbPredicates，查询 cart_items 表中所有行
   *
   * 【RDB 查询流程】
   *   1. 创建 RdbPredicates：指定要查的表
   *   2. 调用 query()：执行查询，返回 ResultSet
   *   3. 遍历 ResultSet：逐行读取数据
   *   4. 关闭 ResultSet：释放数据库连接资源
   *
   * @returns {Promise<CartItem[]>} 购物车商品列表，无数据或出错时返回空数组
   */
  public async getAllItems(): Promise<CartItem[]> {
    try {
      if (!this.checkInit()) {
        return [];  // 未初始化时返回空数组
      }

      // 构建 RdbPredicates：指定查询表名为 cart_items，不加查询条件 = 查询全部
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);

      // query(predicates, columns)：
      // 第一个参数是查询条件，第二个参数是要返回的列名数组
      const resultSet = await this.rdbStore!.query(predicates, [
        'id', 'name', 'price', 'quantity', 'image', 'desc'
      ]);

      // 遍历结果集：goToNextRow() 移动到下一行，返回 false 时表示遍历完毕
      const items: CartItem[] = [];
      while (resultSet.goToNextRow()) {
        // 从当前行读取各字段的值，组装成 ValuesBucket
        const row: relationalStore.ValuesBucket = {
          'id': resultSet.getString(resultSet.getColumnIndex('id')),              // 读取 id 字段
          'name': resultSet.getString(resultSet.getColumnIndex('name')),          // 读取 name 字段
          'price': resultSet.getDouble(resultSet.getColumnIndex('price')),        // 读取 price 字段（REAL 类型用 getDouble）
          'quantity': resultSet.getLong(resultSet.getColumnIndex('quantity')),    // 读取 quantity 字段（INTEGER 用 getLong）
          'image': resultSet.getString(resultSet.getColumnIndex('image')),        // 读取 image 字段
          'desc': resultSet.getString(resultSet.getColumnIndex('desc'))           // 读取 desc 字段
        };
        // 将 ValuesBucket 转为 CartItem 并加入结果数组
        items.push(this.rowToItem(row));
      }

      // 关闭 ResultSet：释放数据库连接资源（必须调用，否则可能造成资源泄漏）
      resultSet.close();

      console.info(TAG + ': 从 RDB 获取购物车数据成功，共 ' + items.length + ' 件商品');
      return items;
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': 从 RDB 获取购物车数据失败, code=' + error.code + ', msg=' + error.message);
      return [];  // 出错时返回空数组
    }
  }

  /**
   * 添加商品到购物车（插入或更新）
   *
   * 如果商品 ID 已存在，则增加其数量；
   * 如果商品 ID 不存在，则插入新行。
   *
   * @param item - 要添加的购物车商品
   */
  public async addItem(item: CartItem): Promise<void> {
    try {
      if (!this.checkInit()) {
        return;  // 未初始化：静默返回
      }

      // 先查找是否已存在该商品（根据 id 精确匹配）
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
      predicates.equalTo('id', item.id);  // equalTo：添加相等条件，相当于 WHERE id = ?

      const resultSet = await this.rdbStore!.query(predicates, ['id', 'quantity']);

      if (resultSet.goToFirstRow()) {
        // 商品已存在：更新数量（原有数量 + 新增数量）
        const existingQuantity = resultSet.getLong(resultSet.getColumnIndex('quantity'));
        resultSet.close();  // 关闭结果集

        const newQuantity: number = existingQuantity + item.quantity;
        const updatePredicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
        updatePredicates.equalTo('id', item.id);

        const updateValues: relationalStore.ValuesBucket = {
          'quantity': newQuantity  // 只更新 quantity 字段
        };

        // update(values, predicates)：更新符合条件的行
        await this.rdbStore!.update(updateValues, updatePredicates);
        console.info(TAG + ': 商品 ' + item.name + ' 已存在 RDB，数量增加至 ' + newQuantity);
      } else {
        // 商品不存在：插入新行
        resultSet.close();

        const values = this.itemToValues(item);  // 将 CartItem 转为 ValuesBucket
        await this.rdbStore!.insert(RDB_TABLE_NAME, values);  // insert：插入一行数据
        console.info(TAG + ': 新增商品 ' + item.name + ' 到 RDB');
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': RDB 添加商品失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 更新购物车中指定商品的数量
   * 如果 newQuantity <= 0，则从购物车中删除该商品
   *
   * @param itemId      - 商品唯一标识
   * @param newQuantity - 新的数量
   */
  public async updateQuantity(itemId: string, newQuantity: number): Promise<void> {
    try {
      if (!this.checkInit()) {
        return;
      }

      if (newQuantity <= 0) {
        // 数量 <= 0：删除该商品
        await this.removeItem(itemId);
        return;
      }

      // 构建更新条件：WHERE id = ?
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
      predicates.equalTo('id', itemId);

      const updateValues: relationalStore.ValuesBucket = {
        'quantity': newQuantity  // 仅更新 quantity 字段
      };

      // update() 返回受影响的行数（rows）
      const rows = await this.rdbStore!.update(updateValues, predicates);
      if (rows > 0) {
        console.info(TAG + ': RDB 更新商品 ' + itemId + ' 数量为 ' + newQuantity);
      } else {
        console.warn(TAG + ': RDB 未找到商品 id=' + itemId);
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': RDB 更新数量失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 从购物车中移除指定商品
   *
   * @param itemId - 要移除的商品唯一标识
   */
  public async removeItem(itemId: string): Promise<void> {
    try {
      if (!this.checkInit()) {
        return;
      }

      // 构建删除条件：WHERE id = ?
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
      predicates.equalTo('id', itemId);

      // delete() 返回受影响的行数
      const rows = await this.rdbStore!.delete(predicates);
      if (rows > 0) {
        console.info(TAG + ': 从 RDB 移除商品 ' + itemId + ' 成功');
      } else {
        console.warn(TAG + ': RDB 未找到要移除的商品 id=' + itemId);
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': RDB 移除商品失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 清空购物车（删除 cart_items 表中所有数据）
   * 使用 DELETE FROM 语句清除全部行数据，但保留表结构
   */
  public async clearCart(): Promise<void> {
    try {
      // 先检查初始化状态，未初始化则直接返回
      if (!this.checkInit()) {
        return;
      }

      // 执行 DELETE FROM 清空表数据（不删除表结构）
      await this.rdbStore!.executeSql('DELETE FROM ' + RDB_TABLE_NAME);
      console.info(TAG + ': RDB 购物车已清空');
    } catch (err) {
      let error = err as BusinessError;
      console.error(TAG + ': RDB 清空购物车失败, code=' + error.code + ', msg=' + error.message);
    }
  }

  /**
   * 计算购物车中所有商品的总价
   * 遍历所有行，累加 (price × quantity) 得到总价
   *
   * @returns {Promise<number>} 总价（保留两位小数）
   */
  public async getTotalPrice(): Promise<number> {
    try {
      if (!this.checkInit()) {
        return 0;  // 未初始化时返回 0
      }

      // 只查询 price 和 quantity 两个字段（减少数据传输量）
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
      const resultSet = await this.rdbStore!.query(predicates, ['price', 'quantity']);

      let total: number = 0;
      while (resultSet.goToNextRow()) {
        const price = resultSet.getDouble(resultSet.getColumnIndex('price'));          // 读取价格
        const quantity = resultSet.getLong(resultSet.getColumnIndex('quantity'));      // 读取数量
        total += price * quantity;  // 累加每个商品的小计
      }
      resultSet.close();  // 释放资源

      return Math.round(total * 100) / 100;  // 保留两位小数
    } catch (err) {
      console.error(TAG + ': RDB 计算总价失败');
      return 0;
    }
  }

  /**
   * 获取购物车中商品的总数量
   * 遍历所有行，累加 quantity 字段
   *
   * @returns {Promise<number>} 总数量
   */
  public async getTotalQuantity(): Promise<number> {
    try {
      if (!this.checkInit()) {
        return 0;
      }

      // 只查询 quantity 字段
      const predicates = new relationalStore.RdbPredicates(RDB_TABLE_NAME);
      const resultSet = await this.rdbStore!.query(predicates, ['quantity']);

      let total: number = 0;
      while (resultSet.goToNextRow()) {
        total += resultSet.getLong(resultSet.getColumnIndex('quantity'));  // 累加数量
      }
      resultSet.close();

      return total;
    } catch (err) {
      console.error(TAG + ': RDB 计算总数量失败');
      return 0;
    }
  }
}
