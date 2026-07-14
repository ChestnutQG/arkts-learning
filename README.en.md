# ark-ts

An ArkTS-based HarmonyOS learning project demonstrating practical applications of various UI components and data lists.

## Project Overview

This is an example HarmonyOS application developed using the ArkTS language, featuring interface implementations for multiple business scenarios such as product display, shopping cart, and category browsing. Through this project, you can learn:

- Basic architecture setup for HarmonyOS applications
- Usage of various UI components
- Data source binding and refresh mechanisms
- Page navigation and routing configuration

## Main Functional Modules

### Business Pages (business/)

- **ClassAppliancesView** - Appliances Category View  
- **ClassClothesView** - Clothing Category View
- **DepartmentCartView** - Shopping Cart Page
- **DepartmentClassView** - Product Category Page
- **DepartmentHomeView** - Home Navigation
- **DepartmentStorePage** - Store Homepage

### Data Entities (entity/)

- AppliancesDataSource - Appliances Data Source
- ClothesDataSource - Clothing Data Source
- GoodsInfo - Product Information Entity
- ItemOption - Option Configuration Entity
- SwipeDataSource - Swipe Data Source
- WaterFlowDataSource - Waterfall Layout Data Source

### Demo Pages (pages/)

- Index - Application Home Page
- LifeCycleDemo - Lifecycle Demonstration
- LightFlowTabBar - Tab Navigation Bar
- LoginPage - Login Page
- NavigationItem - Navigation Item Component

## Technology Stack

- **Language**: ArkTS
- **Framework**: HarmonyOS
- **API Version**: Supports HarmonyOS APIs

## Environment Requirements

- Latest version of DevEco Studio
- Node.js 14.x or higher
- HarmonyOS SDK

## Quick Start

1. Clone the project to your local machine
2. Open the project in DevEco Studio
3. Connect a physical device or emulator
4. Click the Run button to launch the application

## Project Structure

```
entry/
├── src/main/ets/
│   ├── business/          # Business page components
│   ├── entity/            # Data entity classes
│   ├── entryability/      # Entry capability
│   └── pages/             # Page components
└── src/main/resources/    # Resource files
```

## License

This project is for learning and reference purposes only.