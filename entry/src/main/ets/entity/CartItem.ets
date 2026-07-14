/**
 * =============================================================================
 *  CartItem - 购物车商品项实体模型
 * =============================================================================
 * 【作用】
 *   定义购物车中每个商品项的数据结构，包含 id/name/price/quantity/image/desc 六个字段。
 *   提供 toJsonString() 序列化和 getSubtotal() 小计计算两个实用方法。
 *
 * 【数据流转】
 *   ShopStorePage.addToCart()                            ← 创建 CartItem 实例
 *      → CartPreferencesUtil.saveItems()                  ← 序列化为 JSON → Preferences 持久化
 *      → CartRdbUtil.itemToValues()                       ← 转为 ValuesBucket → RDB 存储
 *      → DepartmentCartView.cartItems[]                   ← 反序列化后 UI 展示
 * =============================================================================
 */

/**
 * 购物车商品项数据模型
 * 所有属性均为 public，便于 JSON.stringify 序列化（仅序列化公共属性）
 */
export class CartItem {
  /** 商品唯一标识，由时间戳+随机数生成，确保不重复（如 'store_iPhone11_1712345678000'） */
  public id: string;

  /** 商品名称，如 'iPhone11'、'Mate30'，直接用于 UI 展示 */
  public name: string;

  /** 商品单价（单位：元），保留两位小数精度，如 4999.00 */
  public price: number;

  /** 购买数量，加入购物车时默认为 1，用户可后续增减 */
  public quantity: number;

  /** 商品图片资源路径字符串（如 'app.media.iphone'），用于 $r() 编译期映射 */
  public image: string;

  /** 商品描述信息，手机类有详细型号描述，普通商品可为空字符串 */
  public desc: string;

  /**
   * 构造函数：创建一个购物车商品项
   * 所有参数按顺序传入，quantity/image/desc 有默认值，可省略部分参数
   *
   * @param id       - 商品唯一标识，必须唯一
   * @param name     - 商品名称，UI 中直接显示
   * @param price    - 商品单价（元），用于计算小计
   * @param quantity - 购买数量，默认 1
   * @param image    - 图片资源路径字符串，默认空字符串
   * @param desc     - 商品描述信息，默认空字符串
   */
  constructor(id: string, name: string, price: number, quantity: number = 1, image: string = '', desc: string = '') {
    this.id = id;           // 保存唯一标识
    this.name = name;       // 保存商品名称
    this.price = price;     // 保存商品价格
    this.quantity = quantity; // 保存购买数量
    this.image = image;     // 保存图片路径
    this.desc = desc;       // 保存商品描述
  }

  /**
   * 将当前 CartItem 序列化为 JSON 字符串
   * 用于 Preferences 持久化存储（以 JSON 格式存入 key-value 存储中）
   * JSON.stringify 会自动提取所有 public 属性的值
   *
   * @returns {string} 如 '{"id":"store_iPhone11_...","name":"iPhone11","price":4999,"quantity":1,"image":"app.media.iphone","desc":"Apple iPhone11..."}'
   */
  public toJsonString(): string {
    return JSON.stringify(this);
  }

  /**
   * 计算该商品项的小计金额
   * 公式：小计 = 单价 × 数量
   * Math.round(... * 100) / 100 确保保留两位小数，避免浮点精度误差
   *
   * @returns {number} 如 4999.00（单价 4999 × 数量 1）
   */
  public getSubtotal(): number {
    return Math.round(this.price * this.quantity * 100) / 100;
  }
}
