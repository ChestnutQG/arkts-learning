/**
 * =============================================================================
 *  ImageCacheManager - 图片缓存管理器（单例模式）
 * =============================================================================
 * 【作用】
 *   管理商品图片资源的加载与内存缓存，提供从资源目录读取图片并缓存为 PixelMap 的能力。
 *   主要使用 resourceManager.getRawFileContent() API 从 resources/rawfile 目录读取图片。
 *
 * 【缓存策略 - FIFO（先进先出）】
 *   1. 内存缓存：使用 Map<string, PixelMap> 存储已加载的图片
 *   2. 容量限制：最多缓存 30 张图片，超过时淘汰最早加载的（FIFO）
 *   3. 并发保护：同一图片的多次请求不会重复加载（使用 pendingLoads Map 跟踪）
 *   4. 内存释放：淘汰和清空时调用 PixelMap.release() 释放 Native 内存
 *
 * 【重要限制】
 *   $r() 是编译期函数，不能接受运行时字符串！本类不提供 Resource 转换功能。
 *   如需在组件中显示图片，请使用 getOrLoadImage() 获取 PixelMap，
 *   或直接在组件中使用 Image($r('app.media.xxx')) 编译期引用。
 *
 * 【使用方式】
 *   1. 获取单例：const cache = ImageCacheManager.getInstance()
 *   2. 设置上下文：cache.setContext(getContext(this))
 *   3. 加载图片：const pixelMap = await cache.getOrLoadImage('app.media.iphone')
 *   4. 检查缓存：cache.hasCache('app.media.iphone')
 *   5. 清空缓存：cache.clearCache()
 * =============================================================================
 */

import { image } from '@kit.ImageKit';
// image: 图片处理模块，提供 ImageSource（图片源）和 PixelMap（像素图）相关 API

import { BusinessError } from '@kit.BasicServicesKit';
// BusinessError: 业务错误类型，用于统一的错误捕获和处理

/** 最大缓存图片数量（超过时按 FIFO 策略淘汰最旧的） */
const MAX_CACHE_SIZE: number = 30;

/**
 * 图片缓存管理器（单例模式）
 * 管理图片的异步加载和内存缓存，确保同一图片不会重复加载
 */
export class ImageCacheManager {
  /** 单例实例（static 类级别变量） */
  private static instance: ImageCacheManager;

  /** 内存缓存：键为资源名称（如 'app.media.iphone'），值为解码后的 PixelMap */
  private cache: Map<string, image.PixelMap> = new Map();

  /** 应用上下文，用于获取 resourceManager 读取资源文件 */
  private context: Context | null = null;

  /** 当前正在加载的图片任务 Map：防止同一图片的并发重复加载 */
  private pendingLoads: Map<string, Promise<image.PixelMap | null>> = new Map();

  /**
   * 私有构造函数（单例模式不允许外部 new 实例化）
   * 必须通过 ImageCacheManager.getInstance() 获取实例
   */
  private constructor() {}

  /**
   * 获取 ImageCacheManager 单例实例
   * 第一次调用时创建，后续复用已创建的实例
   *
   * @returns {ImageCacheManager} 图片缓存管理器实例
   */
  public static getInstance(): ImageCacheManager {
    if (!ImageCacheManager.instance) {
      ImageCacheManager.instance = new ImageCacheManager();
    }
    return ImageCacheManager.instance;
  }

  /**
   * 设置应用上下文
   * 必须在调用 getOrLoadImage() 之前调用此方法，否则无法访问资源文件
   *
   * @param context - 组件或 Ability 的上下文，通过 getContext(this) 获取
   */
  public setContext(context: Context): void {
    this.context = context;
  }

  /**
   * 从缓存获取或加载图片（核心入口方法）
   *
   * 执行逻辑：
   *   1. 检查内存缓存：已有则直接返回
   *   2. 检查是否正在加载中：是则复用已有 Promise（防止并发重复加载）
   *   3. 都不满足：创建新的加载任务并执行
   *
   * @param resName - 图片资源名称（如 'app.media.iphone' 或 'iphone'）
   * @returns {Promise<image.PixelMap | null>} 解码后的 PixelMap，加载失败返回 null
   */
  public async getOrLoadImage(resName: string): Promise<image.PixelMap | null> {
    // 第一步：检查内存缓存中是否已存在
    if (this.cache.has(resName)) {
      // 缓存命中：直接返回缓存的 PixelMap（非空断言 ! 因为 has 已确认存在）
      return this.cache.get(resName)!;
    }

    // 第二步：检查是否正在加载中（防止并发场景下重复加载同一张图片）
    const pending = this.pendingLoads.get(resName);
    if (pending) {
      // 正在加载：复用已有的 Promise，等待加载完成后返回结果
      return pending;
    }

    // 第三步：检查上下文是否已设置
    if (!this.context) {
      console.error('ImageCache: context 未设置，请先调用 setContext()');
      return null;
    }

    // 第四步：创建新的加载任务，并记录到 pendingLoads 中
    const loadPromise = this.loadAndCacheImage(resName);
    this.pendingLoads.set(resName, loadPromise);

    try {
      // await 等待加载完成
      const pixelMap = await loadPromise;
      return pixelMap;
    } finally {
      // 无论成功还是失败，从 pendingLoads 中移除（允许下次重新加载）
      this.pendingLoads.delete(resName);
    }
  }

  /**
   * 启动图片加载任务并存入缓存（内部方法）
   *
   * 加载流程：
   *   1. 从资源名称中提取纯文件名（去掉 'app.media.' 前缀）
   *   2. 通过 resourceManager.getRawFileContent() 读取原始字节数据
   *   3. 通过 image.createImageSource() 创建图片源
   *   4. 通过 imageSource.createPixelMap() 解码为可渲染的 PixelMap
   *   5. 检查缓存容量，超出时淘汰最旧的
   *   6. 存入内存缓存并返回
   *
   * @param resName - 完整资源名称（如 'app.media.iphone'）
   * @returns {Promise<image.PixelMap | null>} 解码后的 PixelMap，失败返回 null
   */
  private async loadAndCacheImage(resName: string): Promise<image.PixelMap | null> {
    try {
      // 获取 resourceManager（资源管理器），用于读取资源文件
      const resourceMgr = this.context!.resourceManager;

      // 提取纯文件名：去掉 'app.media.' 前缀（10 个字符）
      // 如 'app.media.iphone' → 'iphone'
      const mediaName: string = resName.startsWith('app.media.') ? resName.substring(10) : resName;

      // 从资源读取原始图片数据
      // 使用 getRawFileContent() 读取 rawfile 目录下的文件
      // rawfile 目录中 media 文件夹下的文件路径为 media/xxx.jpg
      let data: Uint8Array | null = null;

      try {
        // 方式一：尝试从 rawfile 的 media 子目录读取（如 media/iphone.jpg）
        data = await resourceMgr.getRawFileContent('media/' + mediaName);
      } catch (rawErr) {
        // 方式一失败：尝试不带前缀的路径（如 iphone.jpg）
        try {
          data = await resourceMgr.getRawFileContent(mediaName);
        } catch (nameErr) {
          // 两种方式都失败：记录错误并返回 null
          console.error('ImageCache: 无法读取文件: ' + mediaName);
          return null;
        }
      }

      // 确认数据不为 null 后再继续（TypeScript 类型收窄）
      if (data === null) {
        return null;
      }

      // 创建图片源：从原始字节数据创建 ImageSource 对象
      const imageSource: image.ImageSource = image.createImageSource(data);

      // 解码为 PixelMap：将图片源解码为可渲染的像素图
      const pixelMap: image.PixelMap = await imageSource.createPixelMap();

      // 检查缓存大小，如果超过最大容量则淘汰最旧的
      this.evictIfNeeded();

      // 存入内存缓存
      this.cache.set(resName, pixelMap);
      console.info('ImageCache: 图片已缓存 ' + resName);
      return pixelMap;
    } catch (err) {
      let error = err as BusinessError;
      console.error('ImageCache: 加载图片失败 ' + resName + ', code=' + error.code + ', msg=' + error.message);
      return null;
    }
  }

  /**
   * 检查是否需要淘汰旧缓存（FIFO 先进先出策略）
   * 当缓存数量 >= MAX_CACHE_SIZE(30) 时，删除最早加载的图片
   * 并调用 PixelMap.release() 释放 Native 层内存
   */
  private evictIfNeeded(): void {
    // while 循环持续淘汰，直到缓存数量小于最大容量
    while (this.cache.size >= MAX_CACHE_SIZE) {
      // 获取 Map 中所有键（按插入顺序排列，第一个就是最旧的）
      const keys: string[] = Array.from(this.cache.keys());
      if (keys.length > 0) {
        // 获取最旧的键
        const firstKey: string = keys[0];
        // 获取对应的 PixelMap
        const oldPixelMap: image.PixelMap | undefined = this.cache.get(firstKey);
        if (oldPixelMap) {
          // release()：释放 PixelMap 占用的 Native 内存（必须调用！否则可能内存泄漏）
          oldPixelMap.release();
        }
        // 从缓存 Map 中删除此条目
        this.cache.delete(firstKey);
      } else {
        // Map 为空时退出循环（理论上不会发生，但做防御处理）
        break;
      }
    }
  }

  /**
   * 检查缓存中是否已存在指定图片
   *
   * @param resName - 图片资源名称（如 'app.media.iphone'）
   * @returns {boolean} true=已缓存，false=未缓存
   */
  public hasCache(resName: string): boolean {
    return this.cache.has(resName);
  }

  /**
   * 获取当前缓存中的图片数量
   *
   * @returns {number} 缓存图片数量（0 ~ MAX_CACHE_SIZE）
   */
  public getCacheSize(): number {
    return this.cache.size;
  }

  /**
   * 清空所有缓存（遍历所有 PixelMap 并释放 Native 内存）
   * 适用于页面销毁或内存紧张时的主动清理
   */
  public clearCache(): void {
    // 遍历所有缓存的 PixelMap，逐个释放 Native 内存
    this.cache.forEach((pixelMap: image.PixelMap) => {
      try {
        pixelMap.release();  // 释放 PixelMap 的 Native 层内存
      } catch (e) {
        // 个别 PixelMap 释放失败时，忽略错误继续释放其他
      }
    });
    // 清空 Map 容器
    this.cache.clear();
    console.info('ImageCache: 缓存已清空');
  }

  /**
   * 移除指定图片的缓存
   *
   * @param resName - 图片资源名称（如 'app.media.iphone'）
   */
  public removeCache(resName: string): void {
    // 从 Map 中获取指定名称的 PixelMap
    const pixelMap: image.PixelMap | undefined = this.cache.get(resName);
    if (pixelMap) {
      try {
        pixelMap.release();  // 释放 Native 内存
      } catch (e) {
        // 释放失败时忽略
      }
      // 从缓存 Map 中删除
      this.cache.delete(resName);
    }
  }
}
