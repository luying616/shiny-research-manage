# Research Code Management Shiny Application
# This application provides a web interface for managing research code files

library(shiny)
library(shinydashboard)
library(DT)

# Create data directory if it doesn't exist
if (!dir.exists("research_code")) {
  dir.create("research_code", showWarnings = FALSE)
}

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Research Code Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Code Repository", tabName = "repository", icon = icon("folder")),
      menuItem("Upload Code", tabName = "upload", icon = icon("upload")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Code Repository Tab
      tabItem(
        tabName = "repository",
        fluidRow(
          box(
            title = "Code Files", 
            width = 12, 
            solidHeader = TRUE,
            status = "primary",
            DTOutput("fileTable"),
            hr(),
            fluidRow(
              column(4, actionButton("refreshBtn", "Refresh", icon = icon("refresh"))),
              column(4, actionButton("deleteBtn", "Delete Selected", icon = icon("trash"), class = "btn-danger")),
              column(4, downloadButton("downloadBtn", "Download Selected", class = "btn-success"))
            )
          )
        ),
        fluidRow(
          box(
            title = "File Preview",
            width = 12,
            solidHeader = TRUE,
            status = "info",
            verbatimTextOutput("filePreview")
          )
        )
      ),
      
      # Upload Tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "Upload Research Code",
            width = 12,
            solidHeader = TRUE,
            status = "success",
            fileInput("fileUpload", "Choose File(s)",
                     multiple = TRUE,
                     accept = c(".R", ".py", ".ipynb", ".Rmd", ".sql", ".sh", 
                               ".txt", ".md", ".html", ".css", ".js")),
            textInput("categoryInput", "Category (optional)", 
                     placeholder = "e.g., data-analysis, modeling, preprocessing"),
            textAreaInput("descriptionInput", "Description (optional)", 
                         placeholder = "Brief description of the code"),
            actionButton("uploadBtn", "Upload Files", 
                        icon = icon("upload"), 
                        class = "btn-primary btn-lg")
          )
        ),
        fluidRow(
          box(
            title = "Upload Status",
            width = 12,
            solidHeader = TRUE,
            status = "info",
            verbatimTextOutput("uploadStatus")
          )
        )
      ),
      
      # About Tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About Research Code Manager",
            width = 12,
            solidHeader = TRUE,
            status = "primary",
            h3("Overview"),
            p("This application helps researchers manage, organize, and share their code files."),
            h4("Features:"),
            tags$ul(
              tags$li("Upload code files in various formats (R, Python, Jupyter notebooks, etc.)"),
              tags$li("View and manage your code repository"),
              tags$li("Organize code with categories"),
              tags$li("Preview code files directly in the browser"),
              tags$li("Download files for local use"),
              tags$li("Delete outdated or unnecessary files")
            ),
            h4("Supported File Types:"),
            p("R scripts (.R), Python scripts (.py), Jupyter notebooks (.ipynb), 
              R Markdown (.Rmd), SQL scripts (.sql), Shell scripts (.sh), 
              Text files (.txt), Markdown (.md), and web files (HTML, CSS, JS)"),
            hr(),
            p("Version 1.0 | Built with R Shiny")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive value to trigger file list updates
  fileListTrigger <- reactiveVal(0)
  
  # Reactive function to get file info
  getFileInfo <- reactive({
    # Depend on the trigger to refresh
    fileListTrigger()
    
    files <- list.files("research_code", full.names = TRUE)
    if (length(files) == 0) {
      return(data.frame(
        Name = character(0),
        Size = character(0),
        Modified = character(0),
        Type = character(0)
      ))
    }
    
    info <- file.info(files)
    data.frame(
      Name = basename(files),
      Size = paste(round(info$size / 1024, 2), "KB"),
      Modified = as.character(info$mtime),
      Type = tools::file_ext(basename(files))
    )
  })
  
  # Display file table
  output$fileTable <- renderDT({
    datatable(
      getFileInfo(),
      selection = 'single',  # Single selection for preview, delete, and download
      options = list(
        pageLength = 10,
        searching = TRUE,
        ordering = TRUE
      ),
      rownames = FALSE
    )
  })
  
  # File preview
  output$filePreview <- renderText({
    if (is.null(input$fileTable_rows_selected)) {
      return("Select a file from the table above to preview its contents.")
    }
    
    fileData <- getFileInfo()
    if (nrow(fileData) == 0) {
      return("No files available.")
    }
    
    selected_file <- fileData$Name[input$fileTable_rows_selected]
    file_path <- file.path("research_code", selected_file)
    file_ext <- tolower(tools::file_ext(selected_file))
    
    # Define text-based file extensions
    text_extensions <- c("r", "py", "sql", "sh", "txt", "md", "rmd", 
                        "html", "css", "js", "json", "xml", "yaml", "yml")
    
    if (file.exists(file_path)) {
      # Check if file is a text file
      if (!file_ext %in% text_extensions) {
        return(paste("Preview not available for", toupper(file_ext), 
                    "files. Please download to view."))
      }
      
      tryCatch({
        # Read first 100 lines for preview
        content <- readLines(file_path, n = 100, warn = FALSE)
        if (length(content) == 0) {
          return("(Empty file)")
        }
        if (length(content) == 100) {
          content <- c(content, "... (preview limited to 100 lines)")
        }
        paste(content, collapse = "\n")
      }, error = function(e) {
        paste("Error reading file:", e$message, 
              "\nThis may be a binary file. Please download to view.")
      })
    } else {
      "File not found."
    }
  })
  
  # Refresh button
  observeEvent(input$refreshBtn, {
    fileListTrigger(fileListTrigger() + 1)
    showNotification("File list refreshed", type = "message")
  })
  
  # Reactive value for upload status
  uploadStatus <- reactiveVal("")
  
  # Upload files
  observeEvent(input$uploadBtn, {
    if (is.null(input$fileUpload)) {
      showNotification("Please select files to upload", type = "error")
      return()
    }
    
    status <- character()
    
    for (i in 1:nrow(input$fileUpload)) {
      file_name <- input$fileUpload$name[i]
      file_path <- input$fileUpload$datapath[i]
      dest_path <- file.path("research_code", file_name)
      
      tryCatch({
        file.copy(file_path, dest_path, overwrite = TRUE)
        status <- c(status, paste("✓", file_name, "uploaded successfully"))
      }, error = function(e) {
        status <- c(status, paste("✗", file_name, "failed:", e$message))
      })
    }
    
    # Add metadata if provided
    if (nchar(input$categoryInput) > 0 || nchar(input$descriptionInput) > 0) {
      metadata_file <- file.path("research_code", "metadata.txt")
      metadata <- sprintf(
        "\n--- Upload: %s ---\nFiles: %s\nCategory: %s\nDescription: %s\n",
        Sys.time(),
        paste(input$fileUpload$name, collapse = ", "),
        input$categoryInput,
        input$descriptionInput
      )
      cat(metadata, file = metadata_file, append = TRUE)
    }
    
    fileListTrigger(fileListTrigger() + 1)
    uploadStatus(paste(status, collapse = "\n"))
    showNotification("Upload completed", type = "message")
  })
  
  # Render upload status
  output$uploadStatus <- renderText({
    uploadStatus()
  })
  
  # Delete selected file
  observeEvent(input$deleteBtn, {
    if (is.null(input$fileTable_rows_selected)) {
      showNotification("Please select a file to delete", type = "warning")
      return()
    }
    
    fileData <- getFileInfo()
    if (nrow(fileData) == 0) return()
    
    selected_file <- fileData$Name[input$fileTable_rows_selected]
    file_path <- file.path("research_code", selected_file)
    
    if (file.exists(file_path)) {
      # Show confirmation modal
      showModal(modalDialog(
        title = "Confirm Deletion",
        sprintf("Are you sure you want to delete '%s'? This action cannot be undone.", selected_file),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirmDelete", "Delete", class = "btn-danger")
        )
      ))
    }
  })
  
  # Confirm deletion
  observeEvent(input$confirmDelete, {
    if (is.null(input$fileTable_rows_selected)) {
      removeModal()
      return()
    }
    
    fileData <- getFileInfo()
    if (nrow(fileData) == 0) {
      removeModal()
      return()
    }
    
    selected_file <- fileData$Name[input$fileTable_rows_selected]
    file_path <- file.path("research_code", selected_file)
    
    if (file.exists(file_path)) {
      file.remove(file_path)
      fileListTrigger(fileListTrigger() + 1)
      showNotification(paste("Deleted:", selected_file), type = "message")
      removeModal()
    }
  })
  
  # Download selected file
  output$downloadBtn <- downloadHandler(
    filename = function() {
      if (is.null(input$fileTable_rows_selected)) {
        return("file.txt")
      }
      fileData <- getFileInfo()
      if (nrow(fileData) == 0) return("file.txt")
      fileData$Name[input$fileTable_rows_selected]
    },
    content = function(file) {
      if (is.null(input$fileTable_rows_selected)) {
        return()
      }
      fileData <- getFileInfo()
      if (nrow(fileData) == 0) return()
      
      selected_file <- fileData$Name[input$fileTable_rows_selected]
      file_path <- file.path("research_code", selected_file)
      
      if (file.exists(file_path)) {
        file.copy(file_path, file)
      }
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
