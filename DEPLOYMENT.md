# Deployment Configuration
# Instructions for deploying the Research Code Manager

## For shinyapps.io

### First-time setup:
# install.packages("rsconnect")
# rsconnect::setAccountInfo(name='<ACCOUNT>', token='<TOKEN>', secret='<SECRET>')

### Deploy the app:
# rsconnect::deployApp()

## For RStudio Connect

### Deploy using:
# rsconnect::deployApp(server = "your-connect-server.com")

## For Shiny Server (Open Source)

### Copy files to server:
# sudo cp -R /path/to/shiny-research-manage /srv/shiny-server/
# sudo chown -R shiny:shiny /srv/shiny-server/shiny-research-manage

## Local Testing

### Run locally:
# shiny::runApp()
# Or use: source("run_app.R")
