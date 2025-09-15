# =============================================================================
# Script: 2. env.R
# Purpose: Environmental parameter data import and preprocessing for DOM analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Import and clean raw environmental parameter data
#   - Handle comma-separated decimals and standardize names
#   - Perform Z-score normalization
#   - Generate diagnostic plots: density distributions, normality box plots, and correlation networks
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Print script header information
cat("=============================================================================\n")
cat("Script: 2. env.R\n")
cat("Purpose: Environmental parameter data import and preprocessing for DOM analysis\n")
cat("Author: Michel Gad\n")
cat("Date: 2025-09-15\n")
cat("Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018\n")
cat("=============================================================================\n\n")

# 0. Load essential packages
# These libraries provide critical functions for data manipulation, visualization,
# and robust data import/export, adhering to the tidyverse principles.
message("\n--- Loading essential packages for environmental parameters analysis ---")
library(dplyr)      # Data manipulation (mutate, filter, group_by, summarise)
library(tidyr)      # Data reshaping (pivot_longer, pivot_wider)
library(ggplot2)    # High-quality data visualization
library(readr)      # Robust and fast data import/export (read_csv, parse_number)
library(purrr)      # Functional programming (used by `across`)
library(corrr)      # Tidy correlation analysis and visualization
library(data.table) # Efficient large data import (fread)
message("Essential packages loaded successfully.")

# --- Define Output Directories and Global Settings ---
# These paths specify where processed data and plots will be saved.
# Directories are created if they do not already exist to prevent errors,
# ensuring a structured output organization.
message("\n--- Setting up output directories and global plotting theme ---")
output_plot_dir <- "output/env"
output_processed_data_dir <- "processed"

# Create directories if they don't exist
if (!dir.exists(output_plot_dir)) {
  dir.create(output_plot_dir, recursive = TRUE)
  message(paste0("Created plot output directory: ", output_plot_dir))
}
if (!dir.exists(output_processed_data_dir)) {
  dir.create(output_processed_data_dir, recursive = TRUE)
  message(paste0("Created processed data output directory: ", output_processed_data_dir))
}

# Set global ggplot2 theme for consistent plot aesthetics
# This theme applies a clean, publication-ready look to all ggplot2 plots by default,
# ensuring visual consistency across all generated figures.
theme_set(theme_bw(base_size = 11) +
            theme(
              plot.title = element_text(hjust = 0.5, face = "bold", size = 14, color = "black"),
              axis.title = element_text(face = "bold", color = "black"),
              axis.text = element_text(color = "black"),
              panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
              panel.grid.minor = element_line(color = "grey95", linewidth = 0.25),
              strip.background = element_rect(fill = "grey85", color = "black"),
              strip.text = element_text(face = "bold", color = "black")
            ))
message("Output directories created and global ggplot2 theme applied.")

# --- Custom Helper Functions ---

# Custom Plot Saving Function
# This function provides a robust way to save ggplot2 objects to PDF files.
# It includes error handling to ensure devices are closed properly even if plotting fails,
# preventing common issues like "plot margin too large" errors.
figsave <- function(plot_obj, filename, width, height, output_dir) {
  filepath <- file.path(output_dir, filename)
  tryCatch({
    pdf(filepath, width = width, height = height)
    print(plot_obj)
    dev.off()
    message(paste0("Plot saved to: ", filepath))
  }, error = function(e) {
    warning(paste0("Could not save plot '", filename, "'. Error: ", e$message))
    if (!is.null(dev.cur())) { # Check if a graphics device is open
      dev.off() # Attempt to close device to prevent zombie devices
    }
  })
}

# Helper function for robust scaling to handle zero standard deviation
# This function standardizes a numeric vector (Z-score normalization).
# It specifically handles cases where the standard deviation is zero (e.g., all values are the same),
# returning 0 in such cases to prevent NaN results, ensuring stable scaling.
scale_robust <- function(x) {
  if (is.numeric(x)) {
    if (sd(x, na.rm = TRUE) == 0) {
      return(0) # If SD is 0, all values are the same, so normalized value is 0.
    } else {
      return(as.numeric(scale(x))) # Standard Z-score scaling.
    }
  } else {
    return(x) # Return as is if not numeric (e.g., a factor or character column).
  }
}

# --- Data Import and Initial Cleaning ---
# This section handles the import of raw environmental parameter data and performs
# initial cleaning steps, including converting character columns to numeric
# and separating the identifier column for processing.
message("\n--- Importing and cleaning environmental parameters data ---")

# 1. Import environmental parameters
# Loads the raw environmental data from a CSV file. Includes error handling
# to check for file existence and ensure data is loaded correctly.
tryCatch({
  parameters_raw <- fread(file.path(getwd(), "input/env_2025-01-21.csv"))

  # Check if data was loaded and has columns
  if (nrow(parameters_raw) == 0 || ncol(parameters_raw) == 0) {
    stop("Input file 'env_2025-01-21.csv' is empty or contains no data after loading.")
  }

}, error = function(e) {
  stop(paste("Error loading data 'env_2025-01-21.csv':", e$message))
})
message("Environmental parameters data loaded successfully.")

# 2. Convert numbers from character columns (handling comma decimals)
# This step systematically converts character columns containing numeric data (which might use
# commas as decimal separators) into proper numeric format, excluding the 'measurement_name' column.
parameters <- parameters_raw %>%
  mutate(
    across(
      .cols = where(is.character) & !matches("measurement_name", ignore.case = TRUE),
      .fns = ~ {
        # Convert comma-decimals to numeric; handle direct conversion if no commas.
        if (any(grepl(",", .x, fixed = TRUE))) {
          suppressWarnings(as.numeric(gsub(",", ".", .x, fixed = TRUE)))
        } else {
          suppressWarnings(as.numeric(.x))
        }
      }
    )
  )

# Separate the 'measurement_name' ID column for later recombination
# Identifies and separates the unique identifier column ('measurement_name')
# from the rest of the parameters to prevent its inclusion in numeric operations.
id_column_name <- "measurement_name"
if (id_column_name %in% colnames(parameters)) {
  measurement_id <- parameters %>% select(all_of(id_column_name))
  parameters_for_processing <- parameters %>% select(-all_of(id_column_name))
} else {
  warning("No 'measurement_name' column found. Assuming all relevant columns are numeric for processing.")
  parameters_for_processing <- parameters
}

# --- Data Preprocessing ---
# This section defines specific columns to be removed and filters the dataset
# to retain only numeric parameters that are suitable for statistical analysis.
message("\n--- Preprocessing environmental parameters data ---")

# Define columns to remove (e.g., highly correlated parameters or redundant ones)
# These columns are often excluded to simplify analysis or avoid multicollinearity.
cols_to_remove_list <- c("humic_like", "Tyrosine_like", "Humic_like_F", "Marine_like",
                         "Tryptophan_like", "BIX", "HIX", "FI")

# Filter to get only numeric columns and remove specified ones
# Selects all numeric columns and then removes those specified in `cols_to_remove_list`,
# preparing the data for standardization.
parameters_filtered_numeric <- parameters_for_processing %>%
  select(where(is.numeric)) %>%
  select(-any_of(cols_to_remove_list))

# Ensure data remains for analysis after filtering
# Critical check to ensure that the dataset is not empty after filtering,
# preventing downstream errors if no valid numeric data is left.
if (ncol(parameters_filtered_numeric) < 1 || nrow(parameters_filtered_numeric) < 1) {
  stop("No numeric data or observations remaining after initial processing and filtering. Check your input data.")
}

# --- Data Standardization ---
# This section performs Z-score normalization (standardization) on the numeric
# environmental parameters, making them comparable and suitable for various
# statistical methods (e.g., PCA, regression).
message("\n--- Standardizing environmental parameters data ---")

# 3. Standardize data (Z-score normalization)
# Applies the `scale_robust` helper function across all numeric columns
# to standardize their values, handling cases of zero standard deviation.
parameter_std_numeric <- parameters_filtered_numeric %>%
  mutate(across(everything(), .fns = scale_robust))

# Recombine with the ID column
# Merges the standardized numeric data back with the previously separated
# `measurement_id` column to retain sample identification.
if (exists("measurement_id")) {
  parameter_std <- bind_cols(measurement_id, parameter_std_numeric)
} else {
  parameter_std <- parameter_std_numeric
}
message("Data standardization completed.")

# --- Visualization: Density Distributions ---
# This section generates density plots for all standardized numerical parameters,
# allowing for quick assessment of their distributions and potential deviations from normality.
message("\n--- Generating density distribution plots ---")

# 4. Density distributions plot for all numeric parameters
# Pivots the standardized numeric data to a long format suitable for `ggplot2`'s
# `facet_wrap` and creates histograms with overlaid density curves, visualizing
# the distribution of each parameter.
if (nrow(parameter_std_numeric) > 0) {
  plot_data_density <- parameter_std_numeric %>%
    pivot_longer(
      cols = everything(), # Apply to all numeric columns
      names_to = "parameter",
      values_to = "value"
    )

  density_plot <- plot_data_density %>%
    ggplot(aes(x = value)) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#85BFD1", color = "white", alpha = 0.8) +
    geom_density(color = "#E05D5D", linewidth = 1, alpha = 0.7) +
    facet_wrap(~ parameter, scales = "free") +
    labs(
      title = "Density Distributions of Environmental Parameters",
      x = "Value",
      y = "Density"
    )

  figsave(density_plot, "Density_distributions_env.pdf", 11, 7, output_plot_dir)
} else {
  warning("No data available for density distribution plotting. Skipping plot generation.")
}

# --- Visualization: Normality Assessment Box Plot ---
# Box plots visualize the distribution, central tendency, and outliers of standardized
# numerical parameters, aiding in the assessment of data normality and identifying anomalies.
message("\n--- Generating normality assessment box plots ---")

# 5. Reshape standardized data for boxplot visualization
# Transforms the standardized data into a long format, where each row represents
# a single observation of a parameter, making it suitable for creating box plots
# per parameter using `ggplot2`.
if (ncol(parameter_std_numeric) > 0 && nrow(parameter_std_numeric) > 0) {
  parameters_norm_long <- parameter_std_numeric %>%
    pivot_longer(
      cols = everything(), # Applies to all columns (already numeric and standardized)
      names_to = "variable",
      values_to = "value"
    )

  parameters_box <- ggplot(parameters_norm_long, aes(x = value, y = variable)) +
    geom_boxplot(outlier.color = "red", outlier.shape = 16, fill = "lightblue", alpha = 0.8) +
    labs(
      title = "Box Plots of Standardized Environmental Parameters",
      x = "Standardized Value",
      y = "Parameter"
    ) +
    # The default theme_bw() applied by theme_set() is suitable, but additional
    # customizations ensure y-axis text clarity and grid line style.
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      axis.text.y = element_text(vjust = 0.5, hjust = 1, size = 11, color = "black"), # Consistent vjust/hjust
      axis.title.x = element_text(face = "bold", color = "black"),
      axis.title.y = element_text(face = "bold", color = "black"),
      legend.position = "none",
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.5),
      panel.grid.minor.x = element_line(color = "grey95", linewidth = 0.25)
    )

  figsave(parameters_box, "Normality_env.pdf", 8, 10, output_plot_dir)
} else {
  warning("No standardized numeric data available for normality boxplot. Skipping plot generation.")
}

# --- Visualization: Correlation Matrix ---
# A correlation matrix plot provides a visual representation of relationships
# between standardized environmental parameters, highlighting highly correlated variables
# and potential redundancies.
message("\n--- Generating correlation matrix plots ---")

# 6. Correlation matrix plot using `corrr::network_plot`
# Calculates Pearson correlations between all pairs of standardized numeric parameters
# and visualizes them as a network. Edges are drawn for correlations above a certain threshold,
# making strong relationships easy to identify.
if (ncol(parameter_std_numeric) >= 2 && nrow(parameter_std_numeric) >= 2) {
  # Calculate correlations using `corrr::correlate`
  cor_result <- parameter_std_numeric %>%
    correlate(method = "pearson", use = "pairwise.complete.obs")

  # Use `network_plot` for a visual network of correlations
  correlation_network_plot <- cor_result %>%
    network_plot(
      min_cor = 0.5, # Edges are drawn for correlations with absolute value >= 0.5
      repel = TRUE,  # Avoid overlapping labels for better readability
      colors = c("#2C7BB6", "white", "#D7191C") # Custom colors for correlation strength
    ) +
    labs(
      title = "Correlation Network of Standardized Environmental Parameters",
      subtitle = expression("Edges represent correlations (absolute value " >= " 0,5)")
    ) +
    theme_void() + # Minimal theme for network plot
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14, margin = margin(b = 10)),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      legend.position = "bottom",
      plot.margin = margin(1, 1, 1, 1, "cm")
    )
  figsave(correlation_network_plot, "Correlation_map_env.pdf", 11, 7, output_plot_dir)
} else {
  warning("Not enough numeric columns (at least 2) or rows (at least 2) in standardized data to create a correlation plot. Skipping.")
}

# --- Save Processed Data ---
# This final section saves the cleaned and processed environmental parameters data
# to a CSV file, making it available for subsequent analyses or modeling workflows.
message("\n--- Saving processed environmental parameters data ---")

# 7. Save processed (standardized) data for potential downstream analysis.
# Exports the `parameters` dataframe (which includes the numeric conversions and ID column,
# but not the separate `parameter_std_numeric` unless specifically recombined before saving)
# to a CSV file in the 'processed' directory.
write_csv(parameters, file.path(output_processed_data_dir, "parameters_env_processed.csv"))
message("Processed environmental parameters data saved successfully.")

message("Script execution complete!")
