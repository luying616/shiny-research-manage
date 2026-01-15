# Research Code Management System

A web-based Shiny application for managing and organizing research code files. This system provides researchers with an intuitive interface to upload, view, organize, and manage their code files across various programming languages.

## Features

- 📁 **Code Repository Management**: Browse and manage all your research code files in one place
- ⬆️ **Easy File Upload**: Upload code files in multiple formats (R, Python, Jupyter notebooks, SQL, etc.)
- 👁️ **File Preview**: View code content directly in the browser
- 🏷️ **Categorization**: Organize code with custom categories
- 📝 **Metadata Support**: Add descriptions and notes to your uploads
- ⬇️ **Download**: Download files for local use
- 🗑️ **File Management**: Delete outdated or unnecessary files

## Supported File Types

- R scripts (`.R`)
- Python scripts (`.py`)
- Jupyter notebooks (`.ipynb`)
- R Markdown (`.Rmd`)
- SQL scripts (`.sql`)
- Shell scripts (`.sh`)
- Text files (`.txt`)
- Markdown files (`.md`)
- Web files (`.html`, `.css`, `.js`)

## Prerequisites

- R (>= 4.0.0)
- Required R packages:
  - shiny (>= 1.7.0)
  - shinydashboard (>= 0.7.0)
  - DT (>= 0.20)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/luying616/shiny-research-manage.git
cd shiny-research-manage
```

2. Install required R packages:
```R
install.packages(c("shiny", "shinydashboard", "DT"))
```

## Usage

### Running Locally

1. Open R or RStudio in the project directory
2. Run the application:
```R
shiny::runApp()
```

3. The application will open in your default web browser
4. Navigate through the tabs:
   - **Code Repository**: View and manage existing files
   - **Upload Code**: Upload new code files with optional metadata
   - **About**: Learn more about the application

### Using the Application

#### Uploading Code Files
1. Click on the "Upload Code" tab
2. Click "Choose File(s)" and select one or more files
3. Optionally add a category and description
4. Click "Upload Files" to complete the upload

#### Managing Files
1. Go to the "Code Repository" tab
2. View all uploaded files in the table
3. Click on a file row to see a preview below
4. Use the buttons to:
   - **Refresh**: Update the file list
   - **Delete Selected**: Remove the selected file
   - **Download Selected**: Download the selected file

## Deployment

### Deploy to shinyapps.io

1. Install the rsconnect package:
```R
install.packages("rsconnect")
```

2. Configure your shinyapps.io account:
```R
rsconnect::setAccountInfo(name='<ACCOUNT>', 
                         token='<TOKEN>',
                         secret='<SECRET>')
```

3. Deploy the application:
```R
rsconnect::deployApp()
```

### Deploy to Shiny Server

1. Copy the application directory to your Shiny Server apps directory:
```bash
sudo cp -R /path/to/shiny-research-manage /srv/shiny-server/
```

2. Ensure proper permissions:
```bash
sudo chown -R shiny:shiny /srv/shiny-server/shiny-research-manage
```

3. Access the application at: `http://your-server/shiny-research-manage/`

## Project Structure

```
shiny-research-manage/
├── app.R              # Main Shiny application file
├── DESCRIPTION        # Package dependencies
├── README.md          # This file
├── .gitignore         # Git ignore rules
└── research_code/     # Directory for uploaded code files (created automatically)
```

## Data Storage

All uploaded files are stored in the `research_code/` directory within the application folder. Metadata about uploads (categories and descriptions) is stored in `research_code/metadata.txt`.

## Security Considerations

- This application is designed for trusted users within a research environment
- For production deployments, consider adding:
  - User authentication
  - File size limits
  - File type validation
  - Access control mechanisms
  - Backup strategies

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

MIT License - feel free to use this application for your research projects.

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

## Version History

- **v1.0.0** (2026-01-15): Initial release
  - Basic file upload and management
  - File preview functionality
  - Category and metadata support
  - Dashboard interface