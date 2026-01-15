# Example: Running the Research Code Manager
# 
# This script demonstrates how to launch the Shiny application

# Install required packages if not already installed
required_packages <- c("shiny", "shinydashboard", "DT")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Run the Shiny app
shiny::runApp()
