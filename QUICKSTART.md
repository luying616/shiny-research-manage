# Quick Start Guide

Get up and running with Research Code Manager in 5 minutes!

## Step 1: Install R

If you don't have R installed:
- **Windows/Mac**: Download from https://cran.r-project.org/
- **Linux**: `sudo apt-get install r-base` (Ubuntu/Debian) or `sudo yum install R` (RHEL/CentOS)

## Step 2: Install RStudio (Optional but Recommended)

Download from https://posit.co/download/rstudio-desktop/

## Step 3: Install Required Packages

Open R or RStudio and run:

```R
install.packages(c("shiny", "shinydashboard", "DT"))
```

## Step 4: Run the Application

### Option A: Using RStudio
1. Open the project folder in RStudio
2. Open `app.R`
3. Click "Run App" button at the top of the editor

### Option B: Using R Console
```R
setwd("/path/to/shiny-research-manage")
shiny::runApp()
```

### Option C: Using the Helper Script
```R
source("run_app.R")
```

## Step 5: Use the Application

1. **Browse Files**: Click "Code Repository" to see uploaded files
2. **Upload New Files**: Click "Upload Code" to add new files
3. **Preview Code**: Select a file from the table to view its contents
4. **Manage Files**: Use the buttons to refresh, delete, or download files

## Common Issues

### "Package not found" Error
Solution: Install the missing package using `install.packages("package-name")`

### Port Already in Use
Solution: The app will automatically find an available port. If needed, specify a port:
```R
shiny::runApp(port = 8100)
```

### Permission Errors
Solution: Ensure the `research_code` directory has write permissions

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for hosting options
- See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute to the project

## Need Help?

Open an issue on GitHub: https://github.com/luying616/shiny-research-manage/issues
