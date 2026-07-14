/**
 * =============================================================================
 *  LightFlowTabBar - 玻璃流光导航栏组件
 * =============================================================================
 * 【作用】
 *   替代系统原生 Tabs 页签栏的"玻璃流光"风格自定义导航栏组件。
 *   以悬浮形式覆盖在页面底部，提供视觉炫酷的 Tab 切换交互。
 *
 * 【设计风格 - 玻璃流光（Glassmorphism + Light Flow）】
 *   1. 毛玻璃（Glassmorphism）：
 *      - backdropBlur(40)：背景模糊 40px，透视底层内容
 *      - backgroundBlurStyle(BlurStyle.Thin)：系统级毛玻璃风格
 *      - background: rgba(10,10,10,0.15)：高透明度深色底色
 *
 *   2. 磁吸高亮框（Magnetic Highlight）：
 *      - 渐变高光 Column 跟随鼠标/触摸位置移动
 *      - animation({ duration: 600, curve: FastOutSlowIn })：磁吸动画
 *      - 按下时 scale(1.3)：弹性放大效果
 *
 *   3. 流光动画（Flowing Light）：
 *      - animAngle 从 0→360 持续线性旋转
 *      - 结合 conicGradient 实现流光扫光效果
 *
 * 【交互层级】
 *   Stack
 *   ├── 第1层：玻璃主体（毛玻璃 + 半透明背景）
 *   ├── 第2层：磁吸高亮框（渐变 + 磁吸动画）
 *   ├── 第3层：Tab 内容层（图标 + 文字）
 *   └── 第4层：事件捕获层（透明 + Tap/Pan/Mouse 手势统一捕获）
 *
 * 【状态管理】
 *   @Prop tabs:         父组件传入的导航项配置（单向数据流）
 *   @Prop currentIndex: 父组件传入的当前选中索引
 *   @State animAngle:   流光动画角度（0→360 无限循环）
 *   @State hoverIndex:  鼠标/触摸悬停索引（-1=无悬停）
 *   @State pressedIndex:按下索引（-1=未按下）
 *   @State lightingIndex:跨 Tab 划过时临时点亮的索引
 * =============================================================================
 */

import { NavigationItem } from "./NavigationItem";
// NavigationItem: 导航项数据模型（id/text/icon/activeIcon）

import { curves } from '@kit.ArkUI';
// curves: 动画曲线模块，提供各种缓动函数（如 FastOutSlowIn、Sharp、Smooth）

/**
 * 玻璃流光导航栏组件
 * 提供毛玻璃背景 + 磁吸高亮 + 流光动画 + 手势交互
 */
@Component
export struct LightFlowTabBar {
  // ════════════════════════════════════════════
  //  @Prop：父组件传入的属性（单向数据流）
  // ════════════════════════════════════════════

  /**
   * 导航项配置数组，由父组件（Index / DepartmentStorePage）传入
   * @Prop 装饰：从父组件单向传入，本组件不能修改
   * 每个 NavigationItem 包含 id/text/icon/activeIcon 四个字段
   */
  @Prop tabs: NavigationItem[] = [];

  /**
   * 当前选中的 Tab 索引
   * @Prop 装饰：父组件 current 变量的副本，父组件更新时自动刷新
   * 用于高亮框的默认位置和图标切换
   */
  @Prop currentIndex: number = 0;

  // ════════════════════════════════════════════
  //  父组件传入的回调属性
  // ════════════════════════════════════════════

  /**
   * Tab 点击事件回调，由父组件实现
   * 默认空函数 () => {}，防止未赋值时调用报错
   * 父组件在此回调中更新 current 变量，触发 Tabs 切换
   */
  onTabClick: (index: number) => void = () => {};

  // ════════════════════════════════════════════
  //  @State：组件内部状态变量
  // ════════════════════════════════════════════

  /** 流光动画角度，从 0° 到 360° 持续线性旋转（driver for 流光视觉效果） */
  @State private animAngle: number = 0;

  /**
   * 当前悬停/触摸的 Tab 索引
   * -1 表示没有悬停，高亮框回归当前选中位置
   * 鼠标移入 Tab 区域时更新，移出时恢复 -1
   */
  @State private hoverIndex: number = -1;

  /**
   * 组件的实际宽度（布局完成后由 onAreaChange 获取）
   * 用于计算每个 Tab 的宽度和磁吸条的位置
   */
  @State private componentWidth: number = 0;

  /**
   * 标记组件是否已完成初始化
   * 只有当 componentWidth > 0 时才设为 true（布局完成后）
   * 初始化完成前隐藏高亮框，避免布局跳动
   */
  @State private isInitialized: boolean = false;

  /**
   * 按下的 Tab 索引
   * -1 表示未按下，非 -1 时对应的 Tab 项会缩放(0.9)表示被按下
   */
  @State private pressedIndex: number = -1;

  /**
   * 临时被点亮的 Tab 索引
   * 用于跨 Tab 切换时的"流光划过"视觉效果：
   * 从当前 Tab 切换到目标 Tab 时，中间经过的 Tab 会短暂高亮
   */
  @State private lightingIndex: number = -1;

  // ════════════════════════════════════════════
  //  生命周期
  // ════════════════════════════════════════════

  /** 组件即将挂载时触发：启动流光动画（animAngle 0→360 无限循环） */
  aboutToAppear() {
    this.startFlowAnimation();
  }

  // ════════════════════════════════════════════
  //  自定义方法
  // ════════════════════════════════════════════

  /**
   * 启动流光动画
   * 使用 getUIContext().animateTo() 驱动 animAngle 从 0 到 360 循环
   *
   * 参数说明：
   *   duration: 3000     - 动画周期 3000ms（一次完整的 0→360 旋转）
   *   iterations: -1     - -1 表示无限循环
   *   curve: Curve.Linear - 线性匀速，保证流光扫过时速度均匀
   */
  startFlowAnimation() {
    this.getUIContext().animateTo({
      duration: 3000,       // 3000ms 完成一次完整旋转
      iterations: -1,       // 无限循环
      curve: Curve.Linear   // 线性匀速（看起来更自然）
    }, () => {
      this.animAngle = 360; // 目标值：从 0 旋转到 360°
    });
  }

  /**
   * 计算磁吸高亮框的中心 X 坐标
   *
   * 逻辑：
   *   1. 如果有鼠标悬停（hoverIndex !== -1），跟随悬停位置
   *   2. 否则跟随当前选中位置（currentIndex）
   *   3. 计算公式：index * tabWidth + tabWidth / 2
   *
   * @returns {number} 高亮框的中心 X 坐标（相对于组件左上角）
   */
  getHighlightX(): number {
    if (this.componentWidth <= 0 || this.tabs.length <= 0) return 0;

    // 计算每个 Tab 的宽度（等分总宽度）
    let tabWidth = this.componentWidth / this.tabs.length;

    // 决定跟随哪个索引：有悬停时跟随悬停位置，否则跟随当前选中位置
    let targetIndex = this.hoverIndex !== -1 ? this.hoverIndex : this.currentIndex;

    // 计算该 Tab 的中心 X 坐标：起始偏移 + 一半宽度
    return targetIndex * tabWidth + tabWidth / 2;
  }

  // ════════════════════════════════════════════
  //  UI 构建
  // ════════════════════════════════════════════

  /**
   * 构建导航栏 UI
   * 四层 Stack 叠加：玻璃主体 → 高亮框 → Tab 内容 → 事件捕获
   */
  build() {
    Stack() {
      // ════════════════════════════════════════════════
      //  第 1 层：玻璃主体层（视觉基底）
      //  使用 backdropBlur + 半透明背景构成毛玻璃效果
      // ════════════════════════════════════════════════
      Column() {
        Column()
          .width('100%')                                     // 宽度撑满
          .height('100%')                                    // 高度撑满
          .backgroundColor('rgba(10, 10, 10, 0.15)')         // 高透明度深色底色（15% 透明度）
          .backdropBlur(40)                                  // 毛玻璃模糊半径 40px
          .borderRadius(30)                                  // 内部圆角 30
          .backgroundBlurStyle(BlurStyle.Thin)               // 系统级毛玻璃风格（轻量）
      }
      .width('100%')
      .height('100%')
      .borderRadius(30)                                      // 外部圆角 30（整个玻璃底座）
      .clip(true)                                            // 裁剪超出圆角的子元素

      // ════════════════════════════════════════════════
      //  第 2 层：磁吸高亮框
      //  渐变色的圆角 Column，跟随鼠标/选中位置移动
      //  animation(600ms FastOutSlowIn) 实现"磁吸"平滑过渡
      // ════════════════════════════════════════════════
      Column()
        .width(70)                           // 高亮框宽度 70
        .height(60)                          // 高亮框高度 60
        .borderRadius(26)                    // 大圆角胶囊形状

        // 线性渐变：135° 方向（右下→左上对角线），模拟光线反射
        .linearGradient({
          angle: 135,                        // 渐变角度 135°
          colors: [
            ['rgba(255, 255, 255, 0.4)', 0.0],    // 起始(左上)：40% 白色高光
            ['rgba(255, 255, 255, 0.12)', 0.4],   // 中间：12% 白色过渡
            ['rgba(255, 255, 255, 0.02)', 1.0]    // 结束(右下)：2% 几乎透明
          ]
        })

        .backdropBlur(20)                    // 高亮框自身的毛玻璃
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.25)' })  // 细白边框增强质感
        .shadow({ radius: 10, color: 'rgba(255, 255, 255, 0.1)', offsetX: 0, offsetY: 0 })  // 白色外发光阴影

        // position：高亮框定位（X = 中心坐标 - 宽度/2，Y = 距顶部 10px 居中）
        .position({
          x: this.getHighlightX() - 35,  // 中心 X - 半宽(35) = 左上角 X
          y: 10                           // 距顶部 10px，垂直居中：(80-60)/2=10
        })
        .animation({ duration: 600, curve: Curve.FastOutSlowIn })  // 600ms 磁吸动画：先快后慢

        // 按下时的缩放效果：放大 1.3 倍（弹性反馈）
        .scale({
          x: this.pressedIndex !== -1 ? 1.3 : 1,
          y: this.pressedIndex !== -1 ? 1.3 : 1
        })

        .hitTestBehavior(HitTestMode.None)                              // 高亮框不拦截点击事件
        .visibility(this.isInitialized ? Visibility.Visible : Visibility.Hidden)  // 初始化完成才显示

      // ════════════════════════════════════════════════
      //  第 3 层：Tab 内容层（图标 + 文字）
      //  Row 水平排列，ForEach 遍历所有 Tab 项
      // ════════════════════════════════════════════════
      Row() {
        ForEach(this.tabs, (item: NavigationItem, index: number) => {
          // 调用 @Builder TabItem 绘制每个 Tab
          // isActive = (当前选中 | 流光划过点亮)
          this.TabItem(
            item,
            index,
            this.currentIndex === index || this.lightingIndex === index
          )
        }, (item: NavigationItem) =>
          // key 生成函数：id + 当前选中索引 + 点亮索引
          // 当 currentIndex 或 lightingIndex 变化时，ForEach 重新渲染
          item.id + '_' + this.currentIndex + '_' + this.lightingIndex
        )
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceEvenly)  // 所有 Tab 水平均匀分布
      .alignItems(VerticalAlign.Center)       // 垂直居中
      .zIndex(2)                              // 层级 2（高于玻璃层）

      // ════════════════════════════════════════════════
      //  第 4 层：事件捕获层（最顶层，透明，zIndex=3）
      //  统一拦截所有手势（Tap + Pan + Mouse），手动分发
      //
      //  为什么不用子元素的 onClick？
      //  因为需要统一处理：跨 Tab 流光（TapGesture）+ 拖拽跟随（PanGesture）
      //  + 鼠标悬停（onMouse/onHover），统一捕获避免手势冲突
      // ════════════════════════════════════════════════
      Column()
        .width('100%')
        .height('100%')
        .zIndex(3)                              // 最顶层（覆盖所有层）
        .backgroundColor(Color.Transparent)      // 完全透明（只接收事件，不可见）

        // ──── 手势组：并行响应 Tap + Pan ────
        .gesture(
          GestureGroup(GestureMode.Parallel,  // 并行模式：同时监听多种手势

            // ========== 手势 1：TapGesture（点击手势） ==========
            TapGesture({ count: 1 })           // 单次点击
              .onAction((event: GestureEvent) => {
                if (this.componentWidth <= 0 || this.tabs.length <= 0) return;

                // 计算点击的 Tab 索引：点击 X 坐标 / 每个 Tab 宽度
                let tabWidth = this.componentWidth / this.tabs.length;
                let localX = event.fingerList[0].localX;  // 手指相对于组件的 X 坐标
                let index = Math.floor(localX / tabWidth);

                if (index >= 0 && index < this.tabs.length) {
                  // 计算从当前 Tab 到目标 Tab 的跨度
                  let start = this.currentIndex;
                  let end = index;
                  let diff = Math.abs(end - start);

                  // 如果跨度 > 1，中间经过的 Tab 需要依次点亮（流光划过效果）
                  if (diff > 1) {
                    let step = end > start ? 1 : -1;   // 步进方向：向右(+1)或向左(-1)
                    let duration = 300;                 // 总耗时 300ms
                    let stepTime = duration / diff;     // 每步分配的时间

                    // 依次点亮中间经过的 Tab
                    for (let i = 1; i < diff; i++) {
                      let passingIndex = start + i * step;  // 中间 Tab 索引
                      let delay = i * stepTime * 0.5;       // 点亮延迟（系数 0.5 让点亮更早发生）

                      setTimeout(() => {
                        this.getUIContext().animateTo({ duration: 100, curve: Curve.Sharp }, () => {
                          this.lightingIndex = passingIndex;  // 点亮中间 Tab
                        });
                      }, delay);

                      // 稍后熄灭：产生"流光划过"的尾巴效果
                      setTimeout(() => {
                        this.getUIContext().animateTo({ duration: 100, curve: Curve.Smooth }, () => {
                          if (this.lightingIndex === passingIndex) {
                            this.lightingIndex = -1;  // 熄灭
                          }
                        });
                      }, delay + 120);  // 亮 120ms 后熄灭
                    }
                  }

                  // 触发父组件的 onTabClick 回调，切换页面
                  this.onTabClick(index);

                  // 按下放大动画：延迟 100ms 放大（此时高亮框正在移动）
                  setTimeout(() => {
                    this.getUIContext().animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
                      this.pressedIndex = index;  // 设置按下索引 → 触发 scale(1.3)
                    });
                  }, 100);

                  // 恢复大小动画：再过 300ms 恢复
                  setTimeout(() => {
                    this.getUIContext().animateTo({ duration: 300, curve: Curve.Smooth }, () => {
                      this.pressedIndex = -1;  // 恢复为 -1 → 触发 scale(1)
                    });
                  }, 300);
                }
              }),

            // ========== 手势 2：PanGesture（拖拽手势） ==========
            PanGesture({ direction: PanDirection.Horizontal })  // 仅水平拖拽
              .onActionStart((event: GestureEvent) => {
                // 手指按下开始拖拽：高亮框跳到手指位置
                if (this.componentWidth <= 0 || this.tabs.length <= 0) return;
                let tabWidth = this.componentWidth / this.tabs.length;
                let localX = event.fingerList[0].localX;
                let index = Math.floor(localX / tabWidth);
                if (index >= 0 && index < this.tabs.length) {
                  this.hoverIndex = index;       // 高亮框跟随手指
                  this.pressedIndex = index;     // 按下放大效果
                }
              })
              .onActionUpdate((event: GestureEvent) => {
                // 拖拽中持续更新：高亮框实时跟随手指
                if (this.componentWidth <= 0 || this.tabs.length <= 0) return;
                let tabWidth = this.componentWidth / this.tabs.length;
                let localX = event.fingerList[0].localX;
                let index = Math.floor(localX / tabWidth);
                if (index < 0) index = 0;                        // 下限
                if (index >= this.tabs.length) index = this.tabs.length - 1;  // 上限
                this.hoverIndex = index;        // 持续跟随
                this.pressedIndex = index;      // 保持放大
              })
              .onActionEnd(() => {
                // 拖拽结束：平滑恢复到选中状态
                this.getUIContext().animateTo({ duration: 300, curve: Curve.Smooth }, () => {
                  this.hoverIndex = -1;          // 取消悬停 → 回归选中位置
                  this.pressedIndex = -1;        // 恢复大小
                });
              })
          )  // GestureGroup 结束
        )  // .gesture() 结束

        // ──── 鼠标悬停事件（桌面端） ────
        .onMouse((event: MouseEvent) => {
          if (this.componentWidth <= 0 || this.tabs.length <= 0) return;
          let tabWidth = this.componentWidth / this.tabs.length;
          let index = Math.floor(event.x / tabWidth);
          if (index < 0) index = 0;
          if (index >= this.tabs.length) index = this.tabs.length - 1;
          this.hoverIndex = index;  // 高亮框跟随鼠标
        })

        // ──── 鼠标离开事件 ────
        .onHover((isHover: boolean) => {
          if (!isHover) {
            this.hoverIndex = -1;  // 鼠标移出 → 取消悬停 → 回归选中位置
          }
        })
    }
    // ── 外层容器样式 ──
    .width('92%')            // 悬浮宽度 92%（左右各留 4% 边距）
    .height(80)              // 导航栏高度 80
    .margin({ bottom: 20 })  // 底部外边距 20（与屏幕底部的间距）

    // ── 组件尺寸变化监听（获取实际宽度用于 Tab 位置计算） ──
    .onAreaChange((oldArea, newArea) => {
      this.componentWidth = newArea.width as number;  // 保存实际宽度

      // 首次获取到有效宽度时设置初始化标记
      if (!this.isInitialized && this.componentWidth > 0) {
        this.isInitialized = true;  // 初始化完成 → 显示高亮框
      }
    })
  }

  // ════════════════════════════════════════════
  //  @Builder TabItem：单个 Tab 项的 UI 构建函数
  // ════════════════════════════════════════════

  /**
   * 渲染单个导航 Tab（图标 + 文字纵向排列）
   *
   * @param item     - NavigationItem 数据（图标/文字资源）
   * @param index    - 当前 Tab 的索引
   * @param isActive - 是否为激活状态（选中/流光划过点亮）
   *                   激活：高亮图标 + 白色文字
   *                   非激活：灰显图标 + 灰色文字
   */
  @Builder
  TabItem(item: NavigationItem, index: number, isActive: boolean) {
    Column({ space: 6 }) {                              // 图标与文字间距 6
      Image(isActive ? item.activeIcon : item.icon)     // 选中/未选中图标切换
        .width(24)                                      // 图标宽 24
        .height(24)                                     // 图标高 24
        .objectFit(ImageFit.Contain)                    // 保持比例完整显示
        .fillColor(isActive ? '#FFFFFF' : Color.Black)  // 选中白 / 未选中黑
        .opacity(isActive ? 1 : 0.6)                    // 选中不透明 / 未选中半透明

      Text(item.text)                                   // Tab 文本（如"首页"）
        .fontSize(12)
        .fontColor(isActive ? '#FFFFFF' : '#929499')    // 选中白 / 未选中灰
        .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)  // 选中加粗
        .opacity(isActive ? 1 : 0.6)                    // 选中不透明 / 未选中半透明
    }
    .justifyContent(FlexAlign.Center)  // 垂直居中
    .height('100%')                    // 高度撑满
    .layoutWeight(1)                   // 等分宽度（每个 Tab 占 1/n 宽度）

    // 按下缩放效果：pressedIndex === index 时缩小到 0.9 倍
    .scale({
      x: this.pressedIndex === index ? 0.9 : 1,
      y: this.pressedIndex === index ? 0.9 : 1
    })
    .animation({ duration: 100 })  // 缩放动画 100ms（弹性反馈）
  }
}
