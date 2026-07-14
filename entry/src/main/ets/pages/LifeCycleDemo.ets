/**
 * =============================================================================
 *  LifeCycleDemo - 生命周期演示页面
 * =============================================================================
 * 【作用】
 *   演示 HarmonyOS 中页面级和组件级生命周期回调的执行顺序。
 *   通过控制子组件的显示/隐藏和页面跳转，直观观察各个生命周期方法的触发时机。
 *
 * 【页面级生命周期（仅 @Entry 页面拥有）】
 *   aboutToAppear()   - 页面即将显示时触发（首次进入时调用一次）
 *   aboutToDisappear()- 页面即将销毁时触发（返回上一页时调用一次）
 *   onPageShow()      - 页面显示时触发（首次进入 + 从其他页面返回时均触发）
 *   onPageHide()      - 页面隐藏时触发（跳转到其他页面，当前页被覆盖时触发）
 *
 * 【组件级生命周期（所有 @Component 都拥有）】
 *   aboutToAppear()   - 组件即将挂载到组件树时触发
 *   aboutToDisappear()- 组件即将从组件树卸载时触发
 *
 * 【生命周期触发顺序示例】
 *   首次进入：父 aboutToAppear → 父 onPageShow → 子 aboutToAppear
 *   隐藏子：  子 aboutToDisappear
 *   显示子：  子 aboutToAppear
 *   跳转：    父 onPageHide → 新页 aboutToAppear → 新页 onPageShow
 *   返回：    新页 onPageHide → 新页 aboutToDisappear → 父 onPageShow
 * =============================================================================
 */

import { router } from '@kit.ArkUI';
// router: 页面路由模块，用于 pushUrl（跳转到 LoginPage）和 back（返回）

/**
 * SonCom - 子组件
 * 用于演示组件级别的生命周期
 * 当父组件中 if(this.show) 条件变化时，SonCom 被创建（aboutToAppear）或销毁（aboutToDisappear）
 */
@Component
struct SonCom {
  /** 组件即将挂载到组件树时触发（父组件中的 if 条件变为 true） */
  aboutToAppear(): void {
    console.log('子组件 - aboutToAppear');
  }

  /** 组件即将从组件树卸载时触发（父组件中的 if 条件变为 false） */
  aboutToDisappear(): void {
    console.log('子组件 - aboutToDisappear');
  }

  /** 构建 UI：一个居中显示、带边框的 200x200 "我是子组件" 文本 */
  build() {
    Column() {
      Text('我是子组件')  // 标识文本
    }
    .width(200)           // 列宽 200
    .height(200)          // 列高 200
    .border({ width: 3 }) // 3px 宽边框（便于视觉识别）
    .margin(20)           // 外边距 20
  }
}

/**
 * LifeCycleDemo - 主页面（@Entry）
 * 演示页面级 + 组件级的所有生命周期回调
 */
@Entry
@Component
struct LifeCycleDemo {
  /**
   * 控制子组件显示/隐藏的状态变量
   * @State 装饰：当 show 值变化时自动刷新 UI
   * if(this.show) 条件渲染：true=显示 SonCom，false=销毁 SonCom
   */
  @State show: boolean = true;

  // ════════════════════════════════════════════
  //  页面级生命周期回调（@Entry 页面特有）
  // ════════════════════════════════════════════

  /**
   * 页面即将显示时触发（整个生命周期只调用一次）
   * 在 build() 执行之前触发
   * 适合在此做：数据初始化、网络请求发起（不会导致白屏，因为 build() 还没执行）
   */
  aboutToAppear(): void {
    console.log('父页面 - aboutToAppear');
  }

  /**
   * 页面即将销毁时触发（整个生命周期只调用一次）
   * 对应场景：返回上一页 / 关闭页面
   * 适合在此做：释放资源、取消网络订阅、保存草稿数据
   */
  aboutToDisappear(): void {
    console.log('父页面 - aboutToDisappear');
  }

  /**
   * 页面隐藏时触发
   * 对应场景：跳转到其他页面，当前页面被覆盖
   * 注意：与 aboutToDisappear 不同，onPageHide 不表示页面销毁，
   * 页面仍然存活在路由栈中，只是被其他页面覆盖了
   */
  onPageHide(): void {
    console.log('父页面 - 当页面隐藏的时候');
  }

  /**
   * 页面显示时触发
   * 触发场景：
   *   1. 首次进入该页面时（在 aboutToAppear 之后触发）
   *   2. 从其他页面返回该页面时
   * 注意：每次页面变为可见状态都会触发，不像 aboutToAppear 只触发一次
   */
  onPageShow(): void {
    console.log('父页面 - 当页面显示的时候');
  }

  /**
   * 构建 UI 布局
   * 包含：标题、切换子组件按钮、条件渲染的子组件、跳转按钮
   */
  build() {
    Column() {
      Text('组件的生命周期')     // 页面标题
        .fontSize(40)

      Button('切换子组件显示')   // 点击切换 show 变量的值
        .onClick(() => {
          this.show = !this.show;  // true↔false 切换
        })

      // if(this.show) 条件渲染语法
      // show=true → SonCom 被创建并挂载（触发 aboutToAppear）
      // show=false → SonCom 被销毁（触发 aboutToDisappear）
      if (this.show) {
        SonCom()
      }

      Button('跳转页面')         // 跳转到 LoginPage
        .onClick(() => {
          // pushUrl：将 LoginPage 推入路由栈
          // 当前页面被覆盖 → 触发 onPageHide
          // LoginPage 创建 → 触发 aboutToAppear + onPageShow
          router.pushUrl({
            url: 'pages/LoginPage'  // 目标页面路径（已注册在 main_pages.json 中）
          });
        })
    }
  }
}
