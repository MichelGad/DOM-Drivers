# =============================================================================
# Script: 3. wa.R
# Purpose: Weighted average molecular descriptor calculations for DOM analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Process and aggregate raw molecular data to calculate intensity-weighted average molecular descriptors
#   - Handle polarity fractions and clean measurement names for consistent grouping
#   - Perform Z-score normalization on weighted averages
#   - Visualize density distributions, normality box plots, and correlation networks
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Print script header information
cat("=============================================================================\n")
cat("Script: 3. wa.R\n")
cat("Purpose: Weighted average molecular descriptor calculations for DOM analysis\n")
cat("Author: Michel Gad\n")
cat("Date: 2025-09-15\n")
cat("Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018\n")
cat("=============================================================================\n\n")

# 0. Load essential packages
# These libraries provide critical functions for data manipulation, visualization,
# and robust data import/export, adhering to the tidyverse principles.
message("\n--- Loading essential packages for weighted average analysis ---")
library(dplyr)      # Data manipulation (mutate, filter, group_by, summarise)
library(tidyr)      # Data reshaping (pivot_longer, pivot_wider)
library(ggplot2)    # High-quality data visualization
library(readr)      # Robust and fast data import/export (read_csv, parse_number)
library(purrr)      # Functional programming (used by `across`)
library(corrr)      # Tidy correlation analysis and visualization
library(stringr)    # String manipulation (gsub, str_remove_all, tolower)
library(data.table) # Efficient large data import (fread)
message("Essential packages loaded successfully.")

# --- Define Output Directories and Global Settings ---
# These paths specify where processed data and plots will be saved.
# Directories are created if they do not already exist to prevent errors,
# ensuring a structured output organization.
message("\n--- Setting up output directories and global plotting theme ---")
output_plot_dir <- "output/wa"
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

# --- Define Constants for Polarity Indicators ---
# These constants define the suffixes used in 'measurement_name' to denote
# different polarity fractions (High, Medium, Low), essential for categorizing
# and cleaning sample identifiers in FT-ICR MS data.
HIGH_POLARITY <- "_1"
MEDIUM_POLARITY <- "_2"
LOW_POLARITY <- "_3"

# --- Define column name replacements ---
# This list maps common variations or abbreviations of column names to a standardized
# and more readable format, improving data clarity after initial import.
char_replacements <- list(
  "hc" = "H/C", "oc" = "O/C", "nc" = "N/C", "sc" = "S/C",
  "c" = "C", "h" = "H", "o" = "O", "n" = "N", "s" = "S",
  "ai" = "AI", "dbe" = "DBE", "NOS/C" = "NOSC",
  "mOd" = "mod", "meaSuremeNt_Name" = "measurement_name"
)

# --- Helper function to remove polarity indicators from data ---
# This function cleans the 'measurement_name' column by removing common polarity
# suffixes (e.g., "_1", "_2", "_3"), preparing the sample names for consistent
# grouping or merging across different polarity fractions.
remove_polarity <- function(data) {
  data %>%
    mutate(measurement_name = gsub("_[1-3]$", "", measurement_name))
}

# --- Helper function to replace characters in column names ---
# This function systematically renames columns based on a provided list of
# pattern-replacement pairs, ensuring consistent and cleaned column names
# throughout the dataset.
replace_chars_in_column_names <- function(col_names, replacements) {
  new_names <- col_names
  for (pattern in names(replacements)) {
    new_names <- gsub(pattern, replacements[[pattern]], new_names, ignore.case = TRUE)
  }
  return(new_names)
}

# --- Data Import and Initial Cleaning ---
# This section imports raw Weighted Average (WA) data, performs initial cleaning
# to handle character-to-numeric conversions (especially for comma decimals),
# and prepares the data for further processing.
message("\n--- Importing and cleaning weighted average data ---")

# 1. Import WA data
# Loads the raw Weighted Average (WA) data from a CSV file. It includes robust
# error handling to catch issues during file reading and provides helpful
# diagnostics if common parsing problems occur (e.g., wrong delimiter).
tryCatch({
  wa_mf_raw <- data.table::fread(
    file.path(getwd(), "input/eval.summary.clean_2025-01-21.csv"),
    sep = ",",         # Use comma as the delimiter
    quote = "",        # Handles literal quotes within header or data
    data.table = FALSE # Ensure output is a data.frame/tibble
  )

  # Check if data was loaded and has columns
  if (nrow(wa_mf_raw) == 0 || ncol(wa_mf_raw) == 0) {
    stop("Input WA file 'eval.summary.clean_2025-01-21.csv' is empty or contains no data after loading.")
  }

}, error = function(e) {
  stop(paste("Error loading WA data:", e$message,
             "\n\n**Critical Check**: The file 'input/eval.summary.clean_2025-01-21.csv' appears to be comma-separated.",
             "\nIf errors persist, manually inspect the file's true delimiter and quoting."
             ))
})
message("Weighted average data loaded successfully.")

# 2. Convert numeric columns (handling comma decimals)
# This step systematically cleans column names by removing literal quotes and
# converts character columns containing numeric data (which might use commas
# as decimal separators) into proper numeric format, excluding 'measurement_name'.
wa_mf_cleaned <- wa_mf_raw %>%
  # Clean column names by removing literal quotes
  setNames(stringr::str_remove_all(colnames(.), "\"")) %>%
  mutate(
    # Remove literal quotes from the *values* of all character columns
    across(
      .cols = where(is.character),
      .fns = ~ stringr::str_remove_all(.x, "\"")
    ),
    # Process character columns for numeric conversion (excluding measurement_name)
    across(
      .cols = where(is.character) & !matches("measurement_name", ignore.case = TRUE),
      .fns = ~ parse_number(.x, locale = locale(decimal_mark = ",")) # Robust conversion respecting locale
    )
  )

# --- Add Polarity Column and Clean Measurement Names ---
# This block adds a `polarity` column based on recognized suffixes in
# `measurement_name` and then cleans these suffixes, converting `measurement_name`
# to an integer for easier grouping and manipulation.
message("\n--- Processing polarity information and cleaning measurement names ---")
if ("measurement_name" %in% colnames(wa_mf_cleaned)) {
  # Add polarity information and clean measurement_name
  # Categorizes samples into High, Medium, or Low Polarity (HP, MP, LP)
  # based on suffixes in their measurement names.
  wa.clean <- wa_mf_cleaned %>%
    mutate(polarity = case_when(
      grepl(HIGH_POLARITY, measurement_name) ~ "HP",
      grepl(MEDIUM_POLARITY, measurement_name) ~ "MP",
      grepl(LOW_POLARITY, measurement_name) ~ "LP",
      TRUE ~ NA_character_ # Assign NA if no polarity indicator is found
    )) %>%
    remove_polarity() %>% # Removes polarity suffix from measurement_name using helper function
    mutate(measurement_name = as.integer(measurement_name)) # Converts measurement_name to integer
} else {
  warning("No 'measurement_name' column found in wa_mf_cleaned. Skipping polarity addition and cleaning. 'wa.clean' is set to 'wa_mf_cleaned'.")
  wa.clean <- wa_mf_cleaned # Ensure wa.clean is still defined
}

# --- Calculate the Mean for All Polarities ---
# This section groups the data by `measurement_name` and calculates the mean
# for all numeric columns starting with "wa", effectively aggregating data
# across different polarities for each unique measurement.
message("\n--- Calculating mean values across all polarities ---")
if (exists("wa.clean") && nrow(wa.clean) > 0 && "measurement_name" %in% colnames(wa.clean)) {
  if (sum(is.na(wa.clean$measurement_name)) > 0) {
    warning("NAs present in 'measurement_name' column. These rows might be dropped or grouped separately during summarization.")
  }

  wa_mean_clean <- wa.clean %>%
    group_by(measurement_name) %>%
    summarise(
      across(
        .cols = starts_with("wa") & where(is.numeric), # Select numeric columns that start with "wa"
        .fns = mean,
        .names = "{.col}" # Preserve original column names after summarization
      ),
      .groups = "drop" # Remove grouping structure after summarizing
    ) %>%
    select(-contains("_p", ignore.case = TRUE)) %>% # Remove "Phosphorus" related columns (if any)
    rename_with(~ replace_chars_in_column_names(.x, char_replacements), everything()) # Adjust column names for clarity

} else {
  warning("wa.clean data frame is not available or empty, or missing 'measurement_name'. Skipping mean calculation.")
  wa_mean_clean <- NULL # Set to NULL to indicate failure
}

# --- Separate ID Column and Select Numeric Data for Analysis ---
# This section isolates the `measurement_name` identifier and selects only
# the numeric "wa" columns for standardization and subsequent analysis,
# ensuring that non-numeric or identifying columns do not interfere with calculations.
message("\n--- Preparing data for standardization and analysis ---")
id_column_name <- "measurement_name"

if (!is.null(wa_mean_clean) && nrow(wa_mean_clean) > 0 && id_column_name %in% colnames(wa_mean_clean)) {
  measurement_id <- wa_mean_clean %>% select(all_of(id_column_name))
  # Select numeric 'wa' columns from the averaged data for processing and standardization
  wa_for_processing <- wa_mean_clean %>%
    select(-all_of(id_column_name)) %>% # Exclude the ID column
    select(starts_with("wa")) %>%       # Select columns starting with "wa"
    select(where(is.numeric))          # Ensure they are numeric
} else {
  stop("Averaged WA data (wa_mean_clean) is not available, empty, or missing 'measurement_name'. Cannot proceed with standardization or plotting.")
}

# Final check for data availability for analysis
# Ensures that there is sufficient numeric data remaining after all selection
# and filtering steps to proceed with standardization and plotting.
if (ncol(wa_for_processing) < 1 || nrow(wa_for_processing) < 1) {
  stop("No numeric 'wa' data or observations remaining in averaged data after initial processing and selection. Check your input data and column names.")
}

# --- Data Standardization ---
# This section performs Z-score normalization (standardization) on the numeric
# Weighted Average (WA) data, making them comparable and suitable for various
# statistical methods (e.g., PCA, correlation analysis).
message("\n--- Standardizing weighted average data ---")

# 3. Standardize WA data (Z-score normalization)
# Applies the `scale_robust` helper function across all numeric "wa" columns
# to standardize their values, ensuring all values are on a comparable scale.
wa_std_numeric <- wa_for_processing %>%
  mutate(across(everything(), .fns = scale_robust)) %>%
  as_tibble() # Ensure output is a tibble/data.frame

# Recombine with the ID column
# Merges the standardized numeric "wa" data back with the previously separated
# `measurement_id` column to retain sample identification for downstream analysis.
wa_std <- bind_cols(measurement_id, wa_std_numeric)
message("Data standardization completed.")

# --- Visualization: Density Distributions ---
# This section generates density plots for all standardized Weighted Average (WA)
# values, providing a visual assessment of their distributions and identifying
# any potential skewness or multi-modality.
message("\n--- Generating density distribution plots ---")

# 4. Density plot of standardized WA values
# Pivots the standardized numeric WA data to a long format suitable for `ggplot2`'s
# `facet_wrap` and creates histograms with overlaid density curves, visualizing
# the distribution of each WA parameter.
if (nrow(wa_std_numeric) > 0 && ncol(wa_std_numeric) > 0) {
  plot_data_density_wa <- wa_std_numeric %>%
    pivot_longer(
      cols = everything(), # Apply to all numeric columns
      names_to = "parameter",
      values_to = "value"
    )

  if (nrow(plot_data_density_wa) == 0 || ncol(plot_data_density_wa) < 2) {
    warning("Plot data for density distribution is empty or malformed after pivot_longer. Skipping plot generation.")
  } else {
    density_plot_wa <- plot_data_density_wa %>%
      ggplot(aes(x = value)) +
      geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#85BFD1", color = "white", alpha = 0.8) +
      geom_density(color = "#E05D5D", linewidth = 1, alpha = 0.7) +
      facet_wrap(~ parameter, scales = "free") +
      labs(
        title = "Density Distributions of Standardized WA Values (Averaged)",
        x = "Standardized Value",
        y = "Density"
      )

    figsave(density_plot_wa, "Density_distributions_wa.pdf", 11, 7, output_plot_dir)
  }
} else {
  warning("No standardized numeric WA data available for density distribution plotting. Skipping plot generation.")
}

# --- Visualization: Normality Assessment Box Plot ---
# Box plots visualize the distribution, central tendency, and outliers of standardized
# Weighted Average (WA) parameters, aiding in the assessment of data normality
# and identifying potential anomalies in the aggregated data.
message("\n--- Generating normality assessment box plots ---")

# 5. Reshape standardized data for boxplot visualization
# Transforms the standardized WA data into a long format, where each row
# represents a single observation of a WA parameter, making it suitable
# for creating comparative box plots using `ggplot2`.
if (ncol(wa_std_numeric) > 0 && nrow(wa_std_numeric) > 0) {
  wa_norm_long <- wa_std_numeric %>%
    pivot_longer(
      cols = everything(), # Applies to all columns (already numeric and standardized)
      names_to = "variable",
      values_to = "value"
    )

  wa_box <- ggplot(wa_norm_long, aes(x = value, y = variable)) +
    geom_boxplot(outlier.color = "red", outlier.shape = 16, fill = "lightblue", alpha = 0.8) +
    labs(
      title = "Box Plots of Standardized WA Parameters (Averaged)",
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

  figsave(wa_box, "Normality_WA.pdf", 8, 10, output_plot_dir)
} else {
  warning("No standardized numeric WA data available for normality boxplot. Skipping plot generation.")
}

# --- Visualization: Correlation Matrix ---
# A correlation matrix plot provides a visual representation of relationships
# between standardized Weighted Average (WA) parameters, highlighting highly correlated
# variables and potential redundancies in the aggregated molecular data.
message("\n--- Generating correlation matrix plots ---")

# 6. Correlation matrix plot using `corrr::network_plot` for WA data
# Calculates Pearson correlations between all pairs of standardized numeric WA parameters
# and visualizes them as a network. Edges are drawn for correlations above a certain threshold,
# making strong relationships easy to identify.
if (ncol(wa_std_numeric) >= 2 && nrow(wa_std_numeric) >= 2) {
  # Calculate correlations using `corrr::correlate`
  cor_result_wa <- wa_std_numeric %>%
    correlate(method = "pearson", use = "pairwise.complete.obs")

  # Use `network_plot` for a visual network of correlations
  correlation_network_plot_wa <- cor_result_wa %>%
    network_plot(
      min_cor = 0.5, # Edges are drawn for correlations with absolute value >= 0.5
      repel = TRUE,  # Avoid overlapping labels for better readability
      colors = c("#2C7BB6", "white", "#D7191C") # Custom colors for correlation strength
    ) +
    labs(
      title = "Correlation Network of Standardized WA Values (Averaged)",
      subtitle = expression("Edges represent correlations (absolute value " >= " 0,5)")
    ) +
    theme_void() + # Minimal theme for network plot
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14, margin = margin(b = 10)),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      legend.position = "bottom",
      plot.margin = margin(1, 1, 1, 1, "cm")
    )
  figsave(correlation_network_plot_wa, "Correlation_map_wa.pdf", 11, 7, output_plot_dir)
} else {
  warning("Not enough numeric columns (at least 2) or rows (at least 2) in standardized WA data to create correlation plot. Skipping.")
}

# --- Save Processed Data ---
# This final section saves the cleaned and processed (aggregated mean) Weighted
# Average (WA) data to a CSV file, making it available for subsequent analyses
# or modeling workflows.
message("\n--- Saving processed weighted average data ---")

# 7. Save the processed WA data (aggregated means)
# Exports the `wa_mean_clean` dataframe, containing the intensity-weighted
# averages of molecular descriptors, to a CSV file in the 'processed' directory.
if (!is.null(wa_mean_clean)) {
  write_csv(wa_mean_clean, file.path(output_processed_data_dir, "wa_mean_processed.csv"))
  message("Processed weighted average data saved successfully.")
} else {
  warning("wa_mean_clean data is NULL, skipping save for aggregated mean data.")
}

message("Script execution complete!")
