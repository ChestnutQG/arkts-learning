/**
 * =============================================================================
 *  LoginPage - 登录页面（生命周期演示用）
 * =============================================================================
 * 【作用】
 *   与 LifeCycleDemo 配合演示页面生命周期回调的执行顺序。
 *   从 LifeCycleDemo 跳转到本页面时，可观察：
 *     LifeCycleDemo → onPageHide
 *     LoginPage     → aboutToAppear → onPageShow
 *   从本页面返回（系统返回键/路由返回）时，可观察：
 *     LoginPage     → onPageHide → aboutToDisappear
 *     LifeCycleDemo → onPageShow
 *
 * 【生命周期要点】
 *   页面跳转涉及"当前页隐藏"和"目标页显示"两个事件：
 *     - onPageHide：当前页面被覆盖时触发
 *     - onPageShow：页面变为可见时触发（首次进入/从其他页返回）
 *   与 aboutToAppear/disappear 的区别：
 *     - aboutToAppear/disappear 与页面的创建/销毁相关（各一次）
 *     - onPageShow/hide 与页面的可见性相关（可多次触发）
 * =============================================================================
 */

import { router } from '@kit.ArkUI'
// router: 路由模块，保留导入以便在需要时扩展返回功能

/**
 * LoginCom - 子组件
 * 演示组件级别的生命周期（aboutToAppear / aboutToDisappear）
 */
@Component
struct LoginCom {
  /** 组件挂载时触发（父组件创建并渲染 LoginCom 时调用） */
  aboutToAppear(): void {
    console.log('LoginCom - aboutToAppear')
  }

  /** 组件卸载时触发（父组件销毁时调用） */
  aboutToDisappear(): void {
    console.log('LoginCom - aboutToDisappear')
  }

  /** 构建 UI：显示"登录子组件"文本 */
  build() {
    Text('登录子组件')
  }
}

/**
 * LoginPage - 登录主页面（@Entry 标记为路由页面）
 * 演示页面级别的生命周期回调
 */
@Entry
@Component
struct LoginPage {
  // ════════════════════════════════════════════
  //  页面级生命周期回调（@Entry 页面专有）
  // ════════════════════════════════════════════

  /** 页面即将显示时触发（首次创建时调用一次，在 build() 之前） */
  aboutToAppear(): void {
    console.log('LoginPage - aboutToAppear')
  }

  /** 页面即将销毁时触发（从本页面返回上一页时调用一次） */
  aboutToDisappear(): void {
    console.log('LoginPage - aboutToDisappear')
  }

  /** 页面显示时触发（首次进入 + 从其他页面返回时均触发） */
  onPageShow(): void {
    console.log('LoginPage - onPageShow')
  }

  /** 页面隐藏时触发（跳转到其他页面，当前页被覆盖时触发） */
  onPageHide(): void {
    console.log('LoginPage - onPageHide')
  }

  // ──── 状态变量 ────

  /** 登录页标题文本（@State 装饰，当值变化时自动刷新 UI） */
  @State message: string = '登录';

  /**
   * 构建 UI
   * Row 水平居中 → Column 纵向排列 → 标题 + 子组件
   */
  build() {
    Row() {
      Column() {
        Text(this.message)                 // 页面标题（"登录"）
          .fontSize(50)                    // 大字号标题
          .fontWeight(FontWeight.Bold)     // 加粗字体

        LoginCom()                         // 渲染子组件
      }
      .width('100%')
    }
    .height('100%')
  }
}
