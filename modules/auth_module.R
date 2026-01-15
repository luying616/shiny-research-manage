# ==================== 认证模块 ====================
# 功能：用户登录/登出功能
# 文件：modules/auth_module.R
# ===================================================

# ==================== 认证模块 UI ====================
auth_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 登录模态框
    modalDialog(
      title = tagList(
        icon("lock"),
        "用户登录"
      ),
      size = "s",
      footer = NULL,
      easyClose = FALSE,
      
      # 登录表单
      div(
        class = "login-form",
        style = "padding: 20px;",
        
        # 用户名输入
        textInput(
          inputId = ns("username"),
          label = tagList(icon("user"), "用户名"),
          placeholder = "请输入用户名",
          width = "100%"
        ),
        
        # 密码输入
        passwordInput(
          inputId = ns("password"),
          label = tagList(icon("key"), "密码"),
          placeholder = "请输入密码",
          width = "100%"
        ),
        
        # 错误提示区域
        uiOutput(ns("login_error")),
        
        # 登录按钮
        div(
          style = "text-align: center; margin-top: 20px;",
          actionButton(
            inputId = ns("login_btn"),
            label = tagList(icon("sign-in-alt"), "登录"),
            class = "btn-primary btn-lg",
            width = "100%"
          )
        ),
        
        # 调试模式提示
        if (exists("DEBUG_MODE") && DEBUG_MODE) {
          div(
            style = "margin-top: 20px; padding: 10px; background-color: #fff3cd; border: 1px solid #ffc107; border-radius: 4px;",
            icon("exclamation-triangle"),
            strong(" 调试模式："),
            "认证功能已禁用，可直接关闭此窗口使用系统"
          )
        }
      )
    )
  )
}

# ==================== 认证模块 Server ====================
auth_server <- function(id, db_pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 认证状态
    auth_status <- reactiveVal(FALSE)
    current_user <- reactiveVal(NULL)
    
    # 登录错误信息
    output$login_error <- renderUI({
      if (!is.null(input$login_attempt) && input$login_attempt > 0) {
        if (!auth_status()) {
          div(
            class = "alert alert-danger",
            style = "margin-top: 10px;",
            icon("exclamation-circle"),
            " 用户名或密码错误，请重试"
          )
        }
      }
    })
    
    # 登录按钮点击事件
    observeEvent(input$login_btn, {
      username <- trimws(input$username)
      password <- input$password
      
      # 验证输入
      if (username == "" || password == "") {
        showNotification(
          "请输入用户名和密码",
          type = "warning",
          duration = 3
        )
        return()
      }
      
      # 调试模式直接通过
      if (exists("DEBUG_MODE") && DEBUG_MODE) {
        auth_status(TRUE)
        current_user(list(
          username = username,
          role = "admin",
          email = "debug@example.com"
        ))
        removeModal()
        showNotification(
          sprintf("欢迎，%s（调试模式）", username),
          type = "message",
          duration = 3
        )
        log_info(sprintf("用户登录成功（调试模式）: %s", username))
        return()
      }
      
      # 数据库验证
      if (!is.null(db_pool)) {
        tryCatch({
          # 查询用户
          query <- "
            SELECT user_id, username, email, password_hash, role, department, is_active
            FROM auth.users
            WHERE username = $1 AND is_active = TRUE
          "
          
          user_data <- dbGetQuery(db_pool, query, params = list(username))
          
          if (nrow(user_data) == 0) {
            log_warn(sprintf("登录失败：用户不存在或未激活 - %s", username))
            showNotification(
              "用户名或密码错误",
              type = "error",
              duration = 3
            )
            return()
          }
          
          # 验证密码
          if (verify_password(password, user_data$password_hash[1])) {
            auth_status(TRUE)
            current_user(list(
              user_id = user_data$user_id[1],
              username = user_data$username[1],
              email = user_data$email[1],
              role = user_data$role[1],
              department = user_data$department[1]
            ))
            
            # 更新最后活动时间
            update_query <- "
              UPDATE auth.users 
              SET last_activity = CURRENT_TIMESTAMP 
              WHERE user_id = $1
            "
            dbExecute(db_pool, update_query, params = list(user_data$user_id[1]))
            
            removeModal()
            showNotification(
              sprintf("欢迎，%s", username),
              type = "message",
              duration = 3
            )
            log_info(sprintf("用户登录成功: %s (ID: %d)", username, user_data$user_id[1]))
          } else {
            log_warn(sprintf("登录失败：密码错误 - %s", username))
            showNotification(
              "用户名或密码错误",
              type = "error",
              duration = 3
            )
          }
        }, error = function(e) {
          log_error(sprintf("登录过程发生错误: %s", e$message))
          showNotification(
            "登录失败，请联系管理员",
            type = "error",
            duration = 5
          )
        })
      } else {
        # 无数据库连接时的提示
        showNotification(
          "数据库连接不可用，请在调试模式下使用",
          type = "warning",
          duration = 5
        )
      }
    })
    
    # 返回认证状态和用户信息
    return(list(
      is_authenticated = auth_status,
      user = current_user
    ))
  })
}

# ==================== 登出功能 ====================
logout_ui <- function(id) {
  ns <- NS(id)
  actionButton(
    inputId = ns("logout_btn"),
    label = tagList(icon("sign-out-alt"), "登出"),
    class = "btn-default btn-sm"
  )
}

logout_server <- function(id, auth_status, session) {
  moduleServer(id, function(input, output, inner_session) {
    observeEvent(input$logout_btn, {
      auth_status(FALSE)
      showNotification(
        "您已成功登出",
        type = "message",
        duration = 3
      )
      log_info("用户登出")
      # 刷新页面
      session$reload()
    })
  })
}
