# .Rprofile for Research Code Manager
# This file is executed when R starts in this directory

# Set repository for package installation
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Display welcome message
cat("\n")
cat("=========================================\n")
cat("  Research Code Manager\n")
cat("  Version 1.0.0\n")
cat("=========================================\n")
cat("\n")
cat("To run the application, use:\n")
cat("  shiny::runApp()\n")
cat("  or\n")
cat("  source('run_app.R')\n")
cat("\n")

# Check for required packages
required_packages <- c("shiny", "shinydashboard", "DT")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Warning: The following required packages are missing:\n")
  cat(paste("  -", missing_packages, collapse = "\n"), "\n")
  cat("\nInstall them with:\n")
  cat(sprintf('  install.packages(c("%s"))\n', paste(missing_packages, collapse = '", "')))
  cat("\n")
}
