# Example Data Analysis Script
# Author: Research Team
# Date: 2026-01-15
# Category: data-analysis

# Load required libraries
library(ggplot2)

# Sample data analysis
data <- data.frame(
  x = 1:10,
  y = rnorm(10, mean = 5, sd = 2)
)

# Create a simple plot
plot <- ggplot(data, aes(x = x, y = y)) +
  geom_point() +
  geom_line() +
  labs(title = "Sample Research Data",
       x = "Sample ID",
       y = "Measurement") +
  theme_minimal()

# Display plot
print(plot)

# Summary statistics
summary(data)
