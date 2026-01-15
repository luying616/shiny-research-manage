# 科研项目管理系统

## 📋 系统简介

科研项目管理系统是一个基于 R Shiny 开发的 Web 应用程序，专为三甲医院科研实验室设计，用于管理各类科研项目的全生命周期。系统采用现代化的界面设计和模块化架构，提供项目创建、跟踪、统计分析和报告生成等功能。

## ✨ 核心功能

### 1. 项目管理
- **项目CRUD操作**：创建、查看、编辑、删除项目
- **智能编号生成**：自动生成项目编号，格式为`类型-年份-序号[-优先级]`
  - 基础研究 → JC (JI CHU)
  - 应用研究 → YY (YING YONG)
  - 临床研究 → LC (LIN CHUANG)
  - 数据项目 → SJ (SHU JU)
  - 资源项目 → ZY (ZI YUAN)
- **项目信息管理**：
  - 基本信息：名称、编号、类型、状态
  - 时间管理：开始/结束日期、项目周期
  - 资金管理：预算、经费来源
  - 人员管理：负责人、项目经理、研究团队
  - 研究信息：研究阶段、研究领域、合作类型

### 2. 数据展示与筛选
- **项目列表**：分页表格显示，支持状态和优先级标签
- **高级筛选**：
  - 按项目类型、状态、优先级筛选
  - 按负责人筛选
  - 按日期范围筛选
  - 关键词搜索（名称、编号、描述等）

### 3. 统计仪表板
- 总项目数统计
- 进行中项目统计
- 即将到期项目提醒（30天内）
- 总预算统计
- 项目类型分布图
- 项目状态分布图
- 最近创建项目列表

### 4. 数据导出
- CSV 格式导出
- Excel 格式导出
- 支持筛选后数据导出

### 5. 报告生成
- 项目概览报告
- 项目状态报告
- 资金使用报告
- 合作项目报告
- 自定义报告
- 支持 HTML/PDF/Word 格式

### 6. 用户认证
- 用户登录/登出功能
- 基于角色的权限控制
- 调试模式支持（开发时可禁用认证）

## 🏗️ 技术架构

### 技术栈
- **后端框架**：R Shiny
- **数据库**：PostgreSQL 12+
- **UI组件**：shinydashboard, shinyWidgets, DT
- **数据处理**：dplyr, jsonlite
- **文档生成**：rmarkdown
- **日志系统**：logger（使用sprintf格式化）

### 项目结构
```
shiny-research-manage/
├── app.R                    # 主应用文件
├── global.R                 # 全局配置和常量
├── README.md               # 项目文档
├── modules/                # 模块目录
│   ├── auth_module.R       # 认证模块
│   ├── dashboard_module.R  # 仪表板模块
│   ├── project_module.R    # 项目管理模块
│   ├── reports_module.R    # 报告生成模块
│   └── project_code_generator.R  # 项目编号生成器
├── www/                    # 静态资源
│   ├── style.css          # 自定义样式表
│   ├── logo.png           # 应用Logo
│   └── logo_tab.png       # 浏览器标签页图标
└── scripts/                # 辅助脚本（如数据库初始化脚本）
```

## 🚀 安装和部署

### 环境要求
- R >= 4.0.0
- PostgreSQL >= 12.0
- 必要的R包（见下文）

### 安装R包
```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "DT",
  "pool",
  "RPostgres",
  "dplyr",
  "logger",
  "dotenv",
  "jsonlite",
  "lubridate",
  "openxlsx",
  "digest"
))
```

### 数据库配置

1. **创建环境变量文件**

创建文件 `/data/share/luying/shinyApp/.env`（或修改 `global.R` 中的路径）：
```env
DB_NAME=research_db
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
```

2. **初始化数据库结构**

使用提供的 SQL 脚本创建数据库表结构：
- `projects` schema：项目相关表
- `auth` schema：用户认证表

详细的数据库表结构请参考问题陈述中的SQL定义。

### 运行应用

```r
# 方法1：使用 shiny 包
shiny::runApp("app.R", port = 3838, host = "0.0.0.0")

# 方法2：使用 RStudio
# 直接点击 RStudio 界面中的 "Run App" 按钮
```

## 📖 使用指南

### 快速开始

1. **启动应用**
   - 运行 `app.R` 文件
   - 浏览器将自动打开应用界面

2. **登录系统**（如果未启用调试模式）
   - 输入用户名和密码
   - 调试模式下可以跳过登录

3. **查看仪表板**
   - 点击左侧菜单"仪表板"
   - 查看项目统计信息和图表

4. **管理项目**
   - 点击"项目管理"
   - 使用"创建新项目"按钮添加项目
   - 使用筛选功能查找特定项目
   - 点击操作按钮查看、编辑或删除项目

5. **导出数据**
   - 在项目列表页面
   - 点击"导出CSV"或"导出Excel"按钮

6. **生成报告**
   - 点击"报告生成"
   - 选择报告类型和格式
   - 点击"生成报告"按钮

### 项目编号规则

系统会自动生成项目编号，格式为：`类型代码-年份-序号[-优先级]`

**示例**：
- `JC-2026-001`：基础研究项目，2026年第1号
- `LC-2026-015-H`：临床研究项目，2026年第15号，高优先级
- `SJ-202601-003`：数据项目，2026年1月第3号（月度编号模式）

### 筛选和搜索

系统提供多种筛选方式：
- **类型筛选**：按项目类型筛选
- **状态筛选**：规划中、进行中、暂停、已完成、已取消
- **优先级筛选**：高、中、低
- **日期筛选**：按开始日期或结束日期范围筛选
- **关键词搜索**：在项目名称和编号中搜索

## 🔧 配置说明

### 调试模式

在 `global.R` 中设置：
```r
DEBUG_MODE <- TRUE  # 启用调试模式，跳过登录
```

调试模式下：
- 不需要登录即可使用系统
- 使用模拟数据（如果数据库不可用）
- 显示更详细的日志信息

### 数据库连接

系统使用连接池管理数据库连接：
```r
db_pool <- dbPool(
  drv = RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("DB_HOST"),
  port = as.integer(Sys.getenv("DB_PORT")),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD"),
  minSize = 2,
  maxSize = 10,
  idleTimeout = 300000
)
```

### 自定义样式

所有样式定义在 `www/style.css` 文件中，包含详细的样式说明注释。

可以自定义：
- 颜色主题
- 按钮样式
- 表格样式
- 状态标签颜色
- 响应式布局

## 🔒 安全特性

### 密码安全
- 使用 SHA-256 算法存储密码哈希
- 不存储明文密码

### 数据库安全
- 使用参数化查询防止 SQL 注入
- 连接池管理，自动处理连接超时
- 数据库凭证通过环境变量管理

### 访问控制
- 基于角色的权限管理（管理员、项目经理、分析员、查看者）
- 会话管理
- 操作日志记录

## 📊 数据库结构

系统使用多表设计，主要表包括：

- `projects.projects`：项目主表
- `projects.project_types`：项目类型字典
- `projects.project_statuses`：项目状态字典
- `projects.research_stages`：研究阶段字典
- `projects.researchers`：研究人员表
- `projects.project_researchers`：项目-研究人员关联表
- `projects.research_fields`：研究领域表
- `projects.funding_sources`：经费来源表
- `projects.project_milestones`：项目里程碑表
- `projects.project_documents`：项目文档表
- `projects.project_budget_items`：预算明细表
- `auth.users`：用户表

详细的表结构和关系请参考数据库设计文档。

## 🐛 故障排查

### 常见问题

**1. 数据库连接失败**
- 检查 `.env` 文件是否正确配置
- 确认 PostgreSQL 服务是否运行
- 验证数据库用户权限

**2. 包加载失败**
- 运行 `install.packages()` 安装缺失的包
- 检查 R 版本是否满足要求

**3. 页面显示异常**
- 清除浏览器缓存
- 检查 `www/style.css` 文件是否存在
- 查看浏览器控制台的错误信息

**4. 日志相关错误**
- 系统使用 `sprintf` 而不是 `glue` 格式化日志
- 确保日志格式字符串正确

### 日志查看

系统使用 `logger` 包记录日志，默认输出到控制台。

日志级别：
- `INFO`：一般信息
- `WARN`：警告信息
- `ERROR`：错误信息

## 🔄 版本历史

### v1.0.0 (2026-01-15)
- 初始版本发布
- 实现核心功能：项目管理、仪表板、报告生成
- 支持用户认证和权限控制
- 实现智能项目编号生成
- 支持数据导出和高级筛选

## 📝 开发说明

### 代码风格
- 使用中文注释
- 模块化设计，每个模块的 UI 和 Server 代码放在同一文件
- 使用 `sprintf` 格式化字符串，避免 `glue` 冲突
- showNotification 的 type 参数使用："default", "message", "warning", "error"

### 添加新功能
1. 在 `modules/` 目录创建新模块文件
2. 定义模块的 UI 和 Server 函数
3. 在 `app.R` 中加载模块
4. 在主界面添加相应的菜单项和页面

### 数据库更改
1. 修改 SQL 脚本
2. 执行数据库迁移
3. 更新相关的查询代码

## 🤝 贡献指南

欢迎提交问题和改进建议。

## 📄 许可证

本项目仅供内部使用。

## 📧 联系方式

如有问题或建议，请联系系统管理员。

---

**系统版本**：1.0.0  
**最后更新**：2026-01-15  
**开发团队**：科研项目管理系统开发组