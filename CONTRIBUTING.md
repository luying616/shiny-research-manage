# Contributing to Research Code Manager

Thank you for your interest in contributing to the Research Code Manager project!

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear description of the problem
- Steps to reproduce the issue
- Expected vs. actual behavior
- Your R version and package versions

### Suggesting Enhancements

We welcome feature requests! Please open an issue describing:
- The use case for the enhancement
- How it would benefit users
- Any implementation ideas you have

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes with clear messages
6. Push to your fork
7. Open a Pull Request

### Code Style

- Follow standard R coding conventions
- Use meaningful variable names
- Comment complex logic
- Keep functions focused and modular

### Testing

Before submitting a PR:
- Test the application locally
- Verify all existing features still work
- Test your new features thoroughly
- Check for any console errors or warnings

## Development Setup

1. Clone the repository
2. Install required R packages:
```R
install.packages(c("shiny", "shinydashboard", "DT"))
```
3. Run the app locally:
```R
shiny::runApp()
```

## Questions?

Feel free to open an issue for any questions about contributing!
