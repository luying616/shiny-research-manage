# ==================== 项目管理模块 ====================
# 功能：项目的创建、编辑、查看、删除等CRUD操作
# 文件：modules/project_module.R
# =====================================================

# ==================== 项目管理模块 UI ====================
project_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 操作按钮行
    fluidRow(
      column(
        width = 12,
        div(
          style = "margin-bottom: 20px;",
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
          actionButton(
            inputId = ns("export_csv_btn"),
            label = tagList(icon("file-csv"), "导出CSV"),
            class = "btn-success"
          ),
          actionButton(
            inputId = ns("export_excel_btn"),
            label = tagList(icon("file-excel"), "导出Excel"),
            class = "btn-success"
          )
        )
      )
    ),
    
    # 筛选面板
    fluidRow(
      column(
        width = 12,
        div(
          class = "box",
          div(
            class = "box-header",
            h3(class = "box-title", tagList(icon("filter"), "筛选条件"))
          ),
          div(
            class = "box-body",
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
                  inputId = ns("filter_start_date"),
                  label = "开始日期（从）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              ),
              column(
                width = 3,
                dateInput(
                  inputId = ns("filter_end_date"),
                  label = "结束日期（到）",
                  value = NULL,
                  format = "yyyy-mm-dd"
                )
              ),
              column(
                width = 3,
                style = "margin-top: 25px;",
                actionButton(
                  inputId = ns("apply_filter_btn"),
                  label = tagList(icon("search"), "应用筛选"),
                  class = "btn-primary"
                )
              ),
              column(
                width = 3,
                style = "margin-top: 25px;",
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
          class = "box",
          div(
            class = "box-header",
            h3(class = "box-title", tagList(icon("list"), "项目列表"))
          ),
          div(
            class = "box-body",
            DTOutput(ns("projects_table"))
          )
        )
      )
    )
  )
}

# ==================== 项目管理模块 Server ====================
project_module_server <- function(id, db_pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 项目数据
    projects_data <- reactiveVal(NULL)
    
    # 加载项目数据
    load_projects <- function(filters = NULL) {
      if (is.null(db_pool)) {
        log_warn("数据库连接不可用，使用模拟数据")
        return(get_mock_projects())
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
            p.created_at
          FROM projects.projects p
          LEFT JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          LEFT JOIN projects.research_stages rs ON p.research_stage_id = rs.stage_id
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          WHERE p.is_active = TRUE
        "
        
        # 应用筛选条件（简化版，实际应使用参数化查询）
        if (!is.null(filters)) {
          if (!is.null(filters$type) && filters$type != "") {
            # 注意：这里简化了，实际应使用JOIN和参数化查询
            query <- paste0(query, sprintf(" AND pt.type_name = '%s'", filters$type))
          }
          if (!is.null(filters$status) && filters$status != "") {
            query <- paste0(query, sprintf(" AND ps.status_name = '%s'", filters$status))
          }
          if (!is.null(filters$priority) && filters$priority != "") {
            query <- paste0(query, sprintf(" AND p.priority_level = '%s'", filters$priority))
          }
          if (!is.null(filters$keyword) && filters$keyword != "") {
            keyword <- filters$keyword
            query <- paste0(query, sprintf(" AND (p.project_name ILIKE '%%%s%%' OR p.project_code ILIKE '%%%s%%')", keyword, keyword))
          }
        }
        
        query <- paste0(query, " ORDER BY p.created_at DESC")
        
        projects <- dbGetQuery(db_pool, query)
        return(projects)
      }, error = function(e) {
        log_error(sprintf("加载项目数据失败: %s", e$message))
        return(get_mock_projects())
      })
    }
    
    # 模拟项目数据
    get_mock_projects <- function() {
      data.frame(
        project_id = 1:10,
        project_code = paste0("JC-2026-", sprintf("%03d", 1:10)),
        project_name = paste0("示例项目 ", 1:10),
        project_type = rep("基础研究", 10),
        research_stage = rep("实施阶段", 10),
        priority_level = rep(c("high", "medium", "low"), length.out = 10),
        budget = rep(200000, 10),
        start_date = Sys.Date() - sample(100:365, 10),
        end_date = Sys.Date() + sample(100:365, 10),
        status = rep(c("进行中", "规划中"), length.out = 10),
        created_at = Sys.Date() - sample(1:100, 10),
        stringsAsFactors = FALSE
      )
    }
    
    # 初始加载
    observe({
      projects_data(load_projects())
    })
    
    # 应用筛选
    observeEvent(input$apply_filter_btn, {
      filters <- list(
        type = input$filter_type,
        status = input$filter_status,
        priority = input$filter_priority,
        keyword = input$filter_keyword,
        start_date = input$filter_start_date,
        end_date = input$filter_end_date
      )
      projects_data(load_projects(filters))
      showNotification("筛选已应用", type = "message", duration = 2)
    })
    
    # 重置筛选
    observeEvent(input$reset_filter_btn, {
      updateSelectInput(session, "filter_type", selected = "")
      updateSelectInput(session, "filter_status", selected = "")
      updateSelectInput(session, "filter_priority", selected = "")
      updateTextInput(session, "filter_keyword", value = "")
      updateDateInput(session, "filter_start_date", value = NULL)
      updateDateInput(session, "filter_end_date", value = NULL)
      projects_data(load_projects())
      showNotification("筛选已重置", type = "message", duration = 2)
    })
    
    # 刷新列表
    observeEvent(input$refresh_list_btn, {
      projects_data(load_projects())
      showNotification("列表已刷新", type = "message", duration = 2)
      log_info("项目列表已刷新")
    })
    
    # 创建新项目
    observeEvent(input$create_project_btn, {
      showModal(create_project_modal(ns))
    })
    
    # 渲染项目表格
    output$projects_table <- renderDT({
      data <- projects_data()
      if (!is.null(data) && nrow(data) > 0) {
        # 格式化数据
        display_data <- data
        display_data$budget <- sapply(display_data$budget, format_currency)
        display_data$start_date <- sapply(display_data$start_date, format_date)
        display_data$end_date <- sapply(display_data$end_date, format_date)
        
        # 添加状态标签
        display_data$status <- sapply(1:nrow(display_data), function(i) {
          status <- data$status[i]
          class_name <- switch(
            status,
            "规划中" = "status-planning",
            "进行中" = "status-in-progress",
            "暂停" = "status-on-hold",
            "已完成" = "status-completed",
            "已取消" = "status-cancelled",
            "status-in-progress"
          )
          sprintf('<span class="label %s">%s</span>', class_name, status)
        })
        
        # 添加优先级标签
        display_data$priority_level <- sapply(1:nrow(display_data), function(i) {
          priority <- data$priority_level[i]
          if (is.na(priority) || priority == "") return("")
          
          priority_text <- switch(
            priority,
            "high" = "高",
            "medium" = "中",
            "low" = "低",
            priority
          )
          
          class_name <- paste0("priority-", priority)
          sprintf('<span class="label %s">%s</span>', class_name, priority_text)
        })
        
        # 添加操作按钮
        display_data$actions <- sapply(1:nrow(display_data), function(i) {
          project_id <- data$project_id[i]
          sprintf('
            <button class="btn btn-info btn-sm" onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})">
              <i class="fa fa-eye"></i> 查看
            </button>
            <button class="btn btn-warning btn-sm" onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})">
              <i class="fa fa-edit"></i> 编辑
            </button>
            <button class="btn btn-danger btn-sm" onclick="Shiny.setInputValue(\'%s\', %d, {priority: \'event\'})">
              <i class="fa fa-trash"></i> 删除
            </button>
          ',
          ns("view_project"), project_id,
          ns("edit_project"), project_id,
          ns("delete_project"), project_id
          )
        })
        
        # 选择要显示的列
        display_cols <- c("project_code", "project_name", "project_type", "status", 
                         "priority_level", "budget", "start_date", "end_date", "actions")
        display_data <- display_data[, display_cols]
        
        colnames(display_data) <- c("项目编号", "项目名称", "项目类型", "状态", 
                                    "优先级", "预算", "开始日期", "结束日期", "操作")
        
        datatable(
          display_data,
          escape = FALSE,
          options = list(
            pageLength = DEFAULT_PAGE_LENGTH,
            lengthMenu = PAGE_LENGTH_OPTIONS,
            searching = FALSE,
            ordering = TRUE,
            order = list(list(0, 'desc')),
            language = list(
              url = '//cdn.datatables.net/plug-ins/1.10.24/i18n/Chinese.json'
            )
          ),
          rownames = FALSE,
          class = 'display compact stripe hover'
        )
      } else {
        datatable(
          data.frame(消息 = "暂无项目数据"),
          options = list(dom = 't'),
          rownames = FALSE
        )
      }
    })
    
    # 导出CSV
    observeEvent(input$export_csv_btn, {
      data <- projects_data()
      if (!is.null(data) && nrow(data) > 0) {
        filename <- sprintf("projects_export_%s.csv", format(Sys.time(), "%Y%m%d_%H%M%S"))
        write.csv(data, file = filename, row.names = FALSE, fileEncoding = "UTF-8")
        showNotification(sprintf("已导出到: %s", filename), type = "message", duration = 5)
        log_info(sprintf("项目数据已导出到CSV: %s", filename))
      } else {
        showNotification("没有数据可导出", type = "warning", duration = 3)
      }
    })
    
    # 导出Excel
    observeEvent(input$export_excel_btn, {
      data <- projects_data()
      if (!is.null(data) && nrow(data) > 0) {
        filename <- sprintf("projects_export_%s.xlsx", format(Sys.time(), "%Y%m%d_%H%M%S"))
        write.xlsx(data, file = filename)
        showNotification(sprintf("已导出到: %s", filename), type = "message", duration = 5)
        log_info(sprintf("项目数据已导出到Excel: %s", filename))
      } else {
        showNotification("没有数据可导出", type = "warning", duration = 3)
      }
    })
  })
}

# ==================== 创建项目模态框 ====================
create_project_modal <- function(ns) {
  modalDialog(
    title = tagList(icon("plus"), "创建新项目"),
    size = "l",
    
    fluidRow(
      column(
        width = 6,
        textInput(
          inputId = ns("new_project_name"),
          label = tagList("项目名称", tags$span(class = "required")),
          placeholder = "请输入项目名称"
        )
      ),
      column(
        width = 6,
        selectInput(
          inputId = ns("new_project_type"),
          label = tagList("项目类型", tags$span(class = "required")),
          choices = names(PROJECT_TYPE_CODES)
        )
      )
    ),
    
    fluidRow(
      column(
        width = 6,
        textInput(
          inputId = ns("new_project_code"),
          label = "项目编号",
          placeholder = "自动生成",
          value = ""
        ),
        helpText("留空则自动生成")
      ),
      column(
        width = 6,
        selectInput(
          inputId = ns("new_priority"),
          label = "优先级",
          choices = c("请选择" = "", names(PRIORITY_LEVELS))
        )
      )
    ),
    
    fluidRow(
      column(
        width = 6,
        dateInput(
          inputId = ns("new_start_date"),
          label = "开始日期",
          value = Sys.Date()
        )
      ),
      column(
        width = 6,
        dateInput(
          inputId = ns("new_end_date"),
          label = "结束日期",
          value = Sys.Date() + 365
        )
      )
    ),
    
    fluidRow(
      column(
        width = 6,
        numericInput(
          inputId = ns("new_budget"),
          label = "预算金额（元）",
          value = 0,
          min = 0
        )
      ),
      column(
        width = 6,
        selectInput(
          inputId = ns("new_status"),
          label = "项目状态",
          choices = names(PROJECT_STATUSES),
          selected = "规划中"
        )
      )
    ),
    
    textAreaInput(
      inputId = ns("new_description"),
      label = "项目描述",
      placeholder = "请输入项目描述",
      rows = 4
    ),
    
    footer = tagList(
      modalButton("取消"),
      actionButton(
        inputId = ns("confirm_create"),
        label = tagList(icon("check"), "创建"),
        class = "btn-primary"
      )
    )
  )
}
