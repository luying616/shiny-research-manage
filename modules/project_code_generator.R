# ==================== 项目编号生成器 ====================
# 功能：自动生成项目编号
# 格式：类型-年份-序号[-优先级]
# 示例：JC-2026-001-H（基础研究-2026年-001号-高优先级）
# 文件：modules/project_code_generator.R
# ========================================================

# ==================== 项目编号生成函数 ====================
generate_project_code <- function(
  project_type,
  priority = NULL,
  year = NULL,
  use_monthly = FALSE,
  db_pool = NULL
) {
  # 获取年份
  if (is.null(year)) {
    year <- format(Sys.Date(), "%Y")
  }
  
  # 获取类型代码
  type_code <- PROJECT_TYPE_CODES[[project_type]]
  if (is.null(type_code)) {
    type_code <- "UNKN"
    log_warn(sprintf("未知的项目类型: %s，使用默认代码 UNKN", project_type))
  }
  
  # 获取序列号
  sequence_num <- get_next_sequence(
    type_code = type_code,
    year = year,
    use_monthly = use_monthly,
    db_pool = db_pool
  )
  
  # 构建基础编号
  if (use_monthly) {
    month <- format(Sys.Date(), "%m")
    base_code <- sprintf("%s-%s%s-%03d", type_code, year, month, sequence_num)
  } else {
    base_code <- sprintf("%s-%s-%03d", type_code, year, sequence_num)
  }
  
  # 添加优先级后缀
  if (!is.null(priority) && priority != "") {
    priority_suffix <- switch(
      priority,
      "high" = "H",
      "medium" = "M",
      "low" = "L",
      ""
    )
    
    if (priority_suffix != "") {
      base_code <- paste0(base_code, "-", priority_suffix)
    }
  }
  
  log_info(sprintf("生成项目编号: %s", base_code))
  return(base_code)
}

# ==================== 获取下一个序列号 ====================
get_next_sequence <- function(
  type_code,
  year,
  use_monthly = FALSE,
  db_pool = NULL
) {
  # 如果有数据库连接，尝试从数据库获取序列号
  if (!is.null(db_pool)) {
    sequence_num <- get_sequence_from_db(
      type_code = type_code,
      year = year,
      use_monthly = use_monthly,
      db_pool = db_pool
    )
    
    if (!is.null(sequence_num)) {
      return(sequence_num)
    }
  }
  
  # 如果没有数据库或查询失败，使用本地备用生成器
  log_warn("使用本地序列号生成器（备用方案）")
  return(get_local_sequence(type_code, year, use_monthly))
}

# ==================== 从数据库获取序列号 ====================
get_sequence_from_db <- function(type_code, year, use_monthly, db_pool) {
  tryCatch({
    # 构建查询条件
    if (use_monthly) {
      month <- format(Sys.Date(), "%m")
      pattern <- sprintf("%s-%s%s-%%", type_code, year, month)
    } else {
      pattern <- sprintf("%s-%s-%%", type_code, year)
    }
    
    # 查询最大序列号
    query <- "
      SELECT project_code
      FROM projects.projects
      WHERE project_code LIKE $1
      ORDER BY project_code DESC
      LIMIT 1
    "
    
    result <- dbGetQuery(db_pool, query, params = list(pattern))
    
    if (nrow(result) > 0) {
      # 提取序列号
      last_code <- result$project_code[1]
      sequence_part <- extract_sequence_number(last_code)
      return(sequence_part + 1)
    } else {
      # 没有找到记录，从1开始
      return(1)
    }
  }, error = function(e) {
    log_error(sprintf("从数据库获取序列号失败: %s", e$message))
    return(NULL)
  })
}

# ==================== 本地序列号生成器（备用） ====================
get_local_sequence <- function(type_code, year, use_monthly) {
  # 使用环境变量存储序列号计数器
  counter_name <- if (use_monthly) {
    month <- format(Sys.Date(), "%m")
    sprintf("seq_%s_%s%s", type_code, year, month)
  } else {
    sprintf("seq_%s_%s", type_code, year)
  }
  
  # 从全局环境获取或初始化计数器
  if (!exists(counter_name, envir = .GlobalEnv)) {
    assign(counter_name, 1, envir = .GlobalEnv)
    return(1)
  } else {
    current_count <- get(counter_name, envir = .GlobalEnv)
    new_count <- current_count + 1
    assign(counter_name, new_count, envir = .GlobalEnv)
    return(new_count)
  }
}

# ==================== 从编号中提取序列号 ====================
extract_sequence_number <- function(project_code) {
  # 匹配模式：类型-年份-序号 或 类型-年月-序号
  # 例如：JC-2026-001 或 JC-202601-001 或 JC-2026-001-H
  
  # 移除可能的优先级后缀
  code_without_priority <- sub("-[HML]$", "", project_code)
  
  # 提取最后一个破折号后的数字
  parts <- strsplit(code_without_priority, "-")[[1]]
  if (length(parts) >= 3) {
    sequence_str <- parts[length(parts)]
    return(as.integer(sequence_str))
  }
  
  return(0)
}

# ==================== 验证项目编号唯一性 ====================
validate_project_code_unique <- function(project_code, db_pool = NULL) {
  if (is.null(db_pool)) {
    log_warn("无法验证项目编号唯一性：数据库连接不可用")
    return(TRUE)
  }
  
  tryCatch({
    query <- "
      SELECT COUNT(*) as count
      FROM projects.projects
      WHERE project_code = $1
    "
    
    result <- dbGetQuery(db_pool, query, params = list(project_code))
    return(result$count[1] == 0)
  }, error = function(e) {
    log_error(sprintf("验证项目编号唯一性失败: %s", e$message))
    return(TRUE)  # 出错时假设唯一
  })
}

# ==================== 重新生成项目编号 ====================
regenerate_project_code <- function(
  project_type,
  priority = NULL,
  year = NULL,
  use_monthly = FALSE,
  db_pool = NULL,
  max_attempts = 10
) {
  for (attempt in 1:max_attempts) {
    new_code <- generate_project_code(
      project_type = project_type,
      priority = priority,
      year = year,
      use_monthly = use_monthly,
      db_pool = db_pool
    )
    
    if (validate_project_code_unique(new_code, db_pool)) {
      return(new_code)
    }
    
    log_warn(sprintf("项目编号 %s 已存在，尝试重新生成 (尝试 %d/%d)", new_code, attempt, max_attempts))
  }
  
  # 如果多次尝试失败，添加随机后缀
  random_suffix <- sample(1000:9999, 1)
  return(sprintf("%s-R%d", new_code, random_suffix))
}

# ==================== 批量生成项目编号 ====================
batch_generate_codes <- function(
  count,
  project_type,
  priority = NULL,
  year = NULL,
  use_monthly = FALSE,
  db_pool = NULL
) {
  codes <- character(count)
  
  for (i in 1:count) {
    codes[i] <- regenerate_project_code(
      project_type = project_type,
      priority = priority,
      year = year,
      use_monthly = use_monthly,
      db_pool = db_pool
    )
  }
  
  return(codes)
}

# ==================== 解析项目编号 ====================
parse_project_code <- function(project_code) {
  # 解析项目编号，返回各个组成部分
  parts <- strsplit(project_code, "-")[[1]]
  
  if (length(parts) < 3) {
    return(list(
      valid = FALSE,
      message = "项目编号格式无效"
    ))
  }
  
  type_code <- parts[1]
  year_part <- parts[2]
  sequence_part <- parts[3]
  
  # 检查是否包含优先级
  priority_code <- NULL
  if (length(parts) == 4) {
    priority_code <- parts[4]
  }
  
  # 检查是否使用月度编号
  use_monthly <- nchar(year_part) == 6
  
  if (use_monthly) {
    year <- substr(year_part, 1, 4)
    month <- substr(year_part, 5, 6)
  } else {
    year <- year_part
    month <- NULL
  }
  
  return(list(
    valid = TRUE,
    type_code = type_code,
    year = year,
    month = month,
    sequence = as.integer(sequence_part),
    priority = priority_code,
    use_monthly = use_monthly
  ))
}

log_info("项目编号生成器模块加载完成")
