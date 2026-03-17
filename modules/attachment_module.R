# ==================== 项目附件管理模块 ====================
# 功能：管理项目的附件（文档）、链接和评论
# 文件：modules/attachment_module.R
# =========================================================

# ==================== 附件管理模块 UI ====================
attachment_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 附件管理面板
    div(
      class = "box box-primary",
      div(
        class = "box-header with-border",
        h3(class = "box-title", tagList(icon("paperclip"), "项目文档管理")),
        div(
          class = "box-tools pull-right",
          tags$button(
            class = "btn btn-box-tool",
            `data-widget` = "collapse",
            tags$i(class = "fa fa-minus")
          )
        )
      ),
      div(
        class = "box-body",
        
        # 操作选项卡
        tabsetPanel(
          id = ns("attachment_tabs"),
          type = "tabs",
          
          # 选项卡1：上传文档
          tabPanel(
            title = tagList(icon("upload"), "上传文档"),
            value = "upload_tab",
            div(
              style = "padding: 20px;",
              
              # 文档信息表单
              fluidRow(
                column(
                  width = 6,
                  textInput(
                    inputId = ns("document_name"),
                    label = "文档名称",
                    placeholder = "请输入文档名称",
                    width = "100%"
                  )
                ),
                column(
                  width = 6,
                  selectInput(
                    inputId = ns("document_type"),
                    label = "文档类型",
                    choices = DOCUMENT_TYPES,
                    selected = "other",
                    width = "100%"
                  )
                )
              ),
              
              fluidRow(
                column(
                  width = 6,
                  textInput(
                    inputId = ns("document_number"),
                    label = "文档编号",
                    placeholder = "如：合同编号、批件号等",
                    width = "100%"
                  )
                ),
                column(
                  width = 6,
                  dateInput(
                    inputId = ns("valid_until"),
                    label = "有效期至",
                    value = NULL,
                    format = "yyyy-mm-dd",
                    width = "100%"
                  )
                )
              ),
              
              textAreaInput(
                inputId = ns("document_description"),
                label = "文档描述",
                placeholder = "请输入文档的详细描述...",
                rows = 3,
                width = "100%"
              ),
              
              # 文件上传
              div(
                class = "well",
                style = "margin-top: 15px;",
                h4(icon("cloud-upload-alt"), "选择文件"),
                helpText(sprintf("最大文件大小: %.0fMB", MAX_FILE_SIZE/1024/1024)),
                
                fileInput(
                  inputId = ns("file_upload"),
                  label = NULL,
                  multiple = FALSE,
                  buttonLabel = tagList(icon("search"), "浏览文件"),
                  accept = NULL,  # 接受所有类型
                  width = "100%"
                ),
                
                # 文件上传进度
                div(
                  id = ns("upload_progress"),
                  style = "display: none;",
                  div(
                    class = "progress",
                    style = "height: 20px; margin-top: 10px;",
                    div(
                      class = "progress-bar progress-bar-striped progress-bar-animated",
                      id = ns("progress_bar"),
                      role = "progressbar",
                      style = "width: 0%;",
                      "0%"
                    )
                  )
                )
              ),
              
              # 其他选项
              fluidRow(
                column(
                  width = 6,
                  checkboxInput(
                    inputId = ns("is_confidential"),
                    label = "机密文件",
                    value = FALSE
                  ),
                  helpText("标记为机密文件，限制访问权限")
                ),
                column(
                  width = 6,
                  textInput(
                    inputId = ns("document_tags"),
                    label = "标签",
                    placeholder = "用逗号分隔多个标签",
                    width = "100%"
                  )
                )
              ),
              
              # 上传按钮
              div(
                style = "text-align: center; margin-top: 20px;",
                actionButton(
                  inputId = ns("upload_btn"),
                  label = tagList(icon("upload"), "上传文档"),
                  class = "btn-primary",
                  disabled = TRUE
                )
              )
            )
          ),
          
          # 选项卡2：项目评论
          tabPanel(
            title = tagList(icon("comment"), "项目评论"),
            value = "comment_tab",
            div(
              style = "padding: 20px;",
              
              # 评论输入区域
              fluidRow(
                column(
                  width = 9,
                  textAreaInput(
                    inputId = ns("comment_content"),
                    label = "评论内容",
                    placeholder = "请输入项目相关的评论、建议或问题反馈...",
                    rows = 4,
                    width = "100%"
                  )
                ),
                column(
                  width = 3,
                  checkboxInput(
                    inputId = ns("comment_internal"),
                    label = "内部评论",
                    value = TRUE
                  ),
                  helpText("内部评论仅系统内可见"),
                  br(),
                  actionButton(
                    inputId = ns("add_comment_btn"),
                    label = tagList(icon("paper-plane"), "发表评论"),
                    class = "btn-info btn-block"
                  )
                )
              ),
              
              hr(),
              
              # 评论列表
              h4("历史评论", style = "margin-top: 20px;"),
              uiOutput(ns("comments_list"))
            )
          ),
          
          # 选项卡3：文档列表
          tabPanel(
            title = tagList(icon("list"), "文档列表"),
            value = "list_tab",
            div(
              style = "padding: 20px;",
              
              # 筛选和搜索
              fluidRow(
                column(
                  width = 3,
                  selectInput(
                    inputId = ns("filter_doc_type"),
                    label = "文档类型",
                    choices = c("全部" = "", DOCUMENT_TYPES),
                    selected = ""
                  )
                ),
                column(
                  width = 3,
                  textInput(
                    inputId = ns("filter_doc_keyword"),
                    label = "关键词搜索",
                    placeholder = "文档名称、编号..."
                  )
                ),
                column(
                  width = 3,
                  dateRangeInput(
                    inputId = ns("filter_doc_date"),
                    label = "上传时间",
                    start = Sys.Date() - 90,
                    end = Sys.Date()
                  )
                ),
                column(
                  width = 3,
                  div(
                    style = "padding-top: 25px;",
                    actionButton(
                      inputId = ns("refresh_docs"),
                      label = tagList(icon("sync-alt"), "刷新"),
                      class = "btn-default btn-sm"
                    )
                  )
                )
              ),
              
              hr(),
              
              # 文档列表
              DTOutput(ns("documents_table")),
              
              # 统计信息
              div(
                style = "margin-top: 20px; padding: 10px; background-color: #f8f9fa; border-radius: 4px;",
                div(
                  id = ns("document_stats"),
                  style = "font-size: 12px; color: #666;"
                )
              )
            )
          ),
          
          # 选项卡4：活动记录
          tabPanel(
            title = tagList(icon("history"), "活动记录"),
            value = "activity_tab",
            div(
              style = "padding: 20px;",
              
              # 活动记录列表
              DTOutput(ns("activity_table")),
              
              # 统计信息
              div(
                style = "margin-top: 20px; padding: 10px; background-color: #f8f9fa; border-radius: 4px;",
                div(
                  id = ns("activity_stats"),
                  style = "font-size: 12px; color: #666;"
                )
              )
            )
          )
        )
      )
    )
  )
}

# ==================== 附件管理模块 Server ====================
attachment_server <- function(id, db_pool = NULL, project_id = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 响应式数据
    documents_data <- reactiveVal(NULL)
    comments_data <- reactiveVal(NULL)
    activity_data <- reactiveVal(NULL)
    current_project_id <- reactiveVal(NULL)
    
    # 监听项目ID变化
    observe({
      if (!is.null(project_id)) {
        current_project_id(project_id())
        load_all_data()
      }
    })
    
    # 加载所有数据
    load_all_data <- function() {
      load_documents()
      load_comments()
      load_activity()
    }
    
    # 加载文档数据
    load_documents <- function(filters = NULL) {
      if (is.null(db_pool) || is.null(current_project_id())) {
        log_warn("数据库连接或项目ID不可用")
        return(NULL)
      }
      
      tryCatch({
        query <- "
          SELECT 
            d.*,
            u.username as uploader_name,
            u.email as uploader_email
          FROM projects.project_documents d
          LEFT JOIN auth.users u ON d.uploader_id = u.user_id
          WHERE d.project_id = $1
        "
        
        params <- list(current_project_id())
        
        # 应用筛选条件
        conditions <- c()
        
        if (!is.null(filters)) {
          # 文档类型筛选
          if (!is.null(filters$type) && filters$type != "") {
            conditions <- c(conditions, sprintf("d.document_type = $%d", length(params) + 1))
            params <- c(params, list(filters$type))
          }
          
          # 关键词搜索
          if (!is.null(filters$keyword) && trimws(filters$keyword) != "") {
            keyword <- paste0("%", trimws(filters$keyword), "%")
            conditions <- c(conditions, sprintf("(d.document_name ILIKE $%d OR d.document_number ILIKE $%d)", 
                                                length(params) + 1, length(params) + 2))
            params <- c(params, list(keyword, keyword))
          }
          
          # 时间范围筛选
          if (!is.null(filters$date_start)) {
            conditions <- c(conditions, sprintf("d.upload_date >= $%d", length(params) + 1))
            params <- c(params, list(filters$date_start))
          }
          if (!is.null(filters$date_end)) {
            conditions <- c(conditions, sprintf("d.upload_date <= $%d", length(params) + 1))
            params <- c(params, list(filters$date_end))
          }
        }
        
        # 添加WHERE条件
        if (length(conditions) > 0) {
          query <- paste(query, "AND", paste(conditions, collapse = " AND "))
        }
        
        query <- paste(query, "ORDER BY d.upload_date DESC")
        
        # 执行查询
        documents <- dbGetQuery(db_pool, query, params = params)
        documents_data(documents)
        
        return(documents)
      }, error = function(e) {
        log_error(sprintf("加载文档数据失败: %s", e$message))
        showNotification("加载文档数据失败", type = "error")
        return(NULL)
      })
    }
    
    # 加载评论数据
    load_comments <- function() {
      if (is.null(db_pool) || is.null(current_project_id())) {
        return(NULL)
      }
      
      tryCatch({
        query <- "
          SELECT 
            c.*,
            u.username as author_name,
            u.email as author_email
          FROM projects.project_comments c
          LEFT JOIN auth.users u ON c.user_id = u.user_id
          WHERE c.project_id = $1
          ORDER BY c.created_at DESC
        "
        
        comments <- dbGetQuery(db_pool, query, params = list(current_project_id()))
        comments_data(comments)
        
        return(comments)
      }, error = function(e) {
        log_error(sprintf("加载评论数据失败: %s", e$message))
        return(NULL)
      })
    }
    
    # 加载活动记录
    load_activity <- function() {
      if (is.null(db_pool) || is.null(current_project_id())) {
        return(NULL)
      }
      
      tryCatch({
        query <- "
          SELECT 
            c.*,
            u.username as changed_by_name
          FROM projects.project_changes c
          LEFT JOIN auth.users u ON c.changed_by = u.user_id
          WHERE c.project_id = $1
          ORDER BY c.changed_at DESC
          LIMIT 100
        "
        
        activity <- dbGetQuery(db_pool, query, params = list(current_project_id()))
        activity_data(activity)
        
        return(activity)
      }, error = function(e) {
        log_error(sprintf("加载活动记录失败: %s", e$message))
        return(NULL)
      })
    }
    
    # 显示文件信息
    observe({
      file <- input$file_upload
      if (is.null(file)) {
        shinyjs::disable("upload_btn")
        return()
      }
      
      # 检查文件大小
      if (file$size > MAX_FILE_SIZE) {
        showNotification(
          sprintf("文件大小超出限制 (%.1fMB > %.0fMB)", 
                  file$size/1024/1024, MAX_FILE_SIZE/1024/1024),
          type = "error"
        )
        shinyjs::disable("upload_btn")
        return()
      }
      
      # 更新文档名称（如果为空）
      if (is.null(input$document_name) || trimws(input$document_name) == "") {
        updateTextInput(session, "document_name", value = tools::file_path_sans_ext(file$name))
      }
      
      shinyjs::enable("upload_btn")
    })
    
    # 上传文档
    observeEvent(input$upload_btn, {
      file <- input$file_upload
      if (is.null(file) || is.null(current_project_id())) {
        showNotification("请选择文件", type = "warning")
        return()
      }
      
      # 验证输入
      if (is.null(input$document_name) || trimws(input$document_name) == "") {
        showNotification("请输入文档名称", type = "warning")
        return()
      }
      
      tryCatch({
        # 显示上传进度
        shinyjs::show("upload_progress")
        updateProgressBar()
        
        # 生成安全的文件名
        safe_filename <- generate_safe_filename(file$name)
        
        # 创建项目目录
        project_dir <- file.path(NFS_BASE_PATH, current_project_id())
        dir.create(project_dir, showWarnings = FALSE, recursive = TRUE)
        
        # 目标路径
        dest_path <- file.path(project_dir, safe_filename)
        
        # 复制文件到NFS
        file.copy(file$datapath, dest_path)
        
        # 处理标签
        tags <- NULL
        if (!is.null(input$document_tags) && trimws(input$document_tags) != "") {
          tags <- unlist(strsplit(trimws(input$document_tags), ","))
          tags <- trimws(tags)
          tags <- tags[tags != ""]
        }
        
        # 插入数据库记录
        dbExecute(db_pool, "
          INSERT INTO projects.project_documents 
          (project_id, document_type, document_name, document_number, 
           file_path, file_size, mime_type, uploader_id, description, 
           tags, is_confidential, valid_until)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ", params = list(
          current_project_id(),
          input$document_type,
          trimws(input$document_name),
          ifelse(!is.null(input$document_number) && trimws(input$document_number) != "", 
                 trimws(input$document_number), NULL),
          dest_path,
          file$size,
          file$type,
          1,  # 当前用户ID，从session获取
          ifelse(!is.null(input$document_description) && trimws(input$document_description) != "", 
                 trimws(input$document_description), NULL),
          ifelse(length(tags) > 0, paste(tags, collapse = ","), NULL),
          input$is_confidential,
          ifelse(!is.null(input$valid_until), input$valid_until, NULL)
        ))
        
        # 记录活动
        record_activity(
          change_type = "document_upload",
          table_name = "project_documents",
          field_name = "file_path",
          new_value = dest_path,
          change_reason = sprintf("上传文档: %s", input$document_name)
        )
        
        # 清空表单
        shinyjs::reset("file_upload")
        updateTextInput(session, "document_name", value = "")
        updateTextInput(session, "document_number", value = "")
        updateTextAreaInput(session, "document_description", value = "")
        updateTextInput(session, "document_tags", value = "")
        updateCheckboxInput(session, "is_confidential", value = FALSE)
        updateDateInput(session, "valid_until", value = NULL)
        
        shinyjs::disable("upload_btn")
        shinyjs::hide("upload_progress")
        
        # 刷新数据
        load_documents()
        
        showNotification("文档上传成功", type = "success")
        log_info(sprintf("文档上传成功: %s -> %s", file$name, dest_path))
        
      }, error = function(e) {
        shinyjs::hide("upload_progress")
        showNotification(sprintf("上传失败: %s", e$message), type = "error")
        log_error(sprintf("文档上传失败: %s", e$message))
      })
    })
    
    # 更新进度条
    updateProgressBar <- function(value = 0) {
      shinyjs::html("progress_bar", sprintf("%d%%", value))
      shinyjs::runjs(sprintf('$("#%s").css("width", "%d%%");', ns("progress_bar"), value))
      
      if (value < 100) {
        later::later(function() updateProgressBar(value + 10), 0.1)
      }
    }
    
    # 添加评论
    observeEvent(input$add_comment_btn, {
      if (is.null(current_project_id()) || 
          is.null(input$comment_content) || trimws(input$comment_content) == "") {
        showNotification("请填写评论内容", type = "warning")
        return()
      }
      
      tryCatch({
        dbExecute(db_pool, "
          INSERT INTO projects.project_comments 
          (project_id, user_id, content, is_internal)
          VALUES ($1, $2, $3, $4)
        ", params = list(
          current_project_id(),
          1,  # 当前用户ID
          trimws(input$comment_content),
          input$comment_internal
        ))
        
        # 记录活动
        record_activity(
          change_type = "comment_added",
          table_name = "project_comments",
          new_value = substr(trimws(input$comment_content), 1, 100),
          change_reason = "添加项目评论"
        )
        
        # 清空表单
        updateTextAreaInput(session, "comment_content", value = "")
        
        # 刷新数据
        load_comments()
        
        showNotification("评论发表成功", type = "success")
        log_info("评论发表成功")
        
      }, error = function(e) {
        showNotification(sprintf("发表评论失败: %s", e$message), type = "error")
        log_error(sprintf("发表评论失败: %s", e$message))
      })
    })
    
    # 记录活动
    record_activity <- function(change_type, table_name = NULL, record_id = NULL, 
                                field_name = NULL, old_value = NULL, new_value = NULL,
                                change_reason = NULL) {
      if (is.null(db_pool) || is.null(current_project_id())) return()
      
      tryCatch({
        dbExecute(db_pool, "
          INSERT INTO projects.project_changes 
          (project_id, change_type, table_name, record_id, field_name, 
           old_value, new_value, change_reason, changed_by)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ", params = list(
          current_project_id(),
          change_type,
          table_name,
          record_id,
          field_name,
          old_value,
          new_value,
          change_reason,
          1  # 当前用户ID
        ))
      }, error = function(e) {
        log_error(sprintf("记录活动失败: %s", e$message))
      })
    }
    
    # 渲染评论列表
    output$comments_list <- renderUI({
      comments <- comments_data()
      
      if (is.null(comments) || nrow(comments) == 0) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            "暂无评论"
          )
        )
      }
      
      comment_items <- lapply(1:nrow(comments), function(i) {
        comment <- comments[i, ]
        
        div(
          class = "panel panel-default",
          style = "margin-bottom: 10px;",
          div(
            class = "panel-heading",
            style = "padding: 10px 15px; background-color: #f5f5f5;",
            div(
              style = "display: flex; justify-content: space-between;",
              div(
                style = "font-weight: bold;",
                icon("user-circle"),
                comment$author_name,
                if (comment$is_internal) {
                  span(
                    class = "label label-warning",
                    style = "margin-left: 10px; font-size: 10px;",
                    "内部"
                  )
                }
              ),
              div(
                style = "font-size: 12px; color: #666;",
                format(comment$created_at, "%Y-%m-%d %H:%M")
              )
            )
          ),
          div(
            class = "panel-body",
            style = "padding: 15px; white-space: pre-wrap;",
            comment$content
          )
        )
      })
      
      do.call(tagList, comment_items)
    })
    
    # 渲染文档表格
    output$documents_table <- renderDT({
      data <- documents_data()
      if (!is.null(data) && nrow(data) > 0) {
        # 准备显示数据
        display_data <- data
        
        # 格式化文件大小
        display_data$file_size_display <- sapply(display_data$file_size, format_file_size)
        
        # 格式化日期
        display_data$upload_date_formatted <- format(
          display_data$upload_date, "%Y-%m-%d %H:%M"
        )
        
        if (!is.null(display_data$valid_until)) {
          display_data$valid_until_formatted <- format(
            as.Date(display_data$valid_until), "%Y-%m-%d"
          )
        } else {
          display_data$valid_until_formatted <- ""
        }
        
        # 创建文档图标和预览
        display_data$document_preview <- sapply(1:nrow(display_data), function(i) {
          doc_name <- display_data$document_name[i]
          doc_type <- display_data$document_type[i]
          doc_number <- display_data$document_number[i]
          file_size <- display_data$file_size_display[i]
          
          icon_type <- get_file_icon(display_data$document_name[i])
          icon_color <- get_file_color(display_data$document_name[i])
          
          doc_type_text <- ifelse(doc_type %in% names(DOCUMENT_TYPES), 
                                  DOCUMENT_TYPES[[doc_type]], doc_type)
          
          html <- sprintf('
            <div class="document-item">
              <div style="display: flex; align-items: center;">
                <i class="fa fa-%s text-%s fa-2x" style="margin-right: 10px;"></i>
                <div>
                  <strong>%s</strong><br>
                  <small class="text-muted">
                    <span class="label label-default">%s</span>
                    %s
                    %s
                  </small>
                </div>
              </div>
            </div>',
                          icon_type, icon_color,
                          doc_name,
                          doc_type_text,
                          ifelse(!is.na(doc_number) && doc_number != "", 
                                 sprintf(" | 编号: %s", doc_number), ""),
                          ifelse(!is.na(file_size) && file_size != "0 B", 
                                 sprintf(" | 大小: %s", file_size), "")
          )
          
          return(html)
        })
        
        # 操作按钮
        display_data$actions <- sapply(1:nrow(display_data), function(i) {
          document_id <- display_data$document_id[i]
          file_path <- display_data$file_path[i]
          doc_name <- display_data$document_name[i]
          
          buttons <- list()
          
          # 下载按钮
          buttons <- c(buttons,
                       sprintf('<button class="btn btn-xs btn-success" title="下载" onclick="downloadDocument(%d)">
                      <i class="fa fa-download"></i>
                    </button>', document_id)
          )
          
          # 预览按钮（如果是PDF或图片）
          file_ext <- tolower(tools::file_ext(doc_name))
          if (file_ext %in% c("pdf", "jpg", "jpeg", "png", "gif")) {
            buttons <- c(buttons,
                         sprintf('<button class="btn btn-xs btn-info" title="预览" onclick="previewDocument(%d)">
                        <i class="fa fa-eye"></i>
                      </button>', document_id)
            )
          }
          
          # 删除按钮
          buttons <- c(buttons,
                       sprintf('<button class="btn btn-xs btn-danger" title="删除" onclick="deleteDocument(%d)">
                      <i class="fa fa-trash"></i>
                    </button>', document_id)
          )
          
          # 机密文件标记
          if (!is.na(display_data$is_confidential[i]) && display_data$is_confidential[i]) {
            buttons <- c(
              sprintf('<span class="label label-danger" style="margin-right: 5px;">机密</span>'),
              buttons
            )
          }
          
          paste(buttons, collapse = " ")
        })
        
        # 选择显示列
        display_cols <- c("document_preview", "uploader_name", "upload_date_formatted", 
                          "valid_until_formatted", "actions")
        display_data <- display_data[, display_cols, drop = FALSE]
        
        # 设置列名
        colnames(display_data) <- c("文档信息", "上传者", "上传时间", "有效期", "操作")
        
        # 创建数据表
        datatable(
          display_data,
          escape = FALSE,
          options = list(
            pageLength = 10,
            lengthMenu = c(10, 25, 50),
            searching = TRUE,
            ordering = TRUE,
            order = list(list(2, 'desc')),
            scrollX = TRUE,
            language = list(
              url = '//cdn.datatables.net/plug-ins/1.10.24/i18n/Chinese.json'
            ),
            columnDefs = list(
              list(width = '35%', targets = 0),
              list(width = '15%', targets = 1),
              list(width = '15%', targets = 2),
              list(width = '10%', targets = 3),
              list(width = '25%', targets = 4)
            )
          ),
          rownames = FALSE,
          class = 'cell-border stripe hover'
        )
      } else {
        datatable(
          data.frame(
            提示 = "暂无文档数据",
            建议 = "点击'上传文档'选项卡上传项目相关文档"
          ),
          options = list(
            dom = 't',
            ordering = FALSE,
            searching = FALSE
          ),
          rownames = FALSE
        )
      }
    })
    
    # 渲染活动记录表格
    output$activity_table <- renderDT({
      data <- activity_data()
      if (!is.null(data) && nrow(data) > 0) {
        # 准备显示数据
        display_data <- data
        
        # 格式化日期
        display_data$changed_at_formatted <- format(
          display_data$changed_at, "%Y-%m-%d %H:%M:%S"
        )
        
        # 创建活动描述
        display_data$activity_description <- sapply(1:nrow(display_data), function(i) {
          change_type <- display_data$change_type[i]
          table_name <- display_data$table_name[i]
          changed_by <- display_data$changed_by_name[i]
          
          descriptions <- list(
            "document_upload" = "上传了文档",
            "comment_added" = "添加了评论",
            "project_created" = "创建了项目",
            "project_updated" = "更新了项目信息",
            "status_changed" = "更改了项目状态",
            "budget_updated" = "更新了预算信息"
          )
          
          description <- ifelse(change_type %in% names(descriptions), 
                                descriptions[[change_type]], 
                                "执行了操作")
          
          return(sprintf("%s %s", changed_by, description))
        })
        
        # 创建详情预览
        display_data$details <- sapply(1:nrow(display_data), function(i) {
          old_value <- display_data$old_value[i]
          new_value <- display_data$new_value[i]
          change_reason <- display_data$change_reason[i]
          
          details <- ""
          
          if (!is.na(change_reason) && change_reason != "") {
            details <- sprintf("<div><strong>原因:</strong> %s</div>", change_reason)
          }
          
          if (!is.na(old_value) && !is.na(new_value) && old_value != "" && new_value != "") {
            details <- paste0(details, 
                              sprintf("<div><strong>变更:</strong> %s → %s</div>", 
                                      substr(old_value, 1, 50), substr(new_value, 1, 50)))
          }
          
          if (details == "") details <- "无详细变更信息"
          
          return(details)
        })
        
        # 选择显示列
        display_cols <- c("activity_description", "details", "changed_at_formatted")
        display_data <- display_data[, display_cols, drop = FALSE]
        
        # 设置列名
        colnames(display_data) <- c("活动描述", "变更详情", "时间")
        
        # 创建数据表
        datatable(
          display_data,
          escape = FALSE,
          options = list(
            pageLength = 10,
            lengthMenu = c(10, 25, 50),
            searching = TRUE,
            ordering = TRUE,
            order = list(list(2, 'desc')),
            scrollX = TRUE,
            language = list(
              url = '//cdn.datatables.net/plug-ins/1.10.24/i18n/Chinese.json'
            ),
            columnDefs = list(
              list(width = '25%', targets = 0),
              list(width = '55%', targets = 1),
              list(width = '20%', targets = 2)
            )
          ),
          rownames = FALSE,
          class = 'cell-border stripe hover'
        )
      } else {
        datatable(
          data.frame(
            提示 = "暂无活动记录",
            说明 = "项目相关的操作将被记录在这里"
          ),
          options = list(
            dom = 't',
            ordering = FALSE,
            searching = FALSE
          ),
          rownames = FALSE
        )
      }
    })
    
    # 更新统计信息
    observe({
      docs <- documents_data()
      comments <- comments_data()
      activity <- activity_data()
      
      if (!is.null(docs) && nrow(docs) > 0) {
        # 文档统计
        doc_stats <- table(docs$document_type)
        doc_types_text <- sapply(names(doc_stats), function(type) {
          type_name <- ifelse(type %in% names(DOCUMENT_TYPES), 
                              DOCUMENT_TYPES[[type]], type)
          sprintf("%s: %d", type_name, doc_stats[type])
        })
        
        output$document_stats <- renderText({
          sprintf("文档总计: %d 个 | %s", 
                  nrow(docs),
                  paste(doc_types_text, collapse = " | "))
        })
      }
      
      if (!is.null(activity) && nrow(activity) > 0) {
        # 活动统计
        output$activity_stats <- renderText({
          sprintf("最近活动: %d 条记录 | 最近更新: %s", 
                  nrow(activity),
                  format(max(activity$changed_at), "%Y-%m-%d %H:%M"))
        })
      }
    })
    
    # 刷新文档按钮
    observeEvent(input$refresh_docs, {
      filters <- list(
        type = input$filter_doc_type,
        keyword = input$filter_doc_keyword,
        date_start = input$filter_doc_date[1],
        date_end = input$filter_doc_date[2]
      )
      
      load_documents(filters)
      showNotification("文档列表已刷新", type = "message")
    })
    
    # 初始加载
    observe({
      if (!is.null(current_project_id())) {
        load_all_data()
      }
    })
    
    # 返回公共方法
    list(
      refresh = function() {
        load_all_data()
      }
    )
  })
  
  
  # 下载文档
  observeEvent(input$download_document, {
    if (is.null(db_pool) || is.null(input$download_document)) return()
    
    tryCatch({
      # 获取文档信息
      query <- "SELECT * FROM projects.project_documents WHERE document_id = $1"
      doc <- dbGetQuery(db_pool, query, params = list(input$download_document))
      
      if (nrow(doc) == 0) {
        showNotification("文档不存在", type = "error")
        return()
      }
      
      # 检查文件是否存在
      if (!file.exists(doc$file_path)) {
        showNotification("文件不存在或已被删除", type = "error")
        return()
      }
      
      # 提供下载
      output$download_handler <- downloadHandler(
        filename = function() {
          doc$document_name
        },
        content = function(file) {
          file.copy(doc$file_path, file)
        },
        contentType = doc$mime_type
      )
      
      # 触发下载
      session$sendCustomMessage("triggerDownload", list(
        filename = doc$document_name
      ))
      
      # 记录活动
      record_activity(
        change_type = "document_downloaded",
        table_name = "project_documents",
        record_id = doc$document_id,
        new_value = doc$document_name,
        change_reason = "下载文档"
      )
      
    }, error = function(e) {
      showNotification(sprintf("下载失败: %s", e$message), type = "error")
      log_error(sprintf("文档下载失败: %s", e$message))
    })
  })
  
  # 预览文档（仅支持PDF和图片）
  observeEvent(input$preview_document, {
    if (is.null(db_pool) || is.null(input$preview_document)) return()
    
    tryCatch({
      # 获取文档信息
      query <- "SELECT * FROM projects.project_documents WHERE document_id = $1"
      doc <- dbGetQuery(db_pool, query, params = list(input$preview_document))
      
      if (nrow(doc) == 0) {
        showNotification("文档不存在", type = "error")
        return()
      }
      
      # 检查文件类型
      file_ext <- tolower(tools::file_ext(doc$document_name))
      
      if (file_ext == "pdf") {
        # 显示PDF预览模态框
        showModal(modalDialog(
          title = tagList(icon("file-pdf"), "PDF预览"),
          size = "l",
          easyClose = TRUE,
          tags$iframe(
            src = paste0("data:", doc$mime_type, ";base64,", 
                         base64enc::base64encode(doc$file_path)),
            style = "width: 100%; height: 600px; border: none;"
          ),
          footer = tagList(
            modalButton("关闭"),
            downloadButton(
              outputId = ns("download_from_preview"),
              label = tagList(icon("download"), "下载"),
              class = "btn-primary"
            )
          )
        ))
      } else if (file_ext %in% c("jpg", "jpeg", "png", "gif")) {
        # 显示图片预览模态框
        showModal(modalDialog(
          title = tagList(icon("file-image"), "图片预览"),
          size = "l",
          easyClose = TRUE,
          tags$img(
            src = paste0("data:", doc$mime_type, ";base64,", 
                         base64enc::base64encode(doc$file_path)),
            style = "width: 100%; height: auto; max-height: 80vh; object-fit: contain;"
          ),
          footer = tagList(
            modalButton("关闭"),
            downloadButton(
              outputId = ns("download_from_preview"),
              label = tagList(icon("download"), "下载"),
              class = "btn-primary"
            )
          )
        ))
      } else {
        showNotification("该文件类型不支持在线预览", type = "info")
      }
      
    }, error = function(e) {
      showNotification(sprintf("预览失败: %s", e$message), type = "error")
      log_error(sprintf("文档预览失败: %s", e$message))
    })
  })
  
  # 在 attachment_server 函数末尾
  # 返回公共方法
  return(
    list(
      refresh = function() {
        log_info("调用附件模块刷新方法")
        if (!is.null(current_project_id())) {
          load_all_data()
          return(TRUE)
        }
        return(FALSE)
      },
      
      # 可选：添加其他方法
      get_project_id = function() {
        return(current_project_id())
      }
    )
  )
}