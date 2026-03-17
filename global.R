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


# ==================== 全局配置 ====================
# 提供项目类型和状态的映射到 ID 的函数

# 静态映射：项目类型
match_project_type_id <- function(type_name) {
  PROJECT_TYPES <- c(
    "基础研究" = 1,
    "应用研究" = 2,
    "数据项目" = 3,
    "资源项目" = 4,
    "临床研究" = 5
  )
  
  type_id <- PROJECT_TYPES[type_name]
  
  if (is.na(type_id)) {
    stop(sprintf("未知的项目类型：'%s'", type_name))
  }
  
  return(type_id)
}

# 静态映射：项目状态
match_status_id <- function(status_name) {
  PROJECT_STATUSES <- c(
    "规划中" = 1,
    "进行中" = 2,
    "已暂停" = 3,
    "已完成" = 4,
    "已取消" = 5
  )
  
  status_id <- PROJECT_STATUSES[status_name]
  
  if (is.na(status_id)) {
    stop(sprintf("未知的项目状态：'%s'", status_name))
  }
  
  return(status_id)
}

# 回退动态方式（根据需要从数据库中动态读取，适合频繁更新状态或项目类型）
# 动态查询项目类型 ID
fetch_projects_from_db <- function(db_pool, query) {
  tryCatch({
    dbGetQuery(db_pool, query)
  }, error = function(e) {
    log_error(sprintf("查询数据库失败: %s", e$message))
    NULL
  })
}

# 动态查询项目类型到 ID 的映射
match_project_type_id_from_db <- function(type_name, db_pool) {
  query <- "SELECT type_name, type_id FROM projects.project_types"
  project_types <- fetch_projects_from_db(db_pool, query)
  
  if (is.null(project_types)) {
    stop("无法从数据库加载项目类型数据")
  }
  
  type_id <- project_types$type_id[project_types$type_name == type_name]
  
  if (length(type_id) == 0) {
    stop(sprintf("未知的项目类型：'%s'", type_name))
  }
  
  return(type_id)
}

# 动态查询项目状态到 ID 的映射
match_status_id_from_db <- function(status_name, db_pool) {
  query <- "SELECT status_name, status_id FROM projects.project_statuses"
  statuses <- fetch_projects_from_db(db_pool, query)
  
  if (is.null(statuses)) {
    stop("无法从数据库加载项目状态数据")
  }
  
  status_id <- statuses$status_id[statuses$status_name == status_name]
  
  if (length(status_id) == 0) {
    stop(sprintf("未知的项目状态：'%s'", status_name))
  }
  
  return(status_id)
}

# 附件相关配置
NFS_BASE_PATH <- "/mnt/nfs/project_documents"  # NFS挂载点
LOCAL_TEMP_PATH <- "/tmp/project_uploads"  # 本地临时目录
MAX_FILE_SIZE <- 50 * 1024 * 1024  # 50MB最大文件大小

# 文档类型分类
DOCUMENT_TYPES <- c(
  "research_proposal" = "研究方案",
  "ethics_approval" = "伦理批件",
  "contract" = "合同",
  "protocol" = "试验方案",
  "report" = "报告",
  "publication" = "发表论文",
  "presentation" = "演示文稿",
  "data_file" = "数据文件",
  "analysis" = "分析结果",
  "other" = "其他文档"
)

# 允许的文件类型扩展
ALLOWED_FILE_TYPES <- list(
  pdf = c("application/pdf"),
  doc = c("application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
  xls = c("application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
  ppt = c("application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"),
  image = c("image/jpeg", "image/png", "image/gif", "image/bmp", "image/tiff"),
  text = c("text/plain", "text/csv"),
  zip = c("application/zip", "application/x-rar-compressed", "application/x-7z-compressed"),
  data = c("application/json", "application/xml")
)

# 预算类别
BUDGET_CATEGORIES <- c(
  "personnel" = "人员费用",
  "equipment" = "设备购置",
  "consumables" = "实验耗材",
  "travel" = "差旅会议",
  "publication" = "论文发表",
  "other" = "其他费用"
)

# 创建必要的目录
dir.create(LOCAL_TEMP_PATH, showWarnings = FALSE, recursive = TRUE)
dir.create(NFS_BASE_PATH, showWarnings = FALSE, recursive = TRUE)

# 附件相关函数
format_file_size <- function(bytes) {
  if (is.na(bytes) || bytes <= 0) return("0 B")
  
  units <- c("B", "KB", "MB", "GB", "TB")
  for (i in 1:5) {
    if (bytes < 1024^i) {
      value <- bytes / 1024^(i-1)
      if (value < 10) {
        return(sprintf("%.1f %s", value, units[i]))
      } else {
        return(sprintf("%.0f %s", round(value), units[i]))
      }
    }
  }
  return(sprintf("%.1f TB", bytes/1024^4))
}

# 生成安全的文件名
generate_safe_filename <- function(original_filename) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  random_str <- paste0(sample(c(letters, 0:9), 6), collapse = "")
  extension <- tolower(tools::file_ext(original_filename))
  name_without_ext <- tools::file_path_sans_ext(basename(original_filename))
  
  # 清理文件名
  safe_name <- gsub("[^a-zA-Z0-9\u4e00-\u9fa5_-]", "_", name_without_ext)
  safe_name <- gsub("_{2,}", "_", safe_name)  # 移除连续下划线
  safe_name <- substr(safe_name, 1, 100)  # 限制长度
  
  if (safe_name == "") {
    safe_name <- "file"
  }
  
  return(paste0(safe_name, "_", timestamp, "_", random_str, ".", extension))
}

# 获取文件图标类型
get_file_icon <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  
  switch(ext,
         pdf = "file-pdf",
         doc = "file-word",
         docx = "file-word",
         xls = "file-excel",
         xlsx = "file-excel",
         ppt = "file-powerpoint",
         pptx = "file-powerpoint",
         jpg = "file-image",
         jpeg = "file-image",
         png = "file-image",
         gif = "file-image",
         zip = "file-archive",
         rar = "file-archive",
         txt = "file-alt",
         csv = "file-csv",
         "file"
  )
}

# 获取文件类型颜色
get_file_color <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  
  switch(ext,
         pdf = "danger",
         doc = "primary",
         docx = "primary",
         xls = "success",
         xlsx = "success",
         ppt = "warning",
         pptx = "warning",
         jpg = "info",
         jpeg = "info",
         png = "info",
         gif = "info",
         "secondary"
  )
}