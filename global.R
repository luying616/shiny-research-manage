# ==================== 全局配置文件 ====================
# 科研项目管理系统 - Global Configuration
# 
# 功能说明：
# 1. 加载必要的R包
# 2. 配置数据库连接池
# 3. 设置全局常量和配置
# 4. 初始化日志系统
# ======================================================

# ==================== 加载必要的包 ====================
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyWidgets)
  library(DT)
  library(pool)
  library(RPostgres)
  library(dplyr)
  library(logger)
  library(dotenv)
  library(jsonlite)
  library(lubridate)
  library(openxlsx)
  library(digest)
})

# ==================== 日志系统配置 ====================
# 使用sprintf格式化日志，避免glue语法冲突
log_layout(layout_glue_generator(format = '[{time}] {level}: {msg}'))
log_threshold(INFO)

log_info("========== 科研项目管理系统初始化 ==========")

# ==================== 环境变量加载 ====================
# 加载环境变量
env_file_path <- "/data/share/luying/shinyApp/.env"
if (file.exists(env_file_path)) {
  tryCatch({
    dotenv::load_dot_env(env_file_path)
    log_info(sprintf("环境变量加载成功: %s", env_file_path))
  }, error = function(e) {
    log_warn(sprintf("环境变量加载失败: %s，使用默认配置", e$message))
  })
} else {
  log_warn(sprintf("环境变量文件不存在: %s，使用默认配置", env_file_path))
}

# ==================== 数据库连接配置 ====================
# 数据库连接池配置
db_pool <- NULL

tryCatch({
  db_pool <- dbPool(
    drv = RPostgres::Postgres(),
    dbname = Sys.getenv("DB_NAME", "research_db"),
    host = Sys.getenv("DB_HOST", "localhost"),
    port = as.integer(Sys.getenv("DB_PORT", "5432")),
    user = Sys.getenv("DB_USER", "postgres"),
    password = Sys.getenv("DB_PASSWORD", ""),
    minSize = 2,
    maxSize = 10,
    idleTimeout = 300000
  )
  log_info("数据库连接池创建成功")
}, error = function(e) {
  log_error(sprintf("数据库连接池创建失败: %s", e$message))
  log_warn("系统将在无数据库模式下运行（仅用于界面测试）")
})

# 确保应用退出时关闭连接池
onStop(function() {
  if (!is.null(db_pool)) {
    tryCatch({
      poolClose(db_pool)
      log_info("数据库连接池关闭成功")
    }, error = function(e) {
      log_error(sprintf("数据库连接池关闭错误: %s", e$message))
    })
  }
})

# ==================== 全局常量配置 ====================

# 应用版本
APP_VERSION <- "1.0.0"
APP_NAME <- "科研项目管理系统"

# 调试模式（TRUE时不启用登录功能）
DEBUG_MODE <- TRUE

# 项目类型映射（中文 -> 拼音缩写）
PROJECT_TYPE_CODES <- list(
  "基础研究" = "JC",
  "应用研究" = "YY",
  "临床研究" = "LC",
  "数据项目" = "SJ",
  "资源项目" = "ZY"
)

# 项目状态列表
PROJECT_STATUSES <- c(
  "规划中" = "planning",
  "进行中" = "in_progress",
  "暂停" = "on_hold",
  "已完成" = "completed",
  "已取消" = "cancelled"
)

# 优先级列表
PRIORITY_LEVELS <- c(
  "高" = "high",
  "中" = "medium",
  "低" = "low"
)

# 研究阶段列表
RESEARCH_STAGES <- c(
  "立项阶段" = "initiation",
  "实施阶段" = "implementation",
  "中期评估" = "mid_term",
  "结题阶段" = "closing",
  "已结题" = "completed"
)

# 研究领域列表（多选）
RESEARCH_FIELDS <- c(
  "基础医学",
  "临床医学",
  "公共卫生",
  "药学",
  "生物医学工程",
  "护理学",
  "中医学",
  "其他"
)

# 合作类型列表
COLLABORATION_TYPES <- c(
  "独立研究" = "independent",
  "院内合作" = "internal",
  "院外合作" = "external",
  "国际合作" = "international"
)

# 人员角色列表
RESEARCHER_ROLES <- c(
  "项目负责人" = "principal_investigator",
  "项目经理" = "project_manager",
  "合作研究者" = "co_investigator",
  "研究员" = "researcher",
  "助理" = "assistant"
)

# 用户角色列表
USER_ROLES <- c(
  "管理员" = "admin",
  "项目经理" = "manager",
  "分析员" = "analyst",
  "查看者" = "viewer"
)

# 日期格式
DATE_FORMAT <- "%Y-%m-%d"

# 分页设置
DEFAULT_PAGE_LENGTH <- 10
PAGE_LENGTH_OPTIONS <- c(10, 25, 50, 100)

# ==================== 辅助函数 ====================

# 安全的数据库查询函数
safe_query <- function(query, params = NULL) {
  if (is.null(db_pool)) {
    log_warn("数据库连接不可用，返回空结果")
    return(data.frame())
  }
  
  tryCatch({
    if (!is.null(params)) {
      result <- dbGetQuery(db_pool, query, params = params)
    } else {
      result <- dbGetQuery(db_pool, query)
    }
    return(result)
  }, error = function(e) {
    log_error(sprintf("数据库查询错误: %s", e$message))
    return(data.frame())
  })
}

# 安全的数据库执行函数
safe_execute <- function(query, params = NULL) {
  if (is.null(db_pool)) {
    log_warn("数据库连接不可用")
    return(FALSE)
  }
  
  tryCatch({
    if (!is.null(params)) {
      dbExecute(db_pool, query, params = params)
    } else {
      dbExecute(db_pool, query)
    }
    return(TRUE)
  }, error = function(e) {
    log_error(sprintf("数据库执行错误: %s", e$message))
    return(FALSE)
  })
}

# 格式化日期显示
format_date <- function(date_value) {
  if (is.null(date_value) || is.na(date_value)) {
    return("")
  }
  format(as.Date(date_value), DATE_FORMAT)
}

# 格式化金额显示
format_currency <- function(amount) {
  if (is.null(amount) || is.na(amount)) {
    return("¥0.00")
  }
  sprintf("¥%.2f", as.numeric(amount))
}

# 计算项目周期（天数）
calculate_duration <- function(start_date, end_date) {
  if (is.null(start_date) || is.null(end_date) || is.na(start_date) || is.na(end_date)) {
    return(NA)
  }
  as.integer(difftime(as.Date(end_date), as.Date(start_date), units = "days"))
}

# 检查项目是否即将到期（30天内）
is_project_due_soon <- function(end_date, threshold_days = 30) {
  if (is.null(end_date) || is.na(end_date)) {
    return(FALSE)
  }
  days_remaining <- as.integer(difftime(as.Date(end_date), Sys.Date(), units = "days"))
  return(days_remaining <= threshold_days && days_remaining >= 0)
}

# SHA-256密码哈希函数
hash_password <- function(password) {
  digest(password, algo = "sha256", serialize = FALSE)
}

# 验证密码
verify_password <- function(password, hash) {
  hash_password(password) == hash
}

log_info("全局配置加载完成")
