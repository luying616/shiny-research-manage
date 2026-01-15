# ==================== 仪表板模块 ====================
# 功能：显示项目统计信息和概览
# 文件：modules/dashboard_module.R
# ===================================================

# ==================== 仪表板模块 UI ====================
dashboard_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 刷新按钮
    div(
      style = "text-align: right; margin-bottom: 20px;",
      actionButton(
        inputId = ns("refresh_btn"),
        label = tagList(icon("sync-alt"), "刷新数据"),
        class = "btn-info"
      )
    ),
    
    # 统计卡片行
    fluidRow(
      # 总项目数
      column(
        width = 3,
        div(
          class = "info-box",
          div(
            class = "info-box-icon",
            style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
            icon("folder", style = "font-size: 30px;")
          ),
          div(
            class = "info-box-content",
            div(class = "info-box-text", "总项目数"),
            div(class = "info-box-number", textOutput(ns("total_projects")))
          )
        )
      ),
      
      # 进行中项目
      column(
        width = 3,
        div(
          class = "info-box",
          div(
            class = "info-box-icon",
            style = "background-color: #2ecc71;",
            icon("tasks", style = "font-size: 30px;")
          ),
          div(
            class = "info-box-content",
            div(class = "info-box-text", "进行中"),
            div(class = "info-box-number", textOutput(ns("active_projects")))
          )
        )
      ),
      
      # 即将到期
      column(
        width = 3,
        div(
          class = "info-box",
          div(
            class = "info-box-icon",
            style = "background-color: #f39c12;",
            icon("exclamation-triangle", style = "font-size: 30px;")
          ),
          div(
            class = "info-box-content",
            div(class = "info-box-text", "即将到期"),
            div(class = "info-box-number", textOutput(ns("due_soon_projects")))
          )
        )
      ),
      
      # 总预算
      column(
        width = 3,
        div(
          class = "info-box",
          div(
            class = "info-box-icon",
            style = "background-color: #e74c3c;",
            icon("dollar-sign", style = "font-size: 30px;")
          ),
          div(
            class = "info-box-content",
            div(class = "info-box-text", "总预算"),
            div(class = "info-box-number", textOutput(ns("total_budget")))
          )
        )
      )
    ),
    
    # 图表和详细信息
    fluidRow(
      # 项目类型分布
      column(
        width = 6,
        div(
          class = "box",
          div(
            class = "box-header",
            h3(class = "box-title", "项目类型分布")
          ),
          div(
            class = "box-body",
            plotOutput(ns("type_distribution"), height = "300px")
          )
        )
      ),
      
      # 项目状态分布
      column(
        width = 6,
        div(
          class = "box",
          div(
            class = "box-header",
            h3(class = "box-title", "项目状态分布")
          ),
          div(
            class = "box-body",
            plotOutput(ns("status_distribution"), height = "300px")
          )
        )
      )
    ),
    
    # 近期项目列表
    fluidRow(
      column(
        width = 12,
        div(
          class = "box",
          div(
            class = "box-header",
            h3(class = "box-title", "最近创建的项目")
          ),
          div(
            class = "box-body",
            DTOutput(ns("recent_projects_table"))
          )
        )
      )
    )
  )
}

# ==================== 仪表板模块 Server ====================
dashboard_server <- function(id, db_pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 响应式数据加载
    dashboard_data <- reactiveVal(NULL)
    
    # 加载仪表板数据
    load_dashboard_data <- function() {
      if (is.null(db_pool)) {
        log_warn("数据库连接不可用，使用模拟数据")
        return(get_mock_dashboard_data())
      }
      
      tryCatch({
        # 获取项目统计
        stats_query <- "
          SELECT 
            COUNT(*) as total_count,
            COUNT(CASE WHEN ps.status_code = 'in_progress' THEN 1 END) as active_count,
            COUNT(CASE WHEN end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' 
                  AND ps.status_code = 'in_progress' THEN 1 END) as due_soon_count,
            COALESCE(SUM(budget), 0) as total_budget
          FROM projects.projects p
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          WHERE p.is_active = TRUE
        "
        
        stats <- dbGetQuery(db_pool, stats_query)
        
        # 获取项目类型分布
        type_query <- "
          SELECT 
            pt.type_name,
            COUNT(*) as count
          FROM projects.projects p
          INNER JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          WHERE p.is_active = TRUE
          GROUP BY pt.type_name
          ORDER BY count DESC
        "
        
        type_dist <- dbGetQuery(db_pool, type_query)
        
        # 获取项目状态分布
        status_query <- "
          SELECT 
            ps.status_name,
            COUNT(*) as count
          FROM projects.projects p
          INNER JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          WHERE p.is_active = TRUE
          GROUP BY ps.status_name
          ORDER BY count DESC
        "
        
        status_dist <- dbGetQuery(db_pool, status_query)
        
        # 获取最近项目
        recent_query <- "
          SELECT 
            p.project_code,
            p.project_name,
            pt.type_name,
            ps.status_name,
            p.budget,
            p.start_date,
            p.created_at
          FROM projects.projects p
          LEFT JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          WHERE p.is_active = TRUE
          ORDER BY p.created_at DESC
          LIMIT 10
        "
        
        recent_projects <- dbGetQuery(db_pool, recent_query)
        
        return(list(
          stats = stats,
          type_distribution = type_dist,
          status_distribution = status_dist,
          recent_projects = recent_projects
        ))
      }, error = function(e) {
        log_error(sprintf("加载仪表板数据失败: %s", e$message))
        return(get_mock_dashboard_data())
      })
    }
    
    # 模拟数据（用于测试）
    get_mock_dashboard_data <- function() {
      list(
        stats = data.frame(
          total_count = 25,
          active_count = 15,
          due_soon_count = 3,
          total_budget = 5000000
        ),
        type_distribution = data.frame(
          type_name = c("基础研究", "临床研究", "应用研究", "数据项目"),
          count = c(10, 8, 5, 2)
        ),
        status_distribution = data.frame(
          status_name = c("进行中", "规划中", "已完成", "暂停"),
          count = c(15, 5, 3, 2)
        ),
        recent_projects = data.frame(
          project_code = paste0("JC-2026-", sprintf("%03d", 1:5)),
          project_name = paste0("示例项目 ", 1:5),
          type_name = rep("基础研究", 5),
          status_name = rep("进行中", 5),
          budget = rep(200000, 5),
          start_date = Sys.Date() - (1:5),
          created_at = Sys.Date() - (1:5)
        )
      )
    }
    
    # 初始加载
    observe({
      dashboard_data(load_dashboard_data())
    })
    
    # 刷新按钮
    observeEvent(input$refresh_btn, {
      showNotification("正在刷新数据...", type = "message", duration = 2)
      dashboard_data(load_dashboard_data())
      log_info("仪表板数据已刷新")
    })
    
    # 总项目数
    output$total_projects <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats)) {
        return(as.character(data$stats$total_count[1]))
      }
      return("0")
    })
    
    # 进行中项目
    output$active_projects <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats)) {
        return(as.character(data$stats$active_count[1]))
      }
      return("0")
    })
    
    # 即将到期项目
    output$due_soon_projects <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats)) {
        return(as.character(data$stats$due_soon_count[1]))
      }
      return("0")
    })
    
    # 总预算
    output$total_budget <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats)) {
        return(format_currency(data$stats$total_budget[1]))
      }
      return("¥0.00")
    })
    
    # 项目类型分布图
    output$type_distribution <- renderPlot({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$type_distribution) && nrow(data$type_distribution) > 0) {
        par(mar = c(5, 8, 2, 2))
        barplot(
          data$type_distribution$count,
          names.arg = data$type_distribution$type_name,
          col = c("#667eea", "#2ecc71", "#f39c12", "#e74c3c", "#3498db"),
          border = NA,
          las = 1,
          horiz = TRUE,
          xlab = "项目数量",
          main = "",
          cex.names = 0.9
        )
      } else {
        plot.new()
        text(0.5, 0.5, "暂无数据", cex = 1.5, col = "gray")
      }
    })
    
    # 项目状态分布图
    output$status_distribution <- renderPlot({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$status_distribution) && nrow(data$status_distribution) > 0) {
        colors <- c("#2ecc71", "#3498db", "#95a5a6", "#f39c12", "#e74c3c")
        pie(
          data$status_distribution$count,
          labels = paste0(data$status_distribution$status_name, "\n(", data$status_distribution$count, ")"),
          col = colors[1:nrow(data$status_distribution)],
          border = "white",
          main = ""
        )
      } else {
        plot.new()
        text(0.5, 0.5, "暂无数据", cex = 1.5, col = "gray")
      }
    })
    
    # 最近项目表格
    output$recent_projects_table <- renderDT({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$recent_projects) && nrow(data$recent_projects) > 0) {
        df <- data$recent_projects
        df$budget <- sapply(df$budget, format_currency)
        df$start_date <- sapply(df$start_date, format_date)
        df$created_at <- format(df$created_at, "%Y-%m-%d %H:%M")
        
        colnames(df) <- c("项目编号", "项目名称", "项目类型", "状态", "预算", "开始日期", "创建时间")
        
        datatable(
          df,
          options = list(
            pageLength = 5,
            lengthChange = FALSE,
            searching = FALSE,
            ordering = FALSE,
            info = FALSE,
            dom = 'tp'
          ),
          rownames = FALSE,
          class = 'display compact'
        )
      } else {
        datatable(
          data.frame(消息 = "暂无项目数据"),
          options = list(dom = 't'),
          rownames = FALSE
        )
      }
    })
  })
}
