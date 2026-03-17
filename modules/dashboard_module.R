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
        log_error("数据库连接不可用")
        showNotification("数据库连接失败", type = "error")
        return(NULL)
      }
      
      tryCatch({
        # 获取项目统计
        stats_query <- "
          SELECT 
            COUNT(*) as total_count,
            COUNT(CASE WHEN ps.status_name = '进行中' THEN 1 END) as active_count,
            COUNT(CASE WHEN p.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' 
                  AND ps.status_name = '进行中' THEN 1 END) as due_soon_count,
            COALESCE(SUM(p.budget), 0) as total_budget
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
          LEFT JOIN projects.project_types pt ON p.project_type_id = pt.type_id
          WHERE p.is_active = TRUE
          GROUP BY pt.type_name
          ORDER BY count DESC
        "
        
        type_dist <- dbGetQuery(db_pool, type_query)
        
        # 确保count是数值类型
        if (!is.null(type_dist) && nrow(type_dist) > 0) {
          type_dist$count <- as.numeric(type_dist$count)
        }
        
        # 获取项目状态分布
        status_query <- "
          SELECT 
            ps.status_name,
            COUNT(*) as count
          FROM projects.projects p
          LEFT JOIN projects.project_statuses ps ON p.status_id = ps.status_id
          WHERE p.is_active = TRUE
          GROUP BY ps.status_name
          ORDER BY count DESC
        "
        
        status_dist <- dbGetQuery(db_pool, status_query)
        
        # 确保count是数值类型
        if (!is.null(status_dist) && nrow(status_dist) > 0) {
          status_dist$count <- as.numeric(status_dist$count)
        }
        
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
        
        # 确保budget是数值类型
        if (!is.null(recent_projects) && nrow(recent_projects) > 0) {
          recent_projects$budget <- as.numeric(recent_projects$budget)
        }
        
        return(list(
          stats = stats,
          type_distribution = type_dist,
          status_distribution = status_dist,
          recent_projects = recent_projects
        ))
      }, error = function(e) {
        log_error(sprintf("加载仪表板数据失败: %s", e$message))
        showNotification(sprintf("加载仪表板数据失败: %s", e$message), type = "error")
        return(NULL)
      })
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
      if (!is.null(data) && !is.null(data$stats) && nrow(data$stats) > 0) {
        return(as.character(data$stats$total_count[1]))
      }
      return("0")
    })
    
    # 进行中项目
    output$active_projects <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats) && nrow(data$stats) > 0) {
        return(as.character(data$stats$active_count[1]))
      }
      return("0")
    })
    
    # 即将到期项目
    output$due_soon_projects <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats) && nrow(data$stats) > 0) {
        return(as.character(data$stats$due_soon_count[1]))
      }
      return("0")
    })
    
    # 总预算
    output$total_budget <- renderText({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$stats) && nrow(data$stats) > 0) {
        return(format_currency(data$stats$total_budget[1]))
      }
      return("¥0.00")
    })
    
    # 项目类型分布图
    output$type_distribution <- renderPlot({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$type_distribution) && nrow(data$type_distribution) > 0) {
        # 验证数据
        if (!is.numeric(data$type_distribution$count)) {
          log_warn("type_distribution$count 不是数值类型，尝试转换")
          data$type_distribution$count <- as.numeric(data$type_distribution$count)
        }
        
        # 检查是否有NA值
        if (any(is.na(data$type_distribution$count))) {
          log_warn("type_distribution$count 包含NA值，替换为0")
          data$type_distribution$count[is.na(data$type_distribution$count)] <- 0
        }
        
        # 设置图形参数
        par(mar = c(5, 8, 2, 2))
        
        # 创建颜色向量
        colors <- c("#667eea", "#2ecc71", "#f39c12", "#e74c3c", "#3498db", "#9b59b6", "#1abc9c")
        colors <- colors[1:nrow(data$type_distribution)]
        
        # 绘制条形图
        barplot(
          height = data$type_distribution$count,
          names.arg = data$type_distribution$type_name,
          col = colors,
          border = NA,
          las = 1,
          horiz = TRUE,
          xlab = "项目数量",
          main = "",
          cex.names = 0.9
        )
      } else {
        # 无数据时显示空白图
        plot.new()
        text(0.5, 0.5, "暂无数据", cex = 1.5, col = "gray")
        box()
      }
    })
    
    # 项目状态分布图
    output$status_distribution <- renderPlot({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$status_distribution) && nrow(data$status_distribution) > 0) {
        # 验证数据
        if (!is.numeric(data$status_distribution$count)) {
          log_warn("status_distribution$count 不是数值类型，尝试转换")
          data$status_distribution$count <- as.numeric(data$status_distribution$count)
        }
        
        # 检查是否有NA值
        if (any(is.na(data$status_distribution$count))) {
          log_warn("status_distribution$count 包含NA值，替换为0")
          data$status_distribution$count[is.na(data$status_distribution$count)] <- 0
        }
        
        # 创建颜色映射
        status_colors <- list(
          "规划中" = "#3498db",
          "进行中" = "#2ecc71",
          "暂停" = "#f39c12",
          "已完成" = "#95a5a6",
          "已取消" = "#e74c3c"
        )
        
        # 根据状态名称获取颜色
        colors <- sapply(data$status_distribution$status_name, function(status) {
          if (status %in% names(status_colors)) {
            return(status_colors[[status]])
          } else {
            return("#999999")  # 默认颜色
          }
        })
        
        # 绘制饼图
        pie(
          data$status_distribution$count,
          labels = paste0(data$status_distribution$status_name, "\n(", 
                          data$status_distribution$count, ")"),
          col = colors,
          border = "white",
          main = "",
          cex = 0.8
        )
      } else {
        # 无数据时显示空白图
        plot.new()
        text(0.5, 0.5, "暂无数据", cex = 1.5, col = "gray")
        box()
      }
    })
    
    # 最近项目表格
    output$recent_projects_table <- renderDT({
      data <- dashboard_data()
      if (!is.null(data) && !is.null(data$recent_projects) && nrow(data$recent_projects) > 0) {
        df <- data$recent_projects
        
        # 格式化日期
        format_date_column <- function(date_col) {
          sapply(date_col, function(x) {
            if (is.na(x) || is.null(x)) {
              return("")
            } else {
              return(format(as.Date(x), "%Y-%m-%d"))
            }
          })
        }
        
        df$budget <- sapply(df$budget, format_currency)
        df$start_date <- format_date_column(df$start_date)
        df$created_at <- format(as.POSIXct(df$created_at), "%Y-%m-%d %H:%M")
        
        # 重命名列
        colnames(df) <- c("项目编号", "项目名称", "项目类型", "状态", "预算", "开始日期", "创建时间")
        
        # 创建数据表格
        datatable(
          df,
          options = list(
            pageLength = 5,
            lengthChange = FALSE,
            searching = FALSE,
            ordering = TRUE,
            order = list(list(6, 'desc')),  # 按创建时间降序
            info = FALSE,
            dom = 'tp',
            language = list(
              url = '//cdn.datatables.net/plug-ins/1.10.24/i18n/Chinese.json'
            )
          ),
          rownames = FALSE,
          class = 'cell-border stripe hover'
        ) %>%
          formatStyle(
            columns = "项目编号",
            backgroundColor = '#f8f9fa',
            fontWeight = 'bold'
          )
      } else {
        # 无数据时显示提示
        datatable(
          data.frame(
            提示 = "暂无近期项目数据",
            说明 = "请创建新项目或确保数据库中有活动项目"
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
        )
      }
    })
  })
}