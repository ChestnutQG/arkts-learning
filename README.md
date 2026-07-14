# HarmonyOS ArkTS 电商应用示例

<p align="center">
  <img src="https://img.shields.io/badge/HarmonyOS-4.0-blue" alt="HarmonyOS">
  <img src="https://img.shields.io/badge/ArkTS-TypeScript-green" alt="ArkTS">
  <img src="https://img.shields.io/badge/API-6.1.0(23)-orange" alt="API">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

## 📱 项目简介

这是一个基于 HarmonyOS ArkTS 开发的综合性电商应用示例，展示了现代鸿蒙应用开发的完整技术栈。项目采用模块化架构，实现了商品展示、购物车管理、分类浏览、用户登录等核心电商功能，同时集成了多种 HarmonyOS 高级特性。

## ✨ 核心特性

### 🎨 现代化 UI/UX
- **玻璃流光导航栏**：自定义底部 TabBar，支持毛玻璃效果、磁吸高亮和流光动画
- **响应式布局**：自适应不同屏幕尺寸，提供流畅的交互体验
- **瀑布流展示**：服装、电器分类采用瀑布流布局，优化视觉呈现
- **轮播图组件**：首页集成自动轮播的 Banner 广告

### 🛒 完整电商功能
- **多级商品分类**：服装、电器、手机等商品分类展示
- **智能购物车**：支持 RDB + Preferences 双存储，数据持久化
- **商品详情页**：完整的商品信息展示和购买流程
- **实时数据同步**：购物车数据实时更新，支持跨页面刷新

### 🔧 技术亮点
- **双向数据绑定**：使用 `@State`、`@Prop`、`@Link` 装饰器实现响应式数据流
- **组件化开发**：高度复用的业务组件和基础组件
- **生命周期管理**：完整的页面和组件生命周期演示
- **状态管理**：基于装饰器的状态管理方案
- **图片缓存**：自定义 ImageCacheManager 优化图片加载性能

## 📁 项目结构

```
MyApplication3/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用配置
│   └── resources/              # 全局资源文件
├── entry/                       # 主模块
│   ├── src/main/ets/
│   │   ├── pages/              # 页面组件
│   │   │   ├── Index.ets       # 主入口页面（@Entry）
│   │   │   ├── LifeCycleDemo.ets # 生命周期演示页
│   │   │   ├── LoginPage.ets   # 用户登录页
│   │   │   ├── ShopStorePage.ets # 手机商城页
│   │   │   ├── LightFlowTabBar.ets # 自定义导航栏
│   │   │   └── NavigationItem.ets # 导航项组件
│   │   ├── business/           # 业务组件
│   │   │   ├── DepartmentHomeView.ets    # 首页视图
│   │   │   ├── DepartmentClassView.ets   # 分类视图
│   │   │   ├── DepartmentCartView.ets    # 购物车视图
│   │   │   ├── DepartmentStorePage.ets   # 商店主页
│   │   │   ├── ClassClothesView.ets      # 服装分类
│   │   │   └── ClassAppliancesView.ets   # 电器分类
│   │   ├── entity/             # 数据实体
│   │   │   ├── GoodsInfo.ets   # 商品信息实体
│   │   │   ├── CartItem.ets    # 购物车项实体
│   │   │   ├── SwipeDataSource.ets       # 轮播数据源
│   │   │   ├── WaterFlowDataSource.ets   # 瀑布流数据源
│   │   │   ├── ClothesDataSource.ets     # 服装数据源
│   │   │   ├── AppliancesDataSource.ets  # 电器数据源
│   │   │   ├── ItemOption.ets  # 选项配置实体
│   │   │   ├── ImageCacheManager.ets     # 图片缓存管理
│   │   │   ├── CartRdbUtil.ets           # RDB 购物车工具
│   │   │   └── CartPreferencesUtil.ets   # Preferences 购物车工具
│   │   └── entryability/       # Ability 入口
│   │       ├── EntryAbility.ets          # 主 Ability
│   │       └── EntryBackupAbility.ets    # 备份 Ability
│   └── src/main/resources/     # 模块资源
│       ├── base/media/         # 图片资源（100+ 张商品图片）
│       ├── base/profile/       # 配置文件
│       └── base/element/       # 样式资源
├── hvigor/                     # 构建配置
├── oh_modules/                 # 项目依赖
└── 配置文件
    ├── build-profile.json5    # 构建配置
    ├── oh-package.json5       # 依赖管理
    ├── hvigorfile.ts          # 构建脚本
    └── code-linter.json5      # 代码检查配置
```

## 🚀 快速开始

### 环境要求
- **DevEco Studio 4.0+**：HarmonyOS 官方开发工具
- **Node.js 14+**：JavaScript 运行时环境
- **HarmonyOS SDK**：API 6.1.0(23) 或更高版本
- **Java JDK 11+**：Java 开发工具包

### 构建步骤
1. **克隆项目**
   ```bash
   git clone https://gitee.com/chestnutqg/ark-ts.git
   cd MyApplication3
   ```

2. **安装依赖**
   ```bash
   # 使用 DevEco Studio 打开项目
   # 或通过命令行安装依赖
   npm install
   ```

3. **配置签名**
   - 在 DevEco Studio 中配置应用签名
   - 或使用项目自带的调试签名

4. **运行项目**
   - 连接 HarmonyOS 真机或启动模拟器
   - 点击运行按钮（▶️）或使用快捷键 `Shift + F10`

## 🛠️ 技术架构

### 核心架构
```
┌─────────────────────────────────────────────┐
│                UI 层 (Pages)                │
│  Index → HomeView/ClassView/CartView        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│            业务逻辑层 (Business)             │
│  组件化设计、状态管理、事件处理              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│            数据层 (Entity/Utils)            │
│  数据模型、数据源、缓存管理、工具类         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│          持久化层 (RDB/Preferences)         │
│  本地存储、数据同步、状态持久化             │
└─────────────────────────────────────────────┘
```

### 关键技术点

#### 1. 状态管理
```typescript
// 使用 @State、@Prop、@Link 装饰器
@State current: number = 0;
@State cartRefreshCounter: number = 0;

// 双向数据绑定
Tabs({ barPosition: BarPosition.End, index: $$this.current })
```

#### 2. 组件通信
- **父子组件**：`@Prop` 传递数据，`@Watch` 监听变化
- **兄弟组件**：通过父组件中转状态
- **页面间通信**：路由参数 + 页面生命周期

#### 3. 数据持久化
- **RDB (Relational Database)**：结构化数据存储
- **Preferences**：轻量级键值对存储
- **双存储策略**：购物车数据同时保存到 RDB 和 Preferences

#### 4. 性能优化
- **图片缓存**：ImageCacheManager 减少重复加载
- **懒加载**：瀑布流列表的懒加载实现
- **事件防抖**：频繁操作的事件防抖处理

## 📱 页面功能详解

### 1. 首页 (Index.ets)
- **底部导航栏**：自定义玻璃流光效果 TabBar
- **三栏布局**：首页、分类、购物车三页切换
- **悬浮按钮**：生命周期演示和手机商城入口
- **数据刷新机制**：购物车数据自动刷新

### 2. 商品分类页 (DepartmentClassView.ets)
- **二级分类**：服装、电器两大分类
- **瀑布流布局**：自适应高度的瀑布流展示
- **智能排序**：支持价格、销量等多维度排序
- **筛选功能**：品牌、价格区间筛选

### 3. 购物车页 (DepartmentCartView.ets)
- **双存储方案**：RDB + Preferences 保证数据可靠性
- **实时计算**：自动计算总价、优惠、运费
- **批量操作**：全选、删除、数量修改
- **数据同步**：跨页面数据实时同步

### 4. 手机商城 (ShopStorePage.ets)
- **商品详情**：完整的商品信息展示
- **购物流程**：加入购物车、立即购买
- **图片预览**：支持商品图片缩放查看
- **规格选择**：颜色、版本等规格选择

### 5. 生命周期演示 (LifeCycleDemo.ets)
- **生命周期钩子**：完整演示 ArkTS 组件生命周期
- **状态管理**：@State、@Prop、@Link 使用示例
- **事件处理**：点击、滑动等事件处理示例

## 🔧 开发指南

### 添加新页面
1. 在 `entry/src/main/ets/pages/` 创建新的 `.ets` 文件
2. 使用 `@Entry` 装饰器标记页面组件
3. 在 `entry/src/main/resources/base/profile/main_pages.json` 中注册路由
4. 通过 `router.pushUrl()` 进行页面跳转

### 添加新商品分类
1. 在 `entity/` 目录下创建数据源类
2. 在 `business/` 目录下创建对应的视图组件
3. 在 `DepartmentClassView.ets` 中集成新分类
4. 在 `resources/base/media/` 添加商品图片

### 自定义组件开发
```typescript
@Component
export struct CustomComponent {
  // 使用 @Prop 接收父组件数据
  @Prop title: string = '';
  
  // 使用 @State 管理内部状态
  @State isActive: boolean = false;
  
  // 使用 @Link 实现双向绑定
  @Link value: number;
  
  build() {
    // 组件 UI 构建
  }
}
```

## 📊 数据模型

### GoodsInfo (商品信息)
```typescript
class GoodsInfo {
  id: string;           // 商品ID
  name: string;         // 商品名称
  price: number;        // 商品价格
  pic: string;          // 图片资源路径
  desc: string;         // 商品描述
  category: string;     // 商品分类
  // ... 其他属性
}
```

### CartItem (购物车项)
```typescript
class CartItem {
  id: string;           // 购物车项ID
  goodsId: string;      // 商品ID
  name: string;        // 商品名称
  price: number;       // 单价
  quantity: number;    // 数量
  image: string;       // 图片资源
  // ... 其他属性
}
```

## 🚀 部署与发布

### 调试版本
```bash
# 生成调试版本 HAP
npm run build:debug
```

### 发布版本
```bash
# 生成发布版本 HAP
npm run build:release
```

### 应用签名
1. 在 DevEco Studio 中创建签名证书
2. 配置 `build-profile.json5` 中的签名信息
3. 使用 `ohos.p7b` 和 `ohos.p12` 文件进行签名

## 📚 学习资源

### 官方文档
- [HarmonyOS 应用开发](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/start-overview-0000001478061421-V3)
- [ArkTS 语言指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-get-started-0000001504925041-V3)
- [ArkUI 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkui-get-started-0000001504924929-V3)

### 相关项目
- [HarmonyOS 官方示例](https://gitee.com/openharmony/applications_app_samples)
- [ArkUI 组件库](https://gitee.com/openharmony/arkui_ace_engine)

## 🤝 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目基于 MIT 许可证开源，详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 反馈与支持

如有问题或建议，欢迎通过以下方式参与：

- **Gitee Issues**: [项目 Issues](https://gitee.com/chestnutqg/ark-ts/issues)
- **Pull Requests**: 欢迎提交代码改进和功能增强

---

<p align="center">
  Made with ❤️ for HarmonyOS Developers
</p>

<p align="center">
  <sub>如果这个项目对您有帮助，请给个 ⭐️ Star 支持一下！</sub>
</p>