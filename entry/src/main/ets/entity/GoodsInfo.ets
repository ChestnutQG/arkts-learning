/**
 * =============================================================================
 *  GoodsInfo - 商品信息实体类（含 5 组预设数据集的静态工厂方法）
 * =============================================================================
 * 【作用】
 *   封装商品的核心属性（pic/name/desc/price），并提供 5 个静态工厂方法
 *   （getDefaultGrid / getDefaultClot / getDefaultCombine / getDefaultAppi / getDefaultPhone），
 *   用于生成不同区域/分类的预设商品数据集合。
 *
 * 【设计模式 - 静态工厂方法】
 *   直接通过类名调用（GoodsInfo.getDefaultGrid()），无需创建 GoodsInfo 实例。
 *   调用者不需要知道内部数据细节，只需调用方法名即可获得完整数据集。
 *
 * 【商品分组】
 *   1. grid   - 首页常规 5 列网格（10 个普通商品，pic_01~pic_10）
 *   2. stag   - 服装瀑布流（23 件服装，skirt01~skirt23）
 *   3. combine- 首页合并网格（6 个不规则布局商品，cainixihuan 等）
 *   4. appi   - 电器瀑布流（15 件电器，dian01~dian15）
 *   5. phone  - 首页手机 3 列网格（6 款手机，含详细 desc 和 price）
 * =============================================================================
 */

/**
 * 商品信息实体类
 * 所有属性均为 public，便于组件中直接读取（如 Image($r(item.pic))、Text(item.name)）
 */
export class GoodsInfo {
  /**
   * 商品图片资源路径字符串
   * 如 'app.media.pic_01' 指向 resources/base/media/ 下的图片文件
   * 注意：这里是字符串，UI 中需通过 getImageResource() 映射函数转为 Resource 对象
   * （$r() 是编译期函数，不能直接传运行时字符串）
   */
  public pic: string;

  /** 商品名称，如 "商场"、"iPhone11"、"促销价" 等，直接用于 UI 标签显示 */
  public name: string;

  /** 商品描述信息，手机类商品有详细型号参数（如 "Apple iPhone11 256GB 绿色"），普通商品为空串 */
  public desc: string;

  /** 商品价格（元），手机类商品有真实价格（4999.00），普通商品默认 0 */
  public price: number;

  /**
   * 创建一个商品信息对象
   *
   * @param pic   - 图片资源路径字符串，如 'app.media.pic_01'
   * @param name  - 商品名称，如 'iPhone11'
   * @param desc  - 商品描述信息，默认可传空字符串
   * @param price - 商品价格（元），默认可传 0
   */
  public constructor(pic: string, name: string, desc: string, price: number = 0) {
    this.pic = pic;         // 保存图片资源路径，UI 中通过映射函数转为 Resource
    this.name = name;       // 保存商品名称，直接用于 Text 组件
    this.desc = desc;       // 保存商品描述，手机类商品含完整型号配置
    this.price = price;     // 保存商品价格，用于价格标签和购物车计算
  }

  // ══════════════════════════════════════════════════════════════════
  //  以下 5 组为：各区域预设商品数据 + 对应的静态工厂方法
  // ══════════════════════════════════════════════════════════════════

  // ──────────────────────────────────────────────────────────────
  //  区域一：首页常规网格（5 列，10 个普通商品）
  //  展示位置：轮播图下方，5列等宽网格，图片命名 pic_01 ~ pic_10
  // ──────────────────────────────────────────────────────────────

  /** 网格商品图片资源路径数组（10 张），命名 pic_01 ~ pic_10 */
  private static gridImageArray: string[] = [
    'app.media.pic_01', 'app.media.pic_02', 'app.media.pic_03',
    'app.media.pic_04', 'app.media.pic_05', 'app.media.pic_06',
    'app.media.pic_07', 'app.media.pic_08', 'app.media.pic_09',
    'app.media.pic_10'
  ];

  /** 网格商品名称数组（10 个，与 gridImageArray 按索引一一对应） */
  private static gridNameArray: string[] = [
    '商场', '超市', '百货', '便利店',
    '地摊', '食杂店', '饭店', '餐厅', '会所', '菜市场'
  ];

  /**
   * 获取首页默认网格的 10 个商品数据
   * 遍历 gridImageArray 与 gridNameArray，按相同索引组装成 GoodsInfo
   *
   * @returns {Array<GoodsInfo>} 10 个网格商品，每个包含 pic 和 name，desc 为空
   */
  public static getDefaultGrid(): Array<GoodsInfo> {
    let gridArray = new Array<GoodsInfo>();   // 创建空数组，准备装 10 个商品
    for (let i = 0; i < GoodsInfo.gridImageArray.length; i++) {
      // 按索引组装：第 i 张图片配第 i 个名称，desc 传空字符串
      gridArray.push(
        new GoodsInfo(GoodsInfo.gridImageArray[i], GoodsInfo.gridNameArray[i], '')
      );
    }
    return gridArray;   // 返回完整的 10 个商品数组
  }

  // ──────────────────────────────────────────────────────────────
  //  区域二：服装瀑布流（23 件服装）
  //  展示位置：分类页 → 服装 Tab → WaterFlow，图片命名 skirt01 ~ skirt23
  // ──────────────────────────────────────────────────────────────

  /** 服装商品图片资源路径数组（23 张），命名 skirt01 ~ skirt23 */
  private static stagImageArray: string[] = [
    'app.media.skirt01', 'app.media.skirt02', 'app.media.skirt03',
    'app.media.skirt04', 'app.media.skirt05', 'app.media.skirt06',
    'app.media.skirt07', 'app.media.skirt08', 'app.media.skirt09',
    'app.media.skirt10', 'app.media.skirt11', 'app.media.skirt12',
    'app.media.skirt13', 'app.media.skirt14', 'app.media.skirt15',
    'app.media.skirt16', 'app.media.skirt17', 'app.media.skirt18',
    'app.media.skirt19', 'app.media.skirt20', 'app.media.skirt21',
    'app.media.skirt22', 'app.media.skirt23'
  ];

  /** 服装商品名称数组（23 个趣味促销名称，与 stagImageArray 按索引一一对应） */
  private static stagNameArray: string[] = [
    '促销价', '惊爆价', '跳楼价', '白菜价', '清仓价', '割肉价',
    '实惠价', '一口价', '满意价', '打折价', '腰斩价', '真实惠',
    '算了吧', '大声点', '嘘嘘', '嗯嗯', '呼呼', '呵呵', '哈哈',
    '嘿嘿', '嘻嘻', '嗷嗷', '喔喔'
  ];

  /**
   * 获取 23 件服装商品数据
   * 遍历 stagImageArray 与 stagNameArray，组装成 GoodsInfo 数组
   *
   * @returns {Array<GoodsInfo>} 23 个服装商品信息
   */
  public static getDefaultClot(): Array<GoodsInfo> {
    let stagArray = new Array<GoodsInfo>();   // 创建空数组
    for (let i = 0; i < GoodsInfo.stagImageArray.length; i++) {
      // 逐个创建服装商品，desc 传空字符串（服装类没有详细描述）
      stagArray.push(
        new GoodsInfo(GoodsInfo.stagImageArray[i], GoodsInfo.stagNameArray[i], '')
      );
    }
    return stagArray;   // 返回完整的 23 个服装商品数组
  }

  // ──────────────────────────────────────────────────────────────
  //  区域三：首页合并网格（不规则跨列布局，6 个推荐商品）
  //  展示位置：首页常规网格下方，前 2 项（索引 0,1）各占一行两列
  // ──────────────────────────────────────────────────────────────

  /** 合并网格图片资源路径数组（6 张） */
  private static combineImageArray: string[] = [
    'app.media.cainixihuan', 'app.media.dapaijiadao',
    'app.media.trip_01', 'app.media.trip_02',
    'app.media.trip_03', 'app.media.trip_04'
  ];

  /** 合并网格商品名称数组（6 个推荐商品名称） */
  private static combineNameArray: string[] = [
    '猜你喜欢', '大牌驾到', '买哪个', '别想了', '先下单', '包你满意'
  ];

  /**
   * 获取 6 个合并网格商品数据
   * 遍历 combineImageArray 与 combineNameArray 组装
   *
   * @returns {Array<GoodsInfo>} 6 个合并网格商品信息
   */
  public static getDefaultCombine(): Array<GoodsInfo> {
    let combineArray = new Array<GoodsInfo>();   // 创建空数组
    for (let i = 0; i < GoodsInfo.combineImageArray.length; i++) {
      // 逐个创建合并网格商品，desc 传空字符串
      combineArray.push(
        new GoodsInfo(GoodsInfo.combineImageArray[i], GoodsInfo.combineNameArray[i], '')
      );
    }
    return combineArray;   // 返回完整的 6 个商品数组
  }

  // ──────────────────────────────────────────────────────────────
  //  区域四：电器瀑布流（15 件电器）
  //  展示位置：分类页 → 电器 Tab → WaterFlow，图片命名 dian01 ~ dian15
  // ──────────────────────────────────────────────────────────────

  /** 电器商品图片资源路径数组（15 张），命名 dian01 ~ dian15 */
  private static appiImageArray: string[] = [
    'app.media.dian01', 'app.media.dian02', 'app.media.dian03',
    'app.media.dian04', 'app.media.dian05', 'app.media.dian06',
    'app.media.dian07', 'app.media.dian08', 'app.media.dian09',
    'app.media.dian10', 'app.media.dian11', 'app.media.dian12',
    'app.media.dian13', 'app.media.dian14', 'app.media.dian15'
  ];

  /** 电器商品名称数组（15 个趣味名称，与 appiImageArray 按索引一一对应） */
  private static appiNameArray: string[] = [
    '双十一', '大聚惠', '爆款价', '就一次', '手慢无',
    '快点击', '付定金', '享特权', '包安装', '再返券',
    '白送你', '想得美', '干活去', '好好学', '才有钱'
  ];

  /**
   * 获取 15 件电器商品数据
   * 遍历 appiImageArray 与 appiNameArray 组装
   *
   * @returns {Array<GoodsInfo>} 15 个电器商品信息
   */
  public static getDefaultAppi(): Array<GoodsInfo> {
    let appiArray = new Array<GoodsInfo>();    // 创建空数组
    for (let i = 0; i < GoodsInfo.appiImageArray.length; i++) {
      // 逐个创建电器商品，desc 传空字符串
      appiArray.push(
        new GoodsInfo(GoodsInfo.appiImageArray[i], GoodsInfo.appiNameArray[i], '')
      );
    }
    return appiArray;    // 返回完整的 15 个电器商品数组
  }

  // ──────────────────────────────────────────────────────────────
  //  区域五：首页手机网格（3 列，6 款品牌手机）
  //  展示位置：首页最下方的 3 列手机专区，含完整型号描述和真实价格
  // ──────────────────────────────────────────────────────────────

  /** 手机商品图片资源路径数组（6 张品牌手机图片） */
  private static phonePicArray = [
    'app.media.iphone', 'app.media.huawei', 'app.media.xiaomi',
    'app.media.oppo', 'app.media.vivo', 'app.media.rongyao'
  ];

  /** 手机商品名称数组（6 款手机型号名称） */
  private static phoneNameArray = [
    'iPhone11', 'Mate30', '小米10',
    'OPPO Reno3', 'vivo X30', '荣耀30S'
  ];

  /** 手机商品描述数组（6 条详细配置描述，与 phoneNameArray 按索引一一对应） */
  private static phoneDescArray = [
    'Apple iPhone11 256GB 绿色 4G全网通手机',
    '华为 HUAWEI Mate30 8GB+256GB 丹霞橙 5G全网通 全面屏手机',
    '小米 MI10 8GB+128GB 钛银黑 5G手机 游戏拍照手机',
    'OPPO Reno3 8GB+128GB 蓝色星夜 双模5G 拍照游戏智能手机',
    'vivo X30 8GB+128GB 绯云 5G全网通 美颜拍照手机',
    '荣耀30S 8GB+128GB 蝶羽红 5G芯片 自拍全面屏手机'
  ];

  /** 手机商品价格数组（6 款真实价格，与 phoneNameArray 按索引一一对应） */
  private static phonePriceArray: number[] = [
    4999.00,  // Apple iPhone11
    3999.00,  // HUAWEI Mate30
    3499.00,  // 小米10
    2999.00,  // OPPO Reno3
    3299.00,  // vivo X30
    2699.00   // 荣耀30S
  ];

  /**
   * 获取 6 款手机商品数据（含详细描述 desc 和真实价格 price）
   * 与其它工厂方法不同，此方法同时遍历 pic/name/desc/price 四个数组，
   * 因为手机商品需要展示完整的型号配置和价格信息。
   *
   * @returns {GoodsInfo[]} 6 款手机商品信息（含完整 desc 和 price）
   */
  public static getDefaultPhone(): GoodsInfo[] {
    let goodsArray: GoodsInfo[] = [];   // 创建空数组
    for (let i = 0; i < GoodsInfo.phoneNameArray.length; i++) {
      // 逐个创建手机商品，携带完整的 4 个属性
      goodsArray.push(
        new GoodsInfo(
          GoodsInfo.phonePicArray[i],      // 手机图片路径，如 'app.media.iphone'
          GoodsInfo.phoneNameArray[i],     // 手机型号名称，如 'iPhone11'
          GoodsInfo.phoneDescArray[i],     // 手机详细描述，如 'Apple iPhone11 256GB 绿色'
          GoodsInfo.phonePriceArray[i]     // 手机价格，如 4999.00
        )
      );
    }
    return goodsArray;   // 返回完整的 6 款手机商品数组
  }
}
