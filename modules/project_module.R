# ==================== 项目管理模块 ====================
# 功能：项目的创建、编辑、查看、删除等CRUD操作
# 文件：modules/project_module.R
# =====================================================

# ==================== 项目管理模块 UI ====================
project_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 样式定义（已移至www/style.css）
    
    # 操作按钮行
    fluidRow(
      column(
        width = 12,
        div(
          style = "margin-bottom: 20px; display: flex; gap: 10px;",
          actionButton(
            inputId = ns("create_project_btn"),
            label = tagList(icon("plus"), "创建新项目"),
            class = "btn-primary"
          ),
          actionButton(
            inputId = ns("refresh_list_btn"),
            label = tagList(icon("sync-alt"), "刷新"),
            class = "btn-info"
          ),
          # 调试按钮
          actionButton(
            inputId = ns("debug_btn"),
            label = tagList(icon("bug"), "调试"),
            class = "btn-warning",
            onclick = sprintf("
          console.log('Shiny inputs:');
          console.log('view_project:', Shiny.shinyapp.$inputValues['%s']);
          console.log('edit_project:', Shiny.shinyapp.$inputValues['%s']);
          console.log('manage_attachments:', Shiny.shinyapp.$inputValues['%s']);
          console.log('delete_project:', Shiny.shinyapp.$inputValues['%s']);
        ", ns("view_project"), ns("edit_project"), ns("manage_attachments"), ns("delete_project"))
          ),
          div(
            style = "margin-left: auto; display: flex; gap: 10px;",
            downloadButton(
              outputId = ns("export_csv_btn"),
              label = tagList(icon("file-csv"), "CSV"),
              class = "btn-success"
            ),
            downloadButton(
              outputId = ns("export_excel_btn"),
              label = tagList(icon("file-excel"), "Excel"),
              class = "btn-success"
            )
          )
        )
      )
    ),
    
    # 筛选面板
    fluidRow(
      column(
        width = 12,
        div(
          class = "box box-primary collapsed-box",
          div(
            class = "box-header with-border",
            h3(
              class = "box-title",
              tagList(icon("filter"), "筛选条件"),
              tags$span(
                class = "pull-right",
                tags$button(
                  class = "btn btn-box-tool",
                  `data-widget` = "collapse",
                  tags$i(class = "fa fa-plus")
                )
              )
            )
          ),
          div(
            class = "box-body",
            style = "display: none;",
            fluidRow(
              column(
                width = 3,
                selectInput(
                  inputId = ns("filter_type"),
                  label = "项目类型",
                  choices = c("全部" = "", names(PROJECT_TYPE_CODES)),
                  selected = ""
                )
              ),
              column(
                width = 3,
                selectInput(
                  inputId = ns("filter_status"),
                  label = "项目状态",
                  choices = c("全部" = "", names(PROJECT_STATUSES)),
                  selected = ""
                )
              ),
              column(
                width = 3,
                selectInput(
                  inputId = ns("filter_priority"),
                  label = "优先级",
                  choices = c("全部" = "", names(PRIORITY_LEVELS)),
                  selected = ""
                )
              ),
              column(
                width = 3,
                textInput(
                  inputId = ns("filter_keyword"),
                  label = "关键词搜索",
                  placeholder = "项目名称、编号..."
                )
              )
            ),
            fluidRow(
              column(
                width = 3,
                dateInput(
                  inputId = ns("filter_start_date_from"),
                  label = "开始日期（从）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              ),
              column(
                width = 3,
                dateInput(
                  inputId = ns("filter_start_date_to"),
                  label = "开始日期（到）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              ),
              column(
                width = 3,
                dateInput(
                  inputId = ns("filter_end_date_from"),
                  label = "结束日期（从）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              ),
              column(
                width = 3,
                dateInput(
                  inputId = ns("filter_end_date_to"),
                  label = "结束日期（到）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              )
            ),
            fluidRow(
              column(
                width = 12,
                style = "text-align: center; margin-top: 20px;",
                actionButton(
                  inputId = ns("apply_filter_btn"),
                  label = tagList(icon("search"), "应用筛选"),
                  class = "btn-primary",
                  style = "margin-right: 10px;"
                ),
                actionButton(
                  inputId = ns("reset_filter_btn"),
                  label = tagList(icon("times"), "重置筛选"),
                  class = "btn-default"
                )
              )
            )
          )
        )
      )
    ),
    
    # 项目列表表格
    fluidRow(
      column(
        width = 12,
        div(
          class = "box box-primary",
          div(
            class = "box-header with-border",
            h3(class = "box-title", tagList(icon("list"), "项目列表")),
            div(
              class = "box-tools pull-right",
              tags$span(
                id = ns("total_count"),
                style = "margin-right: 20px; font-weight: bold; color: #666;"
              )
            )
          ),
          div(
            class = "box-body",
            div(
              style = "overflow-x: auto;",
              DTOutput(ns("projects_table"))
            )
          )
        )
      )
    ),
    
    # 查看项目详情模态框
    uiOutput(ns("project_detail_modal")),
    
    # 删除确认模态框
    uiOutput(ns("delete_confirm_modal"))
  )
}

# ==================== 项目管理模块 Server ====================
# ==================== 项目管理模块 Server ====================
project_module_server <- function(id, db_pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 项目数据
    projects_data <- reactiveVal(NULL)
    
    # 当前选择的项目ID
    selected_project_id <- reactiveVal(NULL)
    
    # 加载项目数据
    load_projects <- function(filters = NULL) {
      if (is.null(db_pool)) {
        log_error("数据库连接不可用，无法加载项目数据")
        showNotification("数据库连接失败，请检查数据库配置", type = "error")
        return(NULL)
      }
      
      tryCatch({
        # 构建查询
        query <- "
          SELECT 
            p.project_id,
            p.project_code,
            p.project_name,
            pt.type_name as project_type,
            rs.stage_name as research_stage,
            p.priority_level,
            p.budget,
            p.start_date,
            p.end_date,
            ps.status_name as status,
            p.description,
            p.created_at,
            p.updated_at,
            u.username as created_by
          FROM projects.projects p
          LEFT JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          LEFT JOIN projects.research_stages rs ON p.research_stage_id = rs.stage_id
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          LEFT JOIN auth.users u ON p.created_by = u.user_id
          WHERE p.is_active = TRUE
        "
        
        # 应用筛选条件
        conditions <- c()
        params <- list()
        param_index <- 1
        
        if (!is.null(filters)) {
          # 项目类型筛选
          if (!is.null(filters$type) && filters$type != "") {
            conditions <- c(conditions, sprintf("pt.type_name = $%d", param_index))
            params[[param_index]] <- filters$type
            param_index <- param_index + 1
          }
          
          # 状态筛选
          if (!is.null(filters$status) && filters$status != "") {
            conditions <- c(conditions, sprintf("ps.status_name = $%d", param_index))
            params[[param_index]] <- filters$status
            param_index <- param_index + 1
          }
          
          # 优先级筛选
          if (!is.null(filters$priority) && filters$priority != "") {
            conditions <- c(conditions, sprintf("p.priority_level = $%d", param_index))
            params[[param_index]] <- filters$priority
            param_index <- param_index + 1
          }
          
          # 关键词搜索
          if (!is.null(filters$keyword) && trimws(filters$keyword) != "") {
            keyword <- trimws(filters$keyword)
            conditions <- c(conditions, sprintf("(p.project_name ILIKE $%d OR p.project_code ILIKE $%d)", 
                                                param_index, param_index + 1))
            params[[param_index]] <- paste0("%", keyword, "%")
            params[[param_index + 1]] <- paste0("%", keyword, "%")
            param_index <- param_index + 2
          }
          
          # 开始日期范围筛选
          if (!is.null(filters$start_date_from)) {
            conditions <- c(conditions, sprintf("p.start_date >= $%d", param_index))
            params[[param_index]] <- filters$start_date_from
            param_index <- param_index + 1
          }
          if (!is.null(filters$start_date_to)) {
            conditions <- c(conditions, sprintf("p.start_date <= $%d", param_index))
            params[[param_index]] <- filters$start_date_to
            param_index <- param_index + 1
          }
          
          # 结束日期范围筛选
          if (!is.null(filters$end_date_from)) {
            conditions <- c(conditions, sprintf("p.end_date >= $%d", param_index))
            params[[param_index]] <- filters$end_date_from
            param_index <- param_index + 1
          }
          if (!is.null(filters$end_date_to)) {
            conditions <- c(conditions, sprintf("p.end_date <= $%d", param_index))
            params[[param_index]] <- filters$end_date_to
            param_index <- param_index + 1
          }
        }
        
        # 添加WHERE条件
        if (length(conditions) > 0) {
          query <- paste(query, "AND", paste(conditions, collapse = " AND "))
        }
        
        query <- paste(query, "ORDER BY p.priority_level DESC, p.created_at DESC")
        
        # 执行查询
        log_info(sprintf("执行SQL查询: %s", query))
        
        if (length(params) > 0) {
          log_info(sprintf("查询参数: %s", paste(names(params), "=", params, collapse = ", ")))
          projects <- dbGetQuery(db_pool, query, params = params)
        } else {
          projects <- dbGetQuery(db_pool, query)
        }
        
        log_info(sprintf("成功从数据库加载 %d 条项目记录", nrow(projects)))
        return(projects)
      }, error = function(e) {
        log_error(sprintf("加载项目数据失败: %s", e$message))
        showNotification(paste("加载项目数据失败:", e$message), type = "error")
        return(NULL)
      })
    }
    
    # 生成项目编号
    generate_project_code <- function(project_type) {
      type_code <- PROJECT_TYPE_CODES[[project_type]]
      year <- format(Sys.Date(), "%Y")
      month <- format(Sys.Date(), "%m")
      
      tryCatch({
        # 查询该类型下当月的最大序列号
        query <- "
          SELECT MAX(CAST(SPLIT_PART(project_code, '-', -1) AS INTEGER)) as max_seq
          FROM projects.projects 
          WHERE project_code LIKE $1
            AND EXTRACT(YEAR FROM created_at) = $2
            AND EXTRACT(MONTH FROM created_at) = $3
        "
        
        pattern <- paste0(type_code, "-", year, "-", month, "-%")
        result <- dbGetQuery(db_pool, query, params = list(pattern, as.numeric(year), as.numeric(month)))
        
        # 确定下一个序列号
        if (!is.null(result$max_seq) && !is.na(result$max_seq)) {
          seq_num <- sprintf("%04d", result$max_seq + 1)
        } else {
          seq_num <- "0001"
        }
        
        return(paste(type_code, year, month, seq_num, sep = "-"))
      }, error = function(e) {
        # 如果查询失败，生成随机序列号
        log_warn(sprintf("生成项目编号查询失败: %s，使用随机序列号", e$message))
        seq_num <- sprintf("%04d", sample(1:1000, 1))
        return(paste(type_code, year, month, seq_num, sep = "-"))
      })
    }
    
    # 获取项目详情
    get_project_details <- function(project_id) {
      if (is.null(db_pool)) {
        log_error("数据库连接不可用，无法获取项目详情")
        return(NULL)
      }
      
      tryCatch({
        query <- "
          SELECT 
            p.*,
            pt.type_name,
            ps.status_name,
            rs.stage_name,
            u.username as created_by_name
          FROM projects.projects p
          LEFT JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          LEFT JOIN projects.research_stages rs ON p.research_stage_id = rs.stage_id
          LEFT JOIN auth.users u ON p.created_by = u.user_id
          WHERE p.project_id = $1 AND p.is_active = TRUE
        "
        
        result <- dbGetQuery(db_pool, query, params = list(project_id))
        
        if (nrow(result) == 0) {
          log_warn(sprintf("未找到项目ID为 %d 的活动项目", project_id))
          return(NULL)
        }
        
        log_info(sprintf("成功获取项目ID %d 的详细信息", project_id))
        return(result)
      }, error = function(e) {
        log_error(sprintf("获取项目详情失败: %s", e$message))
        showNotification("获取项目详情失败", type = "error")
        return(NULL)
      })
    }
    
    # 初始加载
    observe({
      data <- load_projects()
      projects_data(data)
    })
    
    # 应用筛选
    observeEvent(input$apply_filter_btn, {
      filters <- list(
        type = input$filter_type,
        status = input$filter_status,
        priority = input$filter_priority,
        keyword = input$filter_keyword,
        start_date_from = input$filter_start_date_from,
        start_date_to = input$filter_start_date_to,
        end_date_from = input$filter_end_date_from,
        end_date_to = input$filter_end_date_to
      )
      data <- load_projects(filters)
      projects_data(data)
      
      if (!is.null(data) && nrow(data) > 0) {
        showNotification(sprintf("已筛选出 %d 个项目", nrow(data)), type = "message")
        log_info(sprintf("应用筛选条件，找到 %d 个项目", nrow(data)))
      } else {
        showNotification("未找到符合条件的项目", type = "warning")
        log_info("应用筛选条件，未找到匹配的项目")
      }
    })
    
    # 重置筛选
    observeEvent(input$reset_filter_btn, {
      updateSelectInput(session, "filter_type", selected = "")
      updateSelectInput(session, "filter_status", selected = "")
      updateSelectInput(session, "filter_priority", selected = "")
      updateTextInput(session, "filter_keyword", value = "")
      updateDateInput(session, "filter_start_date_from", value = NULL)
      updateDateInput(session, "filter_start_date_to", value = NULL)
      updateDateInput(session, "filter_end_date_from", value = NULL)
      updateDateInput(session, "filter_end_date_to", value = NULL)
      
      data <- load_projects()
      projects_data(data)
      showNotification("筛选已重置", type = "message")
      log_info("项目筛选条件已重置")
    })
    
    # 刷新列表
    observeEvent(input$refresh_list_btn, {
      data <- load_projects()
      projects_data(data)
      showNotification("列表已刷新", type = "message")
      log_info(sprintf("项目列表已刷新，共 %d 条记录", 
                       ifelse(!is.null(data) && nrow(data) > 0, nrow(data), 0)))
    })
    
    # 创建新项目
    observeEvent(input$create_project_btn, {
      showModal(create_project_modal(ns))
    })
    
    # 确认创建项目
    observeEvent(input$confirm_create, {
      # 验证输入
      if (is.null(input$new_project_name) || trimws(input$new_project_name) == "") {
        showNotification("项目名称不能为空！", type = "error")
        return()
      }
      
      # 从用户输入中读取优先级，并映射成英文值
      priority <- PRIORITY_LEVELS[[trimws(input$new_priority)]]
      
      # 验证映射后的优先级
      if (is.null(priority) || length(priority) == 0) {
        showNotification("请选择有效的优先级！", type = "error")
        return()
      }
      
      # 映射项目状态
      status_code <- PROJECT_STATUSES[[input$new_status]]
      
      # 生成或使用用户输入的项目编号
      project_code <- ifelse(
        input$new_project_code == "", 
        generate_project_code(input$new_project_type), 
        input$new_project_code
      )
      
      # 准备项目数据
      new_project <- list(
        name = trimws(input$new_project_name),
        code = project_code,
        type = input$new_project_type,
        priority = priority,
        start_date = input$new_start_date,
        end_date = input$new_end_date,
        budget = input$new_budget,
        status = status_code,
        description = trimws(input$new_description)
      )
      
      # 验证结束日期是否晚于开始日期
      if (new_project$end_date <= new_project$start_date) {
        showNotification("结束日期必须晚于开始日期！", type = "error")
        return()
      }
      
      # 尝试向数据库插入项目数据
      tryCatch({
        # 首先获取类型ID和状态ID
        type_id <- dbGetQuery(
          db_pool, 
          "SELECT type_id FROM projects.project_types WHERE type_name = $1",
          params = list(new_project$type)
        )$type_id
        
        if (is.null(type_id)) {
          showNotification("项目类型不存在，请检查配置", type = "error")
          return()
        }
        
        status_id <- dbGetQuery(
          db_pool, 
          "SELECT status_id FROM projects.project_statuses WHERE status_name = $1",
          params = list(input$new_status)
        )$status_id
        
        if (is.null(status_id)) {
          showNotification("项目状态不存在，请检查配置", type = "error")
          return()
        }
        
        # 检查项目编号是否已存在
        existing_code <- dbGetQuery(
          db_pool,
          "SELECT project_id FROM projects.projects WHERE project_code = $1 AND is_active = TRUE",
          params = list(new_project$code)
        )
        
        if (nrow(existing_code) > 0) {
          showNotification("项目编号已存在，请使用其他编号", type = "error")
          return()
        }
        
        # 插入项目数据
        dbExecute(db_pool, "
          INSERT INTO projects.projects 
          (project_name, project_code, project_type_id, priority_level, 
           start_date, end_date, budget, status_id, description, created_by)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        ", params = list(
          new_project$name,
          new_project$code,
          type_id,
          new_project$priority,
          new_project$start_date,
          new_project$end_date,
          new_project$budget,
          status_id,
          new_project$description,
          1  # 假设当前用户是admin，实际应用中应该从session获取
        ))
        
        showNotification("项目创建成功！", type = "message")
        removeModal()
        
        # 刷新数据
        data <- load_projects()
        projects_data(data)
        
        log_info(sprintf("新项目创建成功: %s (%s)", new_project$name, new_project$code))
      }, error = function(e) {
        error_msg <- sprintf("创建失败: %s", e$message)
        showNotification(error_msg, type = "error")
        log_error(sprintf("数据库插入失败: %s", e$message))
      })
    })
    
    # 查看项目详情
    observeEvent(input$view_project, {
      req(input$view_project)
      project_id <- input$view_project
      
      if (!is.null(project_id) && project_id > 0) {
        log_info(sprintf("查看项目按钮点击，ID: %d", project_id))
        selected_project_id(project_id)
        
        # 获取项目详情
        project_details <- get_project_details(project_id)
        
        if (!is.null(project_details) && nrow(project_details) > 0) {
          showModal(view_project_modal(ns, project_details))
        } else {
          showNotification("无法获取项目信息", type = "error")
        }
      }
    })
    
    # 编辑项目
    observeEvent(input$edit_project, {
      req(input$edit_project)
      project_id <- input$edit_project
      
      if (!is.null(project_id) && project_id > 0) {
        log_info(sprintf("编辑项目按钮点击，ID: %d", project_id))
        selected_project_id(project_id)
        
        # 获取项目当前信息
        project_data <- get_project_details(project_id)
        
        if (!is.null(project_data) && nrow(project_data) > 0) {
          showModal(edit_project_modal(ns, project_data))
        } else {
          showNotification("无法获取项目信息", type = "error")
        }
      }
    })
    
    # 确认编辑项目
    observeEvent(input$confirm_edit, {
      project_id <- selected_project_id()
      req(project_id)
      
      # 验证输入
      if (is.null(input$edit_project_name) || trimws(input$edit_project_name) == "") {
        showNotification("项目名称不能为空！", type = "error")
        return()
      }
      
      # 从用户输入中读取优先级，并映射成英文值
      priority <- PRIORITY_LEVELS[[trimws(input$edit_priority)]]
      
      # 验证映射后的优先级
      if (is.null(priority) || length(priority) == 0) {
        showNotification("请选择有效的优先级！", type = "error")
        return()
      }
      
      # 映射项目状态
      status_code <- PROJECT_STATUSES[[input$edit_status]]
      
      # 准备更新数据
      updated_project <- list(
        name = trimws(input$edit_project_name),
        code = trimws(input$edit_project_code),
        type = input$edit_project_type,
        priority = priority,
        start_date = input$edit_start_date,
        end_date = input$edit_end_date,
        budget = input$edit_budget,
        status = status_code,
        description = trimws(input$edit_description)
      )
      
      # 验证结束日期是否晚于开始日期
      if (updated_project$end_date <= updated_project$start_date) {
        showNotification("结束日期必须晚于开始日期！", type = "error")
        return()
      }
      
      tryCatch({
        # 首先获取类型ID和状态ID
        type_id <- dbGetQuery(
          db_pool, 
          "SELECT type_id FROM projects.project_types WHERE type_name = $1",
          params = list(updated_project$type)
        )$type_id
        
        if (is.null(type_id)) {
          showNotification("项目类型不存在，请检查配置", type = "error")
          return()
        }
        
        status_id <- dbGetQuery(
          db_pool, 
          "SELECT status_id FROM projects.project_statuses WHERE status_name = $1",
          params = list(input$edit_status)
        )$status_id
        
        if (is.null(status_id)) {
          showNotification("项目状态不存在，请检查配置", type = "error")
          return()
        }
        
        # 检查项目编号是否重复（排除当前项目）
        existing_code <- dbGetQuery(
          db_pool,
          "SELECT project_id FROM projects.projects WHERE project_code = $1 AND project_id != $2 AND is_active = TRUE",
          params = list(updated_project$code, project_id)
        )
        
        if (nrow(existing_code) > 0) {
          showNotification("项目编号已存在，请使用其他编号", type = "error")
          return()
        }
        
        # 更新项目数据
        dbExecute(db_pool, "
          UPDATE projects.projects 
          SET project_name = $1,
              project_code = $2,
              project_type_id = $3,
              priority_level = $4,
              start_date = $5,
              end_date = $6,
              budget = $7,
              status_id = $8,
              description = $9,
              updated_at = NOW()
          WHERE project_id = $10
        ", params = list(
          updated_project$name,
          updated_project$code,
          type_id,
          updated_project$priority,
          updated_project$start_date,
          updated_project$end_date,
          updated_project$budget,
          status_id,
          updated_project$description,
          project_id
        ))
        
        showNotification("项目更新成功！", type = "message")
        removeModal()
        
        # 刷新数据
        data <- load_projects()
        projects_data(data)
        
        log_info(sprintf("项目更新成功: %s (ID: %d)", updated_project$name, project_id))
      }, error = function(e) {
        error_msg <- sprintf("更新失败: %s", e$message)
        showNotification(error_msg, type = "error")
        log_error(sprintf("数据库更新失败: %s", e$message))
      })
    })
    
    # 删除项目
    observeEvent(input$delete_project, {
      req(input$delete_project)
      project_id <- input$delete_project
      
      if (!is.null(project_id) && project_id > 0) {
        log_info(sprintf("删除项目按钮点击，ID: %d", project_id))
        selected_project_id(project_id)
        
        # 获取项目名称用于确认
        project_data <- get_project_details(project_id)
        
        if (!is.null(project_data) && nrow(project_data) > 0) {
          showModal(delete_confirm_modal(ns, project_data[1, ]))
        } else {
          showNotification("无法获取项目信息", type = "error")
        }
      }
    })
    
    # 确认删除
    observeEvent(input$confirm_delete, {
      project_id <- selected_project_id()
      req(project_id)
      
      tryCatch({
        # 软删除：标记为不活跃
        dbExecute(
          db_pool,
          "UPDATE projects.projects SET is_active = FALSE, updated_at = NOW() WHERE project_id = $1",
          params = list(project_id)
        )
        
        showNotification("项目已删除", type = "message")
        removeModal()
        
        # 刷新数据
        data <- load_projects()
        projects_data(data)
        
        log_info(sprintf("项目删除成功，ID: %d", project_id))
      }, error = function(e) {
        error_msg <- sprintf("删除失败: %s", e$message)
        showNotification(error_msg, type = "error")
        log_error(sprintf("删除项目失败: %s", e$message))
      })
    })
    
    # 附件管理按钮点击事件
    observeEvent(input$manage_attachments, {
      req(input$manage_attachments)
      project_id <- input$manage_attachments
      
      if (!is.null(project_id) && project_id > 0) {
        log_info(sprintf("附件管理按钮点击，ID: %d", project_id))
        selected_project_id(project_id)
        
        # 获取项目详情
        project_data <- get_project_details(project_id)
        
        if (!is.null(project_data) && nrow(project_data) > 0) {
          showModal(attachments_management_modal(ns, project_data))
        } else {
          showNotification("无法获取项目信息", type = "error")
        }
      }
    })
    
    # 快速上传文件按钮
    observeEvent(input$quick_upload_file, {
      req(selected_project_id())
      project_id <- selected_project_id()
      
      project_data <- get_project_details(project_id)
      if (!is.null(project_data) && nrow(project_data) > 0) {
        showModal(quick_upload_modal(ns, project_data))
      }
    })
    
    # 快速添加链接
    observeEvent(input$quick_add_link, {
      req(selected_project_id())
      project_id <- selected_project_id()
      
      project_data <- get_project_details(project_id)
      if (!is.null(project_data) && nrow(project_data) > 0) {
        showModal(quick_link_modal(ns, project_data))
      }
    })
    
    # 快速添加评论
    observeEvent(input$quick_add_comment, {
      req(selected_project_id())
      project_id <- selected_project_id()
      
      project_data <- get_project_details(project_id)
      if (!is.null(project_data) && nrow(project_data) > 0) {
        showModal(quick_comment_modal(ns, project_data))
      }
    })
    
    # 刷新附件
    observeEvent(input$refresh_attachments, {
      # 这里可以添加刷新附件模块数据的逻辑
      # 如果使用独立的附件模块，可以调用其刷新函数
      showNotification("附件列表已刷新", type = "message")
      log_info("附件列表刷新")
    })
    
    # 关闭附件管理模态框
    observeEvent(input$close_attachments, {
      removeModal()
    })
    
    # 快速上传文件处理
    observeEvent(input$quick_file_input, {
      file <- input$quick_file_input
      if (!is.null(file)) {
        # 自动填充文档名称
        if (is.null(input$quick_doc_name) || trimws(input$quick_doc_name) == "") {
          updateTextInput(session, "quick_doc_name", 
                          value = tools::file_path_sans_ext(file$name))
        }
        shinyjs::enable("confirm_quick_upload")
      }
    })
    
    # 动态渲染上传选项
    output$quick_upload_options <- renderUI({
      file <- input$quick_file_input
      if (is.null(file)) return(NULL)
      
      div(
        style = "margin-top: 20px; text-align: left;",
        textInput(
          inputId = ns("quick_doc_name"),
          label = "文档名称",
          value = tools::file_path_sans_ext(file$name),
          width = "100%",
          placeholder = "请输入文档名称"
        ),
        selectInput(
          inputId = ns("quick_doc_type"),
          label = "文档类型",
          choices = list(
            "文档" = c("项目计划书" = "plan", "研究报告" = "report", "合同" = "contract"),
            "数据" = c("实验数据" = "data", "分析结果" = "analysis"),
            "其他" = c("图片" = "image", "其他" = "other")
          ),
          selected = "other",
          width = "100%"
        )
      )
    })
    
    # 显示快速上传文件信息
    output$quick_file_info <- renderUI({
      file <- input$quick_file_input
      if (is.null(file)) return(NULL)
      
      # 检查文件大小
      if (file$size > MAX_FILE_SIZE) {
        return(
          div(
            class = "alert alert-danger",
            icon("exclamation-triangle"),
            sprintf("文件大小超出限制 (%.1fMB > %.0fMB)", 
                    file$size/1024/1024, MAX_FILE_SIZE/1024/1024)
          )
        )
      }
      
      div(
        class = "alert alert-success",
        icon("check-circle"),
        strong("已选择文件: "), file$name, br(),
        strong("文件大小: "), format_file_size(file$size), br(),
        strong("文件类型: "), file$type
      )
    })
    
    # 确认快速上传
    observeEvent(input$confirm_quick_upload, {
      file <- input$quick_file_input
      if (is.null(file) || is.null(selected_project_id())) {
        showNotification("请选择文件", type = "warning")
        return()
      }
      
      tryCatch({
        # 生成安全的文件名
        safe_filename <- generate_safe_filename(file$name)
        
        # 创建项目目录
        project_dir <- file.path(NFS_BASE_PATH, selected_project_id())
        dir.create(project_dir, showWarnings = FALSE, recursive = TRUE)
        
        # 目标路径
        dest_path <- file.path(project_dir, safe_filename)
        
        # 复制文件到NFS
        file.copy(file$datapath, dest_path)
        
        # 获取文档名称
        doc_name <- trimws(input$quick_doc_name)
        if (doc_name == "") {
          doc_name <- tools::file_path_sans_ext(file$name)
        }
        
        # 插入数据库记录
        dbExecute(db_pool, "
          INSERT INTO projects.project_documents 
          (project_id, document_type, document_name, file_path, 
           file_size, mime_type, uploader_id)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
        ", params = list(
          selected_project_id(),
          input$quick_doc_type,
          doc_name,
          dest_path,
          file$size,
          file$type,
          1  # 当前用户ID
        ))
        
        # 清空表单
        shinyjs::reset("quick_file_input")
        updateTextInput(session, "quick_doc_name", value = "")
        shinyjs::disable("confirm_quick_upload")
        
        # 关闭模态框
        removeModal()
        
        showNotification("文件上传成功", type = "success")
        log_info(sprintf("快速上传成功: %s -> %s", file$name, dest_path))
        
      }, error = function(e) {
        showNotification(sprintf("上传失败: %s", e$message), type = "error")
        log_error(sprintf("快速上传失败: %s", e$message))
      })
    })
    
    # 取消快速上传
    observeEvent(input$cancel_quick_upload, {
      removeModal()
    })
    
    # 确认快速添加链接
    observeEvent(input$confirm_quick_link, {
      if (is.null(selected_project_id()) || 
          is.null(input$quick_link_title) || trimws(input$quick_link_title) == "" ||
          is.null(input$quick_link_url) || trimws(input$quick_link_url) == "") {
        showNotification("请填写链接标题和地址", type = "warning")
        return()
      }
      
      tryCatch({
        # 存储链接到项目备注中（或创建一个专门的表）
        # 这里我们可以暂时存储到项目描述或备注中
        current_desc <- get_project_details(selected_project_id())$description
        new_desc <- paste0(
          current_desc, "\n\n",
          "【链接】", input$quick_link_title, ": ", input$quick_link_url,
          ifelse(!is.null(input$quick_link_desc) && trimws(input$quick_link_desc) != "",
                 paste0("\n描述: ", input$quick_link_desc), "")
        )
        
        dbExecute(db_pool, "
          UPDATE projects.projects 
          SET description = $1, updated_at = NOW()
          WHERE project_id = $2
        ", params = list(new_desc, selected_project_id()))
        
        # 清空表单
        updateTextInput(session, "quick_link_title", value = "")
        updateTextInput(session, "quick_link_url", value = "")
        updateTextAreaInput(session, "quick_link_desc", value = "")
        
        # 关闭模态框
        removeModal()
        
        showNotification("链接添加成功", type = "success")
        log_info(sprintf("快速链接添加成功: %s", input$quick_link_title))
        
      }, error = function(e) {
        showNotification(sprintf("添加链接失败: %s", e$message), type = "error")
        log_error(sprintf("快速链接添加失败: %s", e$message))
      })
    })
    
    # 确认快速添加评论
    observeEvent(input$confirm_quick_comment, {
      if (is.null(selected_project_id()) || 
          is.null(input$quick_comment_text) || trimws(input$quick_comment_text) == "") {
        showNotification("请填写评论内容", type = "warning")
        return()
      }
      
      tryCatch({
        dbExecute(db_pool, "
          INSERT INTO projects.project_comments 
          (project_id, user_id, content, is_internal)
          VALUES ($1, $2, $3, $4)
        ", params = list(
          selected_project_id(),
          1,  # 当前用户ID
          trimws(input$quick_comment_text),
          input$quick_comment_internal
        ))
        
        # 清空表单
        updateTextAreaInput(session, "quick_comment_text", value = "")
        
        # 关闭模态框
        removeModal()
        
        showNotification("评论添加成功", type = "success")
        log_info("快速评论添加成功")
        
      }, error = function(e) {
        showNotification(sprintf("添加评论失败: %s", e$message), type = "error")
        log_error(sprintf("快速评论添加失败: %s", e$message))
      })
    })
    
    # 取消删除
    observeEvent(input$cancel_delete, {
      removeModal()
    })
    
    # 取消编辑
    observeEvent(input$cancel_edit, {
      removeModal()
    })
    
    # 关闭详情模态框
    observeEvent(input$close_detail, {
      removeModal()
    })
    
    # 渲染项目表格
    output$projects_table <- renderDT({
      data <- projects_data()
      
      if (!is.null(data) && nrow(data) > 0) {
        # 格式化显示数据
        display_data <- data
        
        # 格式化日期
        display_data$start_date <- format(display_data$start_date, "%Y-%m-%d")
        display_data$end_date <- format(display_data$end_date, "%Y-%m-%d")
        
        # 计算剩余天数
        display_data$remaining_days <- sapply(1:nrow(display_data), function(i) {
          end_date <- as.Date(display_data$end_date[i])
          days <- as.integer(end_date - Sys.Date())
          if (days < 0) {
            return(sprintf('<span style="color: #dc3545; font-weight: bold;">已过期 %d 天</span>', abs(days)))
          } else if (days <= 7) {
            return(sprintf('<span style="color: #ffc107; font-weight: bold;">%d 天</span>', days))
          } else if (days <= 30) {
            return(sprintf('<span style="color: #17a2b8;">%d 天</span>', days))
          } else {
            return(sprintf('<span style="color: #28a745;">%d 天</span>', days))
          }
        })
        
        # 格式化预算
        display_data$budget_display <- sapply(display_data$budget, function(x) {
          if (is.na(x)) {
            return('<span class="budget-cell">未设置</span>')
          } else if (x >= 1000000) {
            return(sprintf('<span class="budget-cell">¥%.1f万</span>', x/10000))
          } else {
            return(sprintf('<span class="budget-cell">¥%.0f</span>', x))
          }
        })
        
        # 添加状态标签
        display_data$status_display <- sapply(1:nrow(display_data), function(i) {
          status <- display_data$status[i]
          if (is.na(status) || status == "") {
            return('<span class="status-label status-in-progress">未知</span>')
          }
          
          class_name <- switch(
            as.character(status),
            "规划中" = "status-planning",
            "进行中" = "status-in-progress",
            "暂停" = "status-on-hold",
            "已完成" = "status-completed",
            "已取消" = "status-cancelled",
            "status-in-progress"
          )
          sprintf('<span class="status-label %s">%s</span>', class_name, status)
        })
        
        # 添加优先级标签
        display_data$priority_display <- sapply(1:nrow(display_data), function(i) {
          priority <- display_data$priority_level[i]
          if (is.na(priority) || priority == "") {
            return('<span class="status-label priority-medium">未设置</span>')
          }
          
          priority_text <- switch(
            priority,
            "high" = "高",
            "medium" = "中",
            "low" = "低",
            priority
          )
          
          class_name <- paste0("status-label priority-", priority)
          sprintf('<span class="%s">%s</span>', class_name, priority_text)
        })
        
        # 添加操作按钮 - 使用简单的 onclick 事件
        display_data$actions <- sapply(1:nrow(display_data), function(i) {
          project_id <- display_data$project_id[i]
          
          sprintf('
            <div class="action-buttons" style="display: flex; gap: 5px; justify-content: center;">
              <button class="btn btn-info btn-sm" 
                      onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})"
                      title="查看详情">
                <i class="fa fa-eye"></i>
              </button>
              <button class="btn btn-warning btn-sm" 
                      onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})"
                      title="编辑">
                <i class="fa fa-edit"></i>
              </button>
              <button class="btn btn-success btn-sm" 
                      onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})"
                      title="附件管理">
                <i class="fa fa-paperclip"></i>
              </button>
              <button class="btn btn-danger btn-sm" 
                      onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})"
                      title="删除">
                <i class="fa fa-trash"></i>
              </button>
            </div>
          ', 
                  ns("view_project"), project_id,
                  ns("edit_project"), project_id,
                  ns("manage_attachments"), project_id,
                  ns("delete_project"), project_id
          )
        })
        
        # 选择要显示的列
        display_cols <- c(
          "project_code", "project_name", "project_type", 
          "status_display", "priority_display", "budget_display",
          "start_date", "end_date", "remaining_days", "actions"
        )
        
        display_data <- display_data[, display_cols, drop = FALSE]
        
        # 设置列名
        colnames(display_data) <- c(
          "项目编号", "项目名称", "类型", "状态", 
          "优先级", "预算", "开始日期", "结束日期", "剩余时间", "操作"
        )
        
        # 创建数据表格
        dt <- datatable(
          display_data,
          escape = FALSE,
          extensions = c('Buttons', 'Scroller'),
          options = list(
            dom = 'Bfrtip',
            buttons = list(
              list(
                extend = 'copy',
                text = '<i class="fa fa-copy"></i> 复制',
                titleAttr = '复制到剪贴板'
              ),
              list(
                extend = 'csv',
                text = '<i class="fa fa-file-csv"></i> CSV',
                titleAttr = '导出CSV'
              ),
              list(
                extend = 'excel',
                text = '<i class="fa fa-file-excel"></i> Excel',
                titleAttr = '导出Excel'
              ),
              list(
                extend = 'print',
                text = '<i class="fa fa-print"></i> 打印',
                titleAttr = '打印表格'
              )
            ),
            pageLength = DEFAULT_PAGE_LENGTH,
            lengthMenu = PAGE_LENGTH_OPTIONS,
            searching = TRUE,
            searchHighlight = TRUE,
            ordering = TRUE,
            order = list(list(0, 'desc')),
            scrollX = TRUE,
            scrollY = 400,
            scroller = TRUE,
            language = list(
              url = '//cdn.datatables.net/plug-ins/1.10.24/i18n/Chinese.json'
            ),
            columnDefs = list(
              list(width = '100px', targets = 0),
              list(width = '150px', targets = 1),
              list(width = '80px', targets = 2),
              list(width = '90px', targets = 3),
              list(width = '70px', targets = 4),
              list(width = '100px', targets = 5),
              list(width = '100px', targets = 6),
              list(width = '100px', targets = 7),
              list(width = '100px', targets = 8),
              list(width = '120px', targets = 9),
              list(className = 'dt-center', targets = 9)  # 操作列居中
            )
          ),
          rownames = FALSE,
          class = 'cell-border stripe hover'
        )
        
        # 添加CSS样式
        dt <- dt %>%
          formatStyle(
            '项目编号',
            backgroundColor = '#f8f9fa',
            fontWeight = 'bold'
          ) %>%
          formatStyle(
            '项目名称',
            fontWeight = '600'
          ) %>%
          formatStyle(
            '操作',
            textAlign = 'center'
          )
        
        return(dt)
        
      } else {
        # 无数据时显示提示
        datatable(
          data.frame(
            提示 = c("暂无项目数据", "点击上方的'创建新项目'按钮开始")
          ),
          options = list(
            dom = 't',
            ordering = FALSE,
            searching = FALSE,
            info = FALSE,
            paging = FALSE
          ),
          rownames = FALSE,
          class = 'display'
        ) %>%
          formatStyle(
            '提示',
            textAlign = 'center',
            fontSize = '16px',
            color = '#6c757d'
          )
      }
    })
    
    # 导出CSV
    output$export_csv_btn <- downloadHandler(
      filename = function() {
        sprintf("projects_export_%s.csv", format(Sys.time(), "%Y%m%d_%H%M%S"))
      },
      content = function(file) {
        data <- projects_data()
        if (!is.null(data) && nrow(data) > 0) {
          write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
          log_info(sprintf("项目数据已导出到CSV: %s", file))
        } else {
          showNotification("没有数据可导出", type = "warning")
        }
      }
    )
    
    # 导出Excel
    output$export_excel_btn <- downloadHandler(
      filename = function() {
        sprintf("projects_export_%s.xlsx", format(Sys.time(), "%Y%m%d_%H%M%S"))
      },
      content = function(file) {
        data <- projects_data()
        if (!is.null(data) && nrow(data) > 0) {
          write.xlsx(data, file)
          log_info(sprintf("项目数据已导出到Excel: %s", file))
        } else {
          showNotification("没有数据可导出", type = "warning")
        }
      }
    )
  })
}

# ==================== 创建项目模态框 ====================
create_project_modal <- function(ns) {
  modalDialog(
    title = tagList(icon("plus"), "创建新项目"),
    size = "l",
    easyClose = FALSE,
    footer = NULL,
    
    fluidRow(
      column(
        width = 12,
        div(
          style = "padding: 20px;",
          
          fluidRow(
            column(
              width = 6,
              textInput(
                inputId = ns("new_project_name"),
                label = tagList("项目名称", tags$span(class = "required")),
                placeholder = "请输入项目名称",
                width = "100%"
              )
            ),
            column(
              width = 6,
              selectInput(
                inputId = ns("new_project_type"),
                label = tagList("项目类型", tags$span(class = "required")),
                choices = names(PROJECT_TYPE_CODES),
                selected = "基础研究",
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              textInput(
                inputId = ns("new_project_code"),
                label = "项目编号",
                placeholder = "留空则自动生成",
                value = "",
                width = "100%"
              ),
              helpText("格式: 类型代码-年份-月份-序列号")
            ),
            column(
              width = 6,
              selectInput(
                inputId = ns("new_priority"),
                label = tagList("优先级", tags$span(class = "required")),
                choices = c("请选择" = "", names(PRIORITY_LEVELS)),
                selected = "",
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              dateInput(
                inputId = ns("new_start_date"),
                label = tagList("开始日期", tags$span(class = "required")),
                value = Sys.Date(),
                format = "yyyy-mm-dd",
                width = "100%"
              )
            ),
            column(
              width = 6,
              dateInput(
                inputId = ns("new_end_date"),
                label = tagList("结束日期", tags$span(class = "required")),
                value = Sys.Date() + 365,
                format = "yyyy-mm-dd",
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              numericInput(
                inputId = ns("new_budget"),
                label = "预算金额（元）",
                value = 100000,
                min = 0,
                step = 10000,
                width = "100%"
              )
            ),
            column(
              width = 6,
              selectInput(
                inputId = ns("new_status"),
                label = "项目状态",
                choices = names(PROJECT_STATUSES),
                selected = "规划中",
                width = "100%"
              )
            )
          ),
          
          textAreaInput(
            inputId = ns("new_description"),
            label = "项目描述",
            placeholder = "请输入项目详细描述、目标、范围等信息...",
            rows = 5,
            width = "100%"
          ),
          
          hr(),
          
          div(
            style = "text-align: right;",
            modalButton(
              tagList(icon("times"), "取消")
            ),
            actionButton(
              inputId = ns("confirm_create"),
              label = tagList(icon("check"), "创建项目"),
              class = "btn-primary"
            )
          )
        )
      )
    )
  )
  
}


# ==================== 查看项目详情模态框 ====================
view_project_modal <- function(ns, project_data) {
  if (is.null(project_data) || !is.data.frame(project_data) || nrow(project_data) == 0) {
    log_warn("查看项目详情：传入的数据无效")
    return(tagList())
  }
  
  project <- project_data[1, ]
  
  log_info(sprintf("显示项目详情模态框：项目名称=%s，项目ID=%s", 
                   project$project_name, project$project_id))
  
  modalDialog(
    title = tagList(icon("eye"), "项目详情"),
    size = "xl",
    easyClose = TRUE,
    footer = div(
      style = "text-align: center;",
      actionButton(
        inputId = ns("close_detail"),
        label = tagList(icon("times"), "关闭"),
        class = "btn-default"
      )
    ),
    
    tabsetPanel(
      id = ns("project_detail_tabs"),
      type = "tabs",
      
      # 选项卡1：基本信息
      tabPanel(
        title = tagList(icon("info-circle"), "基本信息"),
        value = "basic_info_tab",
        div(
          style = "padding: 20px;",
          
          fluidRow(
            column(
              width = 8,
              h3(project$project_name, style = "margin-top: 0; color: #2c3e50;"),
              h5(paste("项目编号:", project$project_code), 
                 style = "color: #666; margin-top: 5px;")
            ),
            column(
              width = 4,
              div(
                style = "text-align: right;",
                span(
                  class = paste0("status-label status-", 
                                 switch(as.character(project$status_name),
                                        "规划中" = "planning",
                                        "进行中" = "in-progress",
                                        "暂停" = "on-hold",
                                        "已完成" = "completed",
                                        "已取消" = "cancelled",
                                        "in-progress")),
                  project$status_name
                )
              )
            )
          ),
          
          hr(style = "margin: 20px 0;"),
          
          fluidRow(
            column(
              width = 6,
              h4(icon("info-circle"), "基本信息", style = "color: #4e73df; margin-bottom: 15px;"),
              div(
                class = "well",
                style = "padding: 15px; background-color: #f8f9fc; border-radius: 4px;",
                tags$table(
                  class = "table table-striped",
                  tags$tbody(
                    tags$tr(
                      tags$td(strong("项目类型:")),
                      tags$td(project$type_name)
                    ),
                    tags$tr(
                      tags$td(strong("研究阶段:")),
                      tags$td(ifelse(!is.na(project$stage_name) && project$stage_name != "", 
                                     project$stage_name, "未设置"))
                    ),
                    tags$tr(
                      tags$td(strong("优先级:")),
                      tags$td(
                        span(
                          class = paste0("status-label priority-", 
                                         tolower(project$priority_level)),
                          switch(tolower(project$priority_level),
                                 "high" = "高",
                                 "medium" = "中", 
                                 "low" = "低",
                                 project$priority_level)
                        )
                      )
                    ),
                    tags$tr(
                      tags$td(strong("预算金额:")),
                      tags$td(sprintf("¥%.2f", project$budget))
                    )
                  )
                )
              )
            ),
            column(
              width = 6,
              h4(icon("calendar"), "时间信息", style = "color: #4e73df; margin-bottom: 15px;"),
              div(
                class = "well",
                style = "padding: 15px; background-color: #f8f9fc; border-radius: 4px;",
                tags$table(
                  class = "table table-striped",
                  tags$tbody(
                    tags$tr(
                      tags$td(strong("开始日期:")),
                      tags$td(format(project$start_date, "%Y年%m月%d日"))
                    ),
                    tags$tr(
                      tags$td(strong("结束日期:")),
                      tags$td(format(project$end_date, "%Y年%m月%d日"))
                    ),
                    tags$tr(
                      tags$td(strong("项目周期:")),
                      tags$td(sprintf("%d 天", 
                                      as.integer(project$end_date - project$start_date)))
                    ),
                    tags$tr(
                      tags$td(strong("剩余天数:")),
                      tags$td(
                        if (project$end_date >= Sys.Date()) {
                          sprintf('<span style="color: #28a745;">%d 天</span>', 
                                  as.integer(project$end_date - Sys.Date()))
                        } else {
                          sprintf('<span style="color: #dc3545;">已过期 %d 天</span>', 
                                  as.integer(Sys.Date() - project$end_date))
                        }
                      )
                    )
                  )
                )
              )
            )
          ),
          
          h4(icon("file-alt"), "项目描述", style = "color: #4e73df; margin-bottom: 15px; margin-top: 20px;"),
          div(
            class = "well",
            style = "padding: 15px; background-color: #f8f9fc; border-radius: 4px; min-height: 100px;",
            if (!is.null(project$description) && project$description != "") {
              HTML(gsub("\n", "<br>", project$description))
            } else {
              tags$i("暂无描述", style = "color: #6c757d;")
            }
          ),
          
          hr(style = "margin: 20px 0;"),
          
          fluidRow(
            column(
              width = 6,
              h5(icon("user"), "创建信息", style = "color: #666;"),
              tags$p(
                style = "margin-bottom: 5px;",
                paste("创建人:", ifelse(!is.na(project$created_by_name) && 
                                       project$created_by_name != "", 
                                     project$created_by_name, "未知"))
              ),
              tags$p(
                style = "margin-bottom: 5px;",
                paste("创建时间:", format(project$created_at, "%Y-%m-%d %H:%M:%S"))
              ),
              tags$p(
                paste("更新时间:", format(project$updated_at, "%Y-%m-%d %H:%M:%S"))
              )
            )
          )
        )
      )
    )
  )
}

# ==================== 编辑项目模态框 ====================
edit_project_modal <- function(ns, project_data) {
  if (is.null(project_data) || nrow(project_data) == 0) {
    return(tagList())
  }
  
  project <- project_data[1, ]
  
  # 获取优先级的中文显示值
  priority_display <- switch(
    project$priority_level,
    "high" = "高",
    "medium" = "中",
    "low" = "低",
    "中"
  )
  
  modalDialog(
    title = tagList(icon("edit"), "编辑项目"),
    size = "l",
    easyClose = FALSE,
    footer = NULL,
    
    fluidRow(
      column(
        width = 12,
        div(
          style = "padding: 20px;",
          
          fluidRow(
            column(
              width = 6,
              textInput(
                inputId = ns("edit_project_name"),
                label = tagList("项目名称", tags$span(class = "required")),
                value = project$project_name,
                width = "100%"
              )
            ),
            column(
              width = 6,
              textInput(
                inputId = ns("edit_project_code"),
                label = "项目编号",
                value = project$project_code,
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              selectInput(
                inputId = ns("edit_project_type"),
                label = "项目类型",
                choices = names(PROJECT_TYPE_CODES),
                selected = project$type_name,
                width = "100%"
              )
            ),
            column(
              width = 6,
              selectInput(
                inputId = ns("edit_priority"),
                label = "优先级",
                choices = names(PRIORITY_LEVELS),
                selected = priority_display,
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              dateInput(
                inputId = ns("edit_start_date"),
                label = tagList("开始日期", tags$span(class = "required")),
                value = as.Date(project$start_date),
                format = "yyyy-mm-dd",
                width = "100%"
              )
            ),
            column(
              width = 6,
              dateInput(
                inputId = ns("edit_end_date"),
                label = tagList("结束日期", tags$span(class = "required")),
                value = as.Date(project$end_date),
                format = "yyyy-mm-dd",
                width = "100%"
              )
            )
          ),
          
          fluidRow(
            column(
              width = 6,
              numericInput(
                inputId = ns("edit_budget"),
                label = "预算金额（元）",
                value = project$budget,
                min = 0,
                step = 10000,
                width = "100%"
              )
            ),
            column(
              width = 6,
              selectInput(
                inputId = ns("edit_status"),
                label = "项目状态",
                choices = names(PROJECT_STATUSES),
                selected = project$status_name,
                width = "100%"
              )
            )
          ),
          
          textAreaInput(
            inputId = ns("edit_description"),
            label = "项目描述",
            value = ifelse(!is.null(project$description), project$description, ""),
            rows = 5,
            width = "100%"
          ),
          
          hr(),
          
          div(
            style = "text-align: right;",
            actionButton(
              inputId = ns("cancel_edit"),
              label = tagList(icon("times"), "取消"),
              class = "btn-default",
              style = "margin-right: 10px;"
            ),
            actionButton(
              inputId = ns("confirm_edit"),
              label = tagList(icon("check"), "保存修改"),
              class = "btn-primary"
            )
          )
        )
      )
    )
  )
}

# ==================== 删除确认模态框 ====================
delete_confirm_modal <- function(ns, project_data) {
  modalDialog(
    title = tagList(icon("exclamation-triangle"), "确认删除"),
    size = "m",
    easyClose = FALSE,
    
    div(
      style = "text-align: center; padding: 20px;",
      
      h4("您确定要删除这个项目吗？", style = "color: #dc3545; margin-bottom: 20px;"),
      
      div(
        class = "alert alert-warning",
        style = "text-align: left; margin-bottom: 20px;",
        icon("exclamation-circle"),
        "删除操作无法撤销！项目将被标记为不活跃状态。"
      ),
      
      div(
        style = "background-color: #f8f9fc; padding: 15px; border-radius: 4px; margin-bottom: 20px;",
        h5("项目信息:", style = "margin-top: 0;"),
        tags$p(strong("项目名称: "), project_data$project_name),
        tags$p(strong("项目编号: "), project_data$project_code),
        tags$p(strong("项目状态: "), project_data$status_name)
      ),
      
      div(
        style = "display: flex; justify-content: center; gap: 15px;",
        actionButton(
          inputId = ns("cancel_delete"),
          label = tagList(icon("times"), "取消"),
          class = "btn-default",
          style = "min-width: 100px;"
        ),
        actionButton(
          inputId = ns("confirm_delete"),
          label = tagList(icon("trash"), "确认删除"),
          class = "btn-danger",
          style = "min-width: 100px;"
        )
      )
    )
  )
}

# ==================== 附件管理模态框 ====================
attachments_management_modal <- function(ns, project_data) {
  if (is.null(project_data) || nrow(project_data) == 0) {
    return(tagList())
  }
  
  project <- project_data[1, ]
  
  modalDialog(
    title = tagList(
      icon("paperclip"), 
      "附件管理 - ", 
      span(project$project_name, style = "color: #667eea;")
    ),
    size = "xl",
    easyClose = TRUE,
    footer = tagList(
      actionButton(
        inputId = ns("close_attachments"),
        label = tagList(icon("times"), "关闭"),
        class = "btn-default"
      )
    ),
    
    # 快速操作按钮
    fluidRow(
      column(
        width = 12,
        div(
          class = "well",
          style = "margin-bottom: 20px;",
          h4(icon("bolt"), "快速操作", style = "margin-top: 0;"),
          div(
            style = "display: flex; gap: 10px; flex-wrap: wrap;",
            actionButton(
              inputId = ns("quick_upload_file"),
              label = tagList(icon("upload"), "上传文件"),
              class = "btn-primary"
            ),
            actionButton(
              inputId = ns("quick_add_link"),
              label = tagList(icon("link"), "添加链接"),
              class = "btn-success"
            ),
            actionButton(
              inputId = ns("quick_add_comment"),
              label = tagList(icon("comment"), "添加评论"),
              class = "btn-info"
            ),
            actionButton(
              inputId = ns("refresh_attachments"),
              label = tagList(icon("sync-alt"), "刷新"),
              class = "btn-default"
            )
          )
        )
      )
    ),
    
    # 附件管理模块
    attachment_ui(ns("attachment_module"))
  )
}


# ==================== 快速上传模态框 ====================
quick_upload_modal <- function(ns, project_data) {
  if (is.null(project_data) || nrow(project_data) == 0) {
    return(tagList())
  }
  
  project <- project_data[1, ]
  
  modalDialog(
    title = tagList(
      icon("upload"), 
      "快速上传 - ", 
      span(project$project_name, style = "color: #667eea; font-size: 14px;")
    ),
    size = "m",
    easyClose = TRUE,
    footer = NULL,
    
    div(
      style = "padding: 20px; text-align: center;",
      
      # 拖放上传区域
      div(
        class = "upload-area",
        id = ns("drop_zone"),
        style = "min-height: 200px; display: flex; flex-direction: column; 
                justify-content: center; align-items: center;",
        icon("cloud-upload-alt", class = "fa-3x", style = "color: #667eea; margin-bottom: 15px;"),
        h4("拖放文件到这里", style = "margin-bottom: 10px;"),
        p("或", style = "margin: 10px 0;"),
        fileInput(
          inputId = ns("quick_file_input"),
          label = NULL,
          buttonLabel = tagList(icon("search"), "选择文件"),
          multiple = FALSE,
          width = "200px"
        ),
        p(
          class = "text-muted",
          style = "margin-top: 10px; font-size: 12px;",
          sprintf("支持多种文件类型，最大 %.0fMB", MAX_FILE_SIZE/1024/1024)
        )
      ),
      
      # 文件信息预览
      uiOutput(ns("quick_file_info")),
      
      # 上传选项（使用UI输出动态显示）
      uiOutput(ns("quick_upload_options")),
      
      # 操作按钮
      div(
        style = "margin-top: 20px; display: flex; justify-content: center; gap: 10px;",
        actionButton(
          inputId = ns("cancel_quick_upload"),
          label = tagList(icon("times"), "取消"),
          class = "btn-default"
        ),
        actionButton(
          inputId = ns("confirm_quick_upload"),
          label = tagList(icon("upload"), "上传"),
          class = "btn-primary",
          disabled = TRUE
        )
      )
    )
  )
}

# ==================== 快速链接添加模态框 ====================
quick_link_modal <- function(ns, project_data) {
  if (is.null(project_data) || nrow(project_data) == 0) {
    return(tagList())
  }
  
  modalDialog(
    title = tagList(icon("link"), "快速添加链接"),
    size = "m",
    easyClose = TRUE,
    footer = NULL,
    
    div(
      style = "padding: 20px;",
      
      textInput(
        inputId = ns("quick_link_title"),
        label = "链接标题",
        placeholder = "请输入链接标题",
        width = "100%"
      ),
      
      textInput(
        inputId = ns("quick_link_url"),
        label = "链接地址",
        placeholder = "https://example.com",
        width = "100%"
      ),
      
      textAreaInput(
        inputId = ns("quick_link_desc"),
        label = "描述（可选）",
        placeholder = "请输入链接描述",
        rows = 3,
        width = "100%"
      ),
      
      div(
        style = "margin-top: 20px; text-align: center;",
        actionButton(
          inputId = ns("confirm_quick_link"),
          label = tagList(icon("link"), "添加链接"),
          class = "btn-success"
        )
      )
    )
  )
}

# ==================== 快速评论添加模态框 ====================
quick_comment_modal <- function(ns, project_data) {
  if (is.null(project_data) || nrow(project_data) == 0) {
    return(tagList())
  }
  
  modalDialog(
    title = tagList(icon("comment"), "快速添加评论"),
    size = "m",
    easyClose = TRUE,
    footer = NULL,
    
    div(
      style = "padding: 20px;",
      
      textAreaInput(
        inputId = ns("quick_comment_text"),
        label = "评论内容",
        placeholder = "请输入项目相关的评论或备注...",
        rows = 4,
        width = "100%"
      ),
      
      checkboxInput(
        inputId = ns("quick_comment_internal"),
        label = "内部评论",
        value = TRUE
      ),
      
      div(
        style = "margin-top: 20px; text-align: center;",
        actionButton(
          inputId = ns("confirm_quick_comment"),
          label = tagList(icon("comment"), "发表评论"),
          class = "btn-info"
        )
      )
    )
  )
}