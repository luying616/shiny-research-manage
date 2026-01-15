# 测试和运行指南

## 环境准备

### 1. 安装R（如果尚未安装）

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install r-base r-base-dev
```

**macOS:**
```bash
brew install r
```

**Windows:**
从 https://cran.r-project.org/bin/windows/base/ 下载并安装

### 2. 安装PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt-get install postgresql postgresql-contrib
```

**macOS:**
```bash
brew install postgresql
```

### 3. 安装必要的R包

启动R或RStudio，运行以下命令：

```r
# 安装必要的包
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

## 数据库设置

### 1. 创建数据库

```bash
# 切换到postgres用户
sudo -u postgres psql

# 在PostgreSQL中执行
CREATE DATABASE research_db;
\q
```

### 2. 初始化数据库表

```bash
# 执行初始化脚本
psql -U postgres -d research_db -f scripts/init_database.sql
```

### 3. 配置环境变量

创建文件 `/data/share/luying/shinyApp/.env`：

```env
DB_NAME=research_db
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password_here
```

或者修改 `global.R` 中的环境变量路径。

## 测试R代码语法

```bash
# 检查R文件语法
R -e "source('global.R')"
R -e "source('modules/auth_module.R')"
R -e "source('modules/dashboard_module.R')"
R -e "source('modules/project_module.R')"
R -e "source('modules/reports_module.R')"
R -e "source('modules/project_code_generator.R')"
```

## 运行应用

### 方法1：从R控制台

```r
# 设置工作目录
setwd("/path/to/shiny-research-manage")

# 运行应用
shiny::runApp("app.R", port = 3838, host = "0.0.0.0")
```

### 方法2：从命令行

```bash
cd /path/to/shiny-research-manage
R -e "shiny::runApp('app.R', port = 3838, host = '0.0.0.0')"
```

### 方法3：使用RStudio

1. 在RStudio中打开 `app.R` 文件
2. 点击右上角的 "Run App" 按钮

## 测试checklist

### 基础功能测试

- [ ] 应用能正常启动
- [ ] 页面能正常加载
- [ ] CSS样式正确显示
- [ ] 侧边栏菜单可以切换

### 数据库连接测试

- [ ] 数据库连接成功
- [ ] 能够读取数据
- [ ] 能够写入数据

### 功能模块测试

#### 仪表板
- [ ] 统计卡片显示正常
- [ ] 图表渲染正常
- [ ] 刷新功能正常

#### 项目管理
- [ ] 项目列表显示正常
- [ ] 筛选功能正常
- [ ] 创建项目功能正常
- [ ] 编辑项目功能正常
- [ ] 删除项目功能正常
- [ ] 导出CSV功能正常
- [ ] 导出Excel功能正常

#### 报告生成
- [ ] 报告类型选择正常
- [ ] 报告生成功能正常
- [ ] 历史报告列表显示正常

#### 系统帮助
- [ ] README内容显示正常

### 认证功能测试（如果启用）

- [ ] 登录功能正常
- [ ] 密码验证正常
- [ ] 登出功能正常

## 调试模式

在开发和测试阶段，可以启用调试模式：

在 `global.R` 中设置：
```r
DEBUG_MODE <- TRUE
```

调试模式下：
- 不需要登录
- 可以使用模拟数据
- 显示详细日志

## 常见问题排查

### 1. 包加载失败

```r
# 检查包是否安装
installed.packages()

# 重新安装特定包
install.packages("package_name")
```

### 2. 数据库连接失败

- 检查PostgreSQL服务是否运行
- 验证环境变量配置
- 检查数据库权限
- 查看日志输出

### 3. 端口已被占用

```bash
# 查看端口占用
lsof -i :3838

# 或使用其他端口
shiny::runApp("app.R", port = 3839)
```

### 4. 页面显示异常

- 清除浏览器缓存
- 检查CSS文件是否存在
- 查看浏览器控制台错误

## 性能测试

### 1. 负载测试

```r
# 安装shinyloadtest包
install.packages("shinyloadtest")

# 记录测试场景
shinyloadtest::record_session("http://localhost:3838")

# 运行负载测试
shinyloadtest::load_test("recording.log", workers = 10, duration = 60)
```

### 2. 内存监控

```r
# 查看内存使用
pryr::mem_used()

# 查看对象大小
pryr::object_size(your_object)
```

## 日志查看

应用运行时会在控制台输出日志，包括：
- INFO：一般信息
- WARN：警告信息
- ERROR：错误信息

可以根据日志信息进行问题排查。

## 部署到生产环境

### 使用Shiny Server

1. 安装Shiny Server
2. 将应用复制到 `/srv/shiny-server/`
3. 配置 `/etc/shiny-server/shiny-server.conf`
4. 重启Shiny Server

详细文档：https://www.rstudio.com/products/shiny/download-server/

### 使用Docker

创建 `Dockerfile`（待实现）

## 备份和恢复

### 数据库备份

```bash
pg_dump -U postgres research_db > backup.sql
```

### 数据库恢复

```bash
psql -U postgres research_db < backup.sql
```

## 维护建议

- 定期备份数据库
- 监控应用性能
- 及时更新R包
- 查看和分析日志
- 定期清理临时文件

## 支持

如有问题，请联系系统管理员或提交Issue。
