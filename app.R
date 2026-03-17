# ==================== 科研项目管理系统主程序 ====================
# 系统名称：Research Project Management System
# 版本：1.0.0
# 创建时间：2026-01-15
# 
# 功能说明：
# - 基于R Shiny的科研项目管理系统
# - 支持项目CRUD操作、数据筛选、统计分析、报告生成
# - 使用PostgreSQL数据库
# - 模块化设计，便于维护和扩展
# ==============================================================

# ==================== 加载全局配置 ====================
source("global.R")

# ==================== 加载模块 ====================
source("modules/auth_module.R")
source("modules/project_code_generator.R")
source("modules/dashboard_module.R")
source("modules/project_module.R")
source("modules/reports_module.R")
source("modules/attachment_module.R") 

log_info("所有模块加载完成")

# ==================== 用户界面 (UI) ====================
ui <- dashboardPage(
  skin = "purple",
  
  # ==================== 头部 ====================
  dashboardHeader(
    title = div(
      class = "logo-title-container",
      style = "display: flex; align-items: center; height: 100%; padding: 5px 0;",
      # Logo图片
      if (file.exists("www/logo.png")) {
        tags$img(
          src = "logo.png",
          style = "height: 40px; width: auto; margin-right: 15px; object-fit: contain;",
          alt = "Logo"
        )
      },
      # 应用标题
      span(
        style = "font-size: 20px; font-weight: 600; color: #fff; white-space: nowrap;",
        APP_NAME
      )
    ),
    titleWidth = 350
  ),
  
  # ==================== 侧边栏 ====================
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "sidebar_menu",
      menuItem(
        text = "仪表板",
        tabName = "dashboard",
        icon = icon("tachometer-alt")
      ),
      menuItem(
        text = "项目管理",
        tabName = "projects",
        icon = icon("folder-open")
      ),
      menuItem(
        text = "报告生成",
        tabName = "reports",
        icon = icon("file-alt")
      ),
      menuItem(
        text = "系统帮助",
        tabName = "help",
        icon = icon("question-circle")
      ),
      
      # 分隔线
      br(),
      hr(),
      
      # 系统信息
      div(
        style = "padding: 15px; color: #999; font-size: 12px;",
        p(sprintf("版本: %s", APP_VERSION)),
        p(sprintf("用户: %s", ifelse(DEBUG_MODE, "调试模式", "未登录"))),
        if (DEBUG_MODE) {
          p(
            style = "color: #f39c12;",
            icon("exclamation-triangle"),
            " 调试模式"
          )
        }
      )
    )
  ),
  
  # ==================== 主体内容 ====================
  dashboardBody(
    # 加载自定义CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
      # 浏览器标签页图标
      if (file.exists("www/logo_tab.png")) {
        tags$link(rel = "icon", type = "image/png", href = "logo_tab.png")
      },
      # 添加响应式CSS
      tags$style(HTML("
    @media (max-width: 768px) {
      .logo-title-container img {
        height: 30px !important;
        margin-right: 10px !important;
      }
      .logo-title-container span {
        font-size: 16px !important;
      }
    }
  ")),
      tags$script(HTML("
    // 全局项目操作按钮处理函数
    function handleViewProject(projectId) {
      Shiny.setInputValue('view_project', projectId, {priority: 'event'});
    }
    
    function handleEditProject(projectId) {
      Shiny.setInputValue('edit_project', projectId, {priority: 'event'});
    }
    
    function handleManageAttachments(projectId) {
      Shiny.setInputValue('manage_attachments', projectId, {priority: 'event'});
    }
    
    function handleDeleteProject(projectId) {
      Shiny.setInputValue('delete_project', projectId, {priority: 'event'});
    }
    
    // 文档管理相关函数
    function previewDocument(documentId) {
      Shiny.setInputValue('preview_document', documentId, {priority: 'event'});
    }
    
    function downloadDocument(documentId) {
      Shiny.setInputValue('download_document', documentId, {priority: 'event'});
    }
    
    function deleteDocument(documentId) {
      if (confirm('确定要删除这个文档吗？此操作不可撤销。')) {
        Shiny.setInputValue('delete_document', documentId, {priority: 'event'});
      }
    }
    
    // 项目表格按钮点击处理
    $(document).ready(function() {
      // 使用事件委托处理动态生成的按钮
      $(document).on('click', '.project-view-btn', function() {
        var projectId = $(this).data('project-id');
        if (projectId) {
          Shiny.setInputValue('view_project', projectId, {priority: 'event'});
        }
      });
      
      $(document).on('click', '.project-edit-btn', function() {
        var projectId = $(this).data('project-id');
        if (projectId) {
          Shiny.setInputValue('edit_project', projectId, {priority: 'event'});
        }
      });
      
      $(document).on('click', '.project-attach-btn', function() {
        var projectId = $(this).data('project-id');
        if (projectId) {
          Shiny.setInputValue('manage_attachments', projectId, {priority: 'event'});
        }
      });
      
      $(document).on('click', '.project-delete-btn', function() {
        var projectId = $(this).data('project-id');
        if (projectId) {
          Shiny.setInputValue('delete_project', projectId, {priority: 'event'});
        }
      });
      
      // 文件上传区域美化
      $('.shiny-file-input').on('dragover', function(e) {
        e.preventDefault();
        $(this).css('border-color', '#3498db');
      });
      
      $('.shiny-file-input').on('dragleave', function(e) {
        e.preventDefault();
        $(this).css('border-color', '#ccc');
      });
      
      $('.shiny-file-input').on('drop', function(e) {
        e.preventDefault();
        $(this).css('border-color', '#2ecc71');
      });
    });
  ")),
      tags$script(HTML("
    // 文件拖放功能
    $(document).ready(function() {
      // 为所有上传区域添加拖放支持
      function initDropZone(dropZoneId, fileInputId) {
        var dropZone = $('#' + dropZoneId);
        var fileInput = $('#' + fileInputId);
        
        if (dropZone.length && fileInput.length) {
          dropZone.on('dragover', function(e) {
            e.preventDefault();
            e.stopPropagation();
            $(this).addClass('dragover');
          });
          
          dropZone.on('dragleave', function(e) {
            e.preventDefault();
            e.stopPropagation();
            $(this).removeClass('dragover');
          });
          
          dropZone.on('drop', function(e) {
            e.preventDefault();
            e.stopPropagation();
            $(this).removeClass('dragover');
            
            var files = e.originalEvent.dataTransfer.files;
            if (files.length > 0) {
              // 触发文件输入
              fileInput[0].files = files;
              fileInput.trigger('change');
            }
          });
          
          // 点击区域触发文件选择
          dropZone.on('click', function(e) {
            if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'BUTTON') {
              fileInput.trigger('click');
            }
          });
        }
      }
      
      // 初始化所有上传区域
      initDropZone('drop_zone', 'quick_file_input');
      
      // 监听Shiny页面变化，重新初始化
      $(document).on('shiny:connected', function() {
        setTimeout(function() {
          initDropZone('drop_zone', 'quick_file_input');
        }, 500);
      });
    });
  "))
    ),
    
    # 标签页内容
    tabItems(
      # ==================== 仪表板页面 ====================
      tabItem(
        tabName = "dashboard",
        h2(class = "page-title", "项目统计仪表板"),
        dashboard_ui("dashboard_module")
      ),
      
      # ==================== 项目管理页面 ====================
      tabItem(
        tabName = "projects",
        h2(class = "page-title", "项目管理"),
        project_module_ui("project_module")
      ),
      
      # ==================== 报告生成页面 ====================
      tabItem(
        tabName = "reports",
        h2(class = "page-title", "报告生成"),
        reports_ui("reports_module")
      ),
      
      # ==================== 系统帮助页面 ====================
      tabItem(
        tabName = "help",
        h2(class = "page-title", "系统帮助"),
        fluidRow(
          column(
            width = 12,
            div(
              class = "box",
              div(
                class = "box-header",
                h3(class = "box-title", tagList(icon("book"), "使用指南"))
              ),
              div(
                class = "box-body",
                # 读取README.md文件
                if (file.exists("README.md")) {
                  tryCatch({
                    includeMarkdown("README.md")
                  }, error = function(e) {
                    div(
                      class = "alert alert-warning",
                      icon("exclamation-triangle"),
                      " 无法加载帮助文档"
                    )
                  })
                } else {
                  div(
                    class = "alert alert-info",
                    h4("欢迎使用科研项目管理系统"),
                    p("这是一个基于R Shiny的科研项目管理系统，用于管理三甲医院科研实验室的各类科研项目。"),
                    
                    h4("主要功能："),
                    tags$ul(
                      tags$li("项目管理：创建、编辑、查看、删除科研项目"),
                      tags$li("智能编号：自动生成项目编号"),
                      tags$li("数据筛选：多条件组合筛选项目"),
                      tags$li("统计展示：仪表板显示项目统计信息"),
                      tags$li("数据导出：支持CSV和Excel格式导出"),
                      tags$li("报告生成：生成各类项目分析报告")
                    ),
                    
                    h4("快速开始："),
                    tags$ol(
                      tags$li('点击左侧"仪表板"查看项目总览'),
                      tags$li('点击"项目管理"创建或管理项目'),
                      tags$li("使用筛选功能快速查找项目"),
                      tags$li('在"报告生成"页面生成分析报告')
                    ),
                    
                    h4("技术支持："),
                    p("如有问题，请联系系统管理员。")
                  )
                }
              )
            )
          )
        )
      )
    )
  )
)

# ==================== 服务器逻辑 (Server) ====================
server <- function(input, output, session) {
  
  log_info("应用服务器启动")
  
  # ==================== 认证模块 ====================
  # 注意：调试模式下不显示登录框
  auth <- NULL
  if (!DEBUG_MODE) {
    # 显示登录对话框
    showModal(auth_ui("auth_module"))
    auth <- auth_server("auth_module", db_pool = db_pool)
  }
  
  # ==================== 仪表板模块 ====================
  dashboard_server("dashboard_module", db_pool = db_pool)
  
  # ==================== 项目管理模块 ====================
  project_module_server("project_module", db_pool = db_pool)
  
  # ==================== 报告模块 ====================
  reports_server("reports_module", db_pool = db_pool)
  
  # ==================== 会话结束处理 ====================
  session$onSessionEnded(function() {
    log_info("用户会话结束")
  })
  
  # ==================== 错误处理 ====================
  options(shiny.error = function() {
    log_error("应用发生错误")
  })
  
  log_info("服务器初始化完成")
}

# ==================== 运行应用 ====================
shinyApp(ui = ui, server = server)
