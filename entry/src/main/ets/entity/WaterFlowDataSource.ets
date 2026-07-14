/**
 * =============================================================================
 *  WaterFlowDataSource - 瀑布流数据源（星球展示，示例/预留代码）
 * =============================================================================
 * 【作用】
 *   为 WaterFlow 瀑布流组件提供"星球"主题的展示数据，实现 IDataSource 接口。
 *   属于示例/预留代码，当前未在任何页面中实际使用。
 *   可作为参考模板，如需新增瀑布流页面，从此结构复制修改即可。
 *
 * 【ItemOption 接口】
 *   定义在 entity/ItemOption.ets 中，包含三个字段：
 *     name: string;       // 必填：选项名称
 *     icon?: Resource;    // 可选：图标资源引用
 *     desc?: string;      // 可选：描述信息
 *   ? 表示可选字段，创建对象时可以省略。
 * =============================================================================
 */

import { ItemOption } from './ItemOption';
// ItemOption: 通用列表项接口，定义 name/icon?/desc? 三个字段的结构

/**
 * 瀑布流（星球展示）数据源类
 * 为 WaterFlow 提供 6 颗行星的展示数据（名称、图标、描述）
 * implements IDataSource：实现懒加载必须的接口
 */
export class WaterFlowDataSource implements IDataSource {
  /**
   * 星球数据数组，存储太阳系 6 颗行星的 ItemOption 对象
   * 每个对象包含 name（名称）、icon（图标 Resource）、desc（详细描述）
   * 图片资源位于 resources/base/media/ 目录下，命名规则为行星拼音
   */
  private planetArray: ItemOption[] = [
    {
      name: '水星',                                                     // 行星名称：水星
      icon: $r("app.media.shuixing"),                                   // 图标：水星图片资源
      desc: '水星是太阳系八大行星最内侧也是最小的一颗行星，也是离太阳最近的行星'  // 详细描述
    },
    {
      name: '金星',
      icon: $r("app.media.jinxing"),
      desc: '金星是太阳系八大行星之一，排行第二，距离太阳0.725天文单位'
    },
    {
      name: '地球',
      icon: $r("app.media.diqiu"),
      desc: '地球是太阳系八大行星之一，排行第三，也是太阳系中直径、质量和密度最大的类地行星，距离太阳1.5亿公里'
    },
    {
      name: '火星',
      icon: $r("app.media.huoxing"),
      desc: '火星是太阳系八大行星之一，排行第四，属于类地行星，直径约为地球的53%'
    },
    {
      name: '木星',
      icon: $r("app.media.muxing"),
      desc: '木星是太阳系八大行星中体积最大、自转最快的行星，排行第五。它的质量为太阳的千分之一，但为太阳系中其它七大行星质量总和的2.5倍'
    },
    {
      name: '土星',
      icon: $r("app.media.tuxing"),
      desc: '土星为太阳系八大行星之一，排行第六，体积仅次于木星'
    }
  ];

  /**
   * 构造函数
   * planetArray 已在声明时完成数据初始化，无需额外逻辑
   */
  constructor() {
    // 空实现：数据已在声明时初始化
  }

  /**
   * 获取数据源中的星球总条目数
   *
   * @returns {number} 星球数量，固定为 6
   */
  totalCount(): number {
    return this.planetArray.length;  // 返回 6
  }

  /**
   * 根据索引获取对应的星球数据
   *
   * @param index - 要获取的数据索引，从 0 开始
   * @returns {ItemOption} 指定索引的星球信息（包含 name/icon/desc 三个字段）
   */
  getData(index: number): ItemOption {
    return this.planetArray[index];  // 返回指定索引的 ItemOption 对象
  }

  /**
   * 注册数据变化监听器（留空：数据为静态，不会变化）
   *
   * @param listener - DataChangeListener 实例，由 LazyForEach 自动传入
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    // 静态数据，无需监听
  }

  /**
   * 注销数据变化监听器（留空：数据为静态，无需清理）
   */
  unregisterDataChangeListener() {
    // 静态数据，无需注销
  }
}
