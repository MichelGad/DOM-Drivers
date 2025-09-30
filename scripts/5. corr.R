# =============================================================================
# Script: 5. corr.R
# Purpose: Inter-data correlation analysis and Van Krevelen diagrams for DOM analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Calculate Spearman correlation coefficients between molecular formula peak intensities and environmental parameters
#   - Analyze prevalence of molecular formulas across different sites
#   - Generate distribution plots of Spearman's rho values for each environmental variable
#   - Create correlation networks and heatmaps for environmental parameters and molecular formula properties
#   - Generate Van Krevelen diagrams colored by correlation strength with environmental variables
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Print script header information
cat("=============================================================================\n")
cat("Script: 5. corr.R\n")
cat("Purpose: Inter-data correlation analysis and Van Krevelen diagrams for DOM analysis\n")
cat("Author: Michel Gad\n")
cat("Date: 2025-09-15\n")
cat("Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018\n")
cat("=============================================================================\n\n")

# 0. Load essential packages
# These libraries provide critical functions for data manipulation, visualization,
# and robust data import/export, adhering to the tidyverse principles.
message("\n--- Loading essential packages for Spearman correlation analysis ---")
library(dplyr)        # Data wrangling
library(tidyr)        # Data reshaping
library(ggplot2)      # Plotting
library(data.table)   # Fast merging & file reading
library(readr)        # File input/output
library(RColorBrewer) # Color palettes (if needed later)
library(tibble)       # Tibble data frames
library(corrr)        # Correlation calculations
library(stringr)      # String manipulation
message("Essential packages loaded successfully.")

# --- Define Output Directories and Global Settings ---
# These paths specify where processed data and plots will be saved.
# Directories are created if they do not already exist to prevent errors.
message("\n--- Setting up output directories and global plotting theme ---")
output_plot_base_dir <- "output/corr"
vK_plot_figure_sub_dir <- file.path(output_plot_base_dir, "vKs")
Dist_plot_figure_sub_dir <- file.path(output_plot_base_dir, "distribution")
output_processed_data_dir <- "processed"

# Create directories if they don't exist
if (!dir.exists(vK_plot_figure_sub_dir)) dir.create(vK_plot_figure_sub_dir, recursive = TRUE)
if (!dir.exists(Dist_plot_figure_sub_dir)) dir.create(Dist_plot_figure_sub_dir, recursive = TRUE)
if (!dir.exists(output_processed_data_dir)) dir.create(output_processed_data_dir, recursive = TRUE)

# Set a consistent base plotting theme for publication quality
theme_set(theme_bw(base_size = 11) +
            theme(
              plot.title = element_text(hjust = 0.5, face = "bold", size = 14, color = "black"),
              axis.title = element_text(face = "bold", color = "black"),
              axis.text = element_text(color = "black"),
              legend.title = element_text(face = "bold", color = "black"),
              legend.text = element_text(color = "black"),
              panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
              panel.grid.minor = element_line(color = "grey95", linewidth = 0.25),
              strip.background = element_rect(fill = "grey85", color = "black"),
              strip.text = element_text(face = "bold", color = "black")
            ))
message("Output directories created and global ggplot2 theme applied.")

# --- Custom Plot Saving Function ---
# Saves any ggplot object as PDF in the given directory.
# Automatically wraps in tryCatch to avoid script-breaking errors and ensures
# graphics devices are closed cleanly.
figsave <- function(plot_obj, filename, width, height, output_dir) {
  filepath <- file.path(output_dir, filename)
  tryCatch({
    pdf(filepath, width = width, height = height)
    print(plot_obj)
    dev.off()
    message(paste0("Plot saved to: ", filepath))
  }, error = function(e) {
    message(paste0("Could not save plot '", filename, "'. Error: ", e$message))
    if (!is.null(dev.cur())) dev.off() # Close device even on error
  })
}

# --- Helper function for robust scaling to handle zero standard deviation ---
# Standardizes a numeric vector (Z-score normalization).
# Handles cases where the standard deviation is zero (all values are the same),
# returning 0 to prevent NaN results.
scale_robust <- function(x) {
  if (is.numeric(x)) {
    if (sd(x, na.rm = TRUE) == 0) {
      return(0) # If SD is 0, all values are the same, so normalized value is 0.
    } else {
      return(as.numeric(scale(x))) # Standard Z-score scaling.
    }
  } else {
    return(x) # Return as is if not numeric.
  }
}

# --- Helper function: Reorder correlation matrix ---
# Reorders a correlation matrix using hierarchical clustering to group similar variables,
# improving the readability of heatmaps.
reorder_cormat <- function(cormat) {
  dd <- as.dist((1 - cormat) / 2) # Use correlation as distance metric
  hc <- hclust(dd) # Perform hierarchical clustering
  cormat <- cormat[hc$order, hc$order] # Reorder matrix
  return(cormat)
}

# --- Helper function: Get upper triangle of the correlation matrix ---
# Extracts the upper triangle of a correlation matrix,
# setting the lower triangle and diagonal to NA, as correlation matrices are symmetric.
get_upper_tri <- function(cormat) {
  cormat[lower.tri(cormat, diag = TRUE)] <- NA
  return(cormat)
}
message("Custom helper functions defined.")

# Define expected molecular formula property columns for later correlation analysis.
# Removed backticks from "f*", "z*", and "KMD/z*" as all_of() expects literal string names.
expected_mf_cols_props <- c(
  "C", "H", "N", "O", "S",
  "H/C", "O/C", "N/C", "S/C",
  "DBE", "DBE-O", "DBE/O", "DBE/C", "DBE/H",
  "KMD(CH2)", "KMD(CO2)", "KMD(H2)", "KMD(NH2)",
  "AI", "AImod", "AIcon", "Xc", "NOSC",
  "ZX", "f*", "z*", "KMD/z*" # Corrected: no backticks in string literals
)

# --- Data Import and Initial Cleaning ---
message("\n--- Importing molecular formula and environmental parameter data ---")
# Define file paths for input data
mf_input_data_filepath <- file.path(getwd(), "processed/mf_processed.csv")
env_params_raw_filepath <- file.path(getwd(), "processed/parameters_env_processed.csv")

# Validate file existence before attempting to load
if (!file.exists(mf_input_data_filepath)) stop(paste("File not found:", mf_input_data_filepath))
if (!file.exists(env_params_raw_filepath)) stop(paste("File not found:", env_params_raw_filepath))

# Load data into memory using fread for efficiency, converting to data.frame
mf_input_data_df <- fread(mf_input_data_filepath, data.table = FALSE)
env_params_raw_df <- fread(env_params_raw_filepath, data.table = FALSE)
message("Data loaded successfully.")

# ---  Data Preparation --- 
message("\n--- Preparing data for correlation analysis ---")
# Keep only relevant MF columns for correlation calculation:
# formula_string for unique ID, measurement_name for joining, peak_intensity for correlation,
# and polarity for grouping.
mf_minimal_df <- mf_input_data_df %>%
  dplyr::select(formula_string, measurement_name, peak_intensity, polarity)

# Merge environmental data with minimal MF data using 'measurement_name'.
# An inner join ensures only matching records are kept, which is robust.
merged_mf_env_df <- dplyr::inner_join(env_params_raw_df, mf_minimal_df, by = "measurement_name")

# Drop 'measurement_name' after merge as it's no longer needed for direct calculations
# within this merged dataframe.
merged_mf_env_df$measurement_name <- NULL

# Extract unique MF properties for later merging back into correlation results.
# This ensures that each unique molecular formula's descriptive properties are
# available for the final correlation table and subsequent plots.
mf_unique_props_for_final_table_df <- mf_input_data_df %>%
  dplyr::select(-measurement_name, -peak_intensity) %>%
  dplyr::distinct(formula_string, .keep_all = TRUE)

# Define the list of environmental variables against which correlations will be tested.
# This list ensures that only relevant parameters are included in the analysis.
available_env_vars <- c("AAT", "AAP", "Slope", "Coverage", "pH", "EC",
                        "Alcalinity", "F", "Cl", "NO3", "SO2", "TOC",
                        "Na", "K", "Ca", "Mg", "SUV", "SR", "E2_E3")
message("Data preparation complete.")

# --- Common MF Comparison Analysis --- 
message("\n--- Analyzing prevalence of molecular formulas across sites ---")
# Goal: Determine how many molecular formulas remain if we filter
# for appearance in > N sites, for N = 1...max_sites.

result_df <- data.frame(filter_number = integer(), number_of_rows = integer())
max_sites <- 84  # Maximum site count available in the dataset

# Loop through each possible site count threshold
for (i in 1:max_sites) {
  # Group by MF and polarity, then filter to keep only MFs appearing more than 'i' times (across sites).
  # For each filtered group, calculate the Spearman rho with peak intensity against all environmental variables.
  filtered_data <- merged_mf_env_df %>%
    dplyr::group_by(formula_string, polarity) %>%
    dplyr::filter(n() > i) %>%
    dplyr::summarise(
      # Calculate Spearman rho for each environmental variable against peak_intensity
      # Suppress warnings from cor() where correlation might be NA (e.g. constant values)
      across(all_of(available_env_vars),
             ~ suppressWarnings(cor(.x, peak_intensity, method = "spearman")),
             .names = "{paste0('rho', '(', .col, ')')}"
             ),
      .groups = "drop" # Drop grouping after summarisation
    ) %>%
    # Merge in unique MF properties to the results of this prevalence filter
    as.data.table() %>%
    merge(., mf_unique_props_for_final_table_df, all = FALSE) %>%
    na.omit() # Remove any rows with NA values that result from correlation or merging

  # Store the count of remaining formulas for this threshold
  result_df <- rbind(result_df,
                     data.frame(filter_number = i,
                                number_of_rows = nrow(filtered_data)))
}
message("Prevalence analysis completed.")

# Plot Prevalence of MFs by Site Number Threshold
message("\n--- Generating plot for MF prevalence by site number threshold ---")
# Create a bar plot showing the number of molecular formulas that remain
# after filtering by a minimum number of sites they appear in.
p_common_mf_barplot <- ggplot(result_df, aes(x = filter_number, y = number_of_rows)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(
    x = "Site Number",
    y = "No. of MFs",
    title = "Prevalent MFs Bar Plot"
  ) +
  theme_minimal() + # Use a minimal theme for this specific plot
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 24),
    axis.text.y = element_text(size = 24),
    axis.title = element_text(size = 28),
    plot.title = element_text(size = 32, hjust = 0.5),
    text = element_text(size = 24)
  ) +
  # Add reference lines and annotations for significant thresholds (e.g., 15 sites)
  geom_segment(aes(x = 0, y = 7940, xend = 15, yend = 7940),
               color = "red", linetype = "dashed") +
  geom_segment(aes(x = 15, y = 0, xend = 15, yend = 7940),
               color = "red", linetype = "dashed") +
  annotate("text", x = 0, y = 7940, label = "7940",
           hjust = 1, color = "red", size = 10) +
  annotate("text", x = 15, y = 0, label = "15",
           size = 10, color = "red", hjust = 0)

# Save the generated plot to PDF
figsave(p_common_mf_barplot, "Prevalent_MF_barplot.pdf", 20, 10, output_plot_base_dir)

# Filter Prevalent Formulas (Site Number Threshold = 15)
message("\n--- Filtering molecular formulas based on prevalence threshold ---")
# Only keep formulas that appear in more than 15 sites.
# This threshold is often chosen based on the prevalence plot to focus on
# more commonly observed molecular formulas.
mf_filtered_common_df <- merged_mf_env_df %>%
  dplyr::group_by(formula_string, polarity) %>%
  dplyr::filter(n() > 15) %>%
  dplyr::ungroup() # Ungroup after filtering for subsequent operations
message("Molecular formulas filtered.")

# Spearman's rho and p-value Calculation
message("\n--- Calculating Spearman's rho and p-values ---")
# For each environmental variable:
# - Group by molecular formula and polarity.
# - Calculate Spearman correlation (rho) and its p-value between
#   the environmental variable and peak intensity.
# - Store both rho and p-value for each MF-environmental variable pair.

results_list <- lapply(available_env_vars, function(var) {
  mf_filtered_common_df %>%
    group_by(formula_string, polarity) %>%
    # Filter groups with less than 3 data points, as cor.test requires at least 3
    filter(n() >= 3) %>%
    summarise(
      # Directly extract estimate (rho)
      !!paste0("rho(", var, ")") := {
        res <- tryCatch(
          suppressWarnings(cor.test(!!sym(var), peak_intensity, method = "spearman")),
          error = function(e) list(estimate = NA_real_, p.value = NA_real_)
        )
        res$estimate
      },
      # Directly extract p.value
      !!paste0("pval(", var, ")") := {
        res <- tryCatch(
          suppressWarnings(cor.test(!!sym(var), peak_intensity, method = "spearman")),
          error = function(e) list(estimate = NA_real_, p.value = NA_real_)
        )
        res$p.value
      },
      .groups = "drop"
    ) %>%
    # Select only the relevant columns for merging
    dplyr::select(formula_string, polarity, starts_with("rho("), starts_with("pval("))
})
message("Individual correlations calculated.")

# Merge correlation results for all environmental variables into a single data frame.
# This uses `Reduce` with `merge` to iteratively combine all results from the list.
correlation_results <- Reduce(function(...) merge(..., by = c("formula_string", "polarity"), all = TRUE), results_list)
message("Correlation results merged into a single table.")

# Transform Correlation Results for Plotting
message("\n--- Transforming correlation results for plotting ---")
# The subsequent plotting sections (e.g., Spearman ρ Distribution Plots, vK Plots)
# expect a data frame named `spearman_rho_results_df` with columns like
# `formula_string`, `environmental_variable`, and `rho`.
# This step pivots the wide `correlation_results` into the required long format.

# Pivot `correlation_results` from wide to long format for `rho` values.
# This creates a row for each formula-environmental variable-rho combination.
spearman_rho_results_df <- correlation_results %>%
  dplyr::select(formula_string, polarity, starts_with("rho(")) %>% # Select only rho columns and identifiers
  pivot_longer(
    cols = starts_with("rho("),
    names_to = "environmental_variable",
    values_to = "rho"
  ) %>%
  # Clean up the environmental_variable column name (remove "rho()" wrapper)
  dplyr::mutate(
    environmental_variable = stringr::str_remove_all(environmental_variable, "rho\\(|\\)")
  ) %>%
  # Remove rows where rho is NA (e.g., due to insufficient data for correlation)
  dplyr::filter(!is.na(rho))

message("Correlation results transformed for plotting.")

# Merge with MF Properties for Final Table
message("\n--- Merging correlation results with unique MF properties for final output ---")
# Merge the comprehensive correlation results with the unique molecular formula properties.
# This creates a final table (`rho_MF`) that includes all correlations and
# the descriptive chemical properties for each molecular formula.
rho_MF <- merge(correlation_results, mf_unique_props_for_final_table_df, by = c("formula_string", "polarity"), all.x = TRUE) %>%
  na.omit() # Remove any rows with NA values that result from merging

message("Final correlation table (`rho_MF`) constructed.")

# Spearman ρ Distribution Boxplot
message("\n# ---- Starting Spearman ρ Distribution Boxplot ----\n")

# Check if `spearman_rho_results_df` exists and has data for plotting
if (exists("spearman_rho_results_df") && nrow(spearman_rho_results_df) > 0) {
  p_box_rho <- ggplot(spearman_rho_results_df, aes(x = environmental_variable, y = rho)) +
    geom_boxplot(outlier.shape = NA) + # Hide outliers to show them with jitter
    geom_jitter(width = 0.2, alpha = 0.5, size = 0.4, color = "darkblue") + # Add jittered points
    labs(
      title = "Distribution of Spearman's ρ by Environmental Variable",
      x = "Environmental Variable",
      y = expression("Spearman's " * rho) # Use plotmath for rho symbol
    ) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1) # Rotate x-axis labels for readability
    )

  figsave(p_box_rho, "spearman_rho_boxplot.pdf", 9, 6, output_plot_base_dir)
} else {
  message("No Spearman rho results available in `spearman_rho_results_df` to plot boxplot. Skipping plot generation.")
}

message("\n# ---- Spearman ρ Distribution Boxplot Completed ----\n")


# Environmental Parameter Correlation
message("\n# ---- Starting Environmental Parameter Correlation (rho values) ----\n")

# STEP 1 — Prepare data for correlation of rho values
# Pivots `rho_MF` to create a matrix where rows are unique MF-polarity combinations
# and columns are the rho values for each environmental parameter.
if (exists("rho_MF") && nrow(rho_MF) > 0) {
  env_param_rho_matrix_df <- rho_MF %>%
    dplyr::select(formula_string, polarity, dplyr::starts_with("rho(")) %>% # Select only rho columns and identifiers
    tidyr::unite(formula_polarity_id, formula_string, polarity, sep = "_", remove = TRUE) %>% # Create unique ID for rows
    # Convert to tibble to ensure no existing row names, then set new ones.
    tibble::as_tibble() %>%
    tibble::column_to_rownames("formula_polarity_id") %>% # Set the unique ID as row names
    # Rename columns to just parameter name (remove "rho()" for matrix correlation)
    dplyr::rename_with(~gsub("^rho\\(|\\)$", "", .x), dplyr::starts_with("rho(")) %>%
    dplyr::select(dplyr::all_of(available_env_vars)) # Ensure order and only selected vars

  # Check if the matrix has enough dimensions for correlation calculation
  if (ncol(env_param_rho_matrix_df) > 1 && nrow(env_param_rho_matrix_df) > 1) {
    # STEP 2 — Compute Pearson correlation matrix between environmental parameters based on their rho values.
    # This matrix indicates how similarly environmental parameters correlate with the MFs.
    env_param_cor_matrix <- cor(env_param_rho_matrix_df, method = "pearson", use = "pairwise.complete.obs")

    # STEP 3 — Generates a correlation network plot using `corrr::network_plot`.
    # This visually represents strong correlations (above a specified `min_cor` threshold).
    p_env_param_network <- env_param_cor_matrix %>%
      corrr::network_plot(
        min_cor = 0.5, # Only show correlations with absolute value >= 0.5
        repel = TRUE,  # Avoid overlapping labels for clarity
        colors = c("skyblue", "white", "indianred") # Custom color scheme for correlation strength
      ) +
      labs(title = "Correlation Network of Environmental Parameter's Spearman ρ Values",
           subtitle = expression("Edges represent Pearson correlations (absolute value " >= " 0,5)")) +
      theme_void() + # Minimal theme for network plot
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14, margin = margin(b = 10)),
        plot.subtitle = element_text(hjust = 0.5, size = 10),
        legend.position = "bottom",
        plot.margin = margin(1, 1, 1, 1, "cm")
      )

    figsave(p_env_param_network, "Correlation_network_EnvParams.pdf", 11, 7, output_plot_base_dir)

    # STEP 4 — Prepare correlation matrix for heatmap.
    # Rounds values and extracts the upper triangle for a clean heatmap representation.
    cormat_env_param <- round(env_param_cor_matrix, 2) %>%
      reorder_cormat() %>% # Reorder rows/columns based on hierarchical clustering
      get_upper_tri()      # Get only the upper triangle

    # Reshape the matrix to a long format suitable for `ggplot2::geom_tile` (heatmap).
    melted_cormat_env_param <- cormat_env_param %>%
      as.data.frame() %>%
      tibble::rownames_to_column("Var1") %>%
      tidyr::pivot_longer(
        cols = -Var1,
        names_to = "Var2",
        values_to = "value"
      ) %>%
      dplyr::filter(!is.na(value)) # Keep only the upper triangle values

    # Sets factor levels for consistent ordering in the plot.
    ordered_vars <- rev(rownames(cormat_env_param))
    melted_cormat_env_param$Var1 <- factor(melted_cormat_env_param$Var1, levels = ordered_vars)
    melted_cormat_env_param$Var2 <- factor(melted_cormat_env_param$Var2, levels = ordered_vars)

    # STEP 5 — Generates heatmap of environmental parameter correlation matrix.
    ggheatmap_env_param <- ggplot(melted_cormat_env_param, aes(Var2, Var1, fill = value)) +
      geom_tile(color = "black") +
      scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                           midpoint = 0, limit = c(-1, 1), space = "Lab",
                           name = "Pearson\nCorrelation") +
      geom_text(aes(label = value), color = "black", size = 4) +
      theme(
        axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 10),
        axis.text.y = element_text(vjust = 1, hjust = 1, size = 10),
        axis.title.x = element_blank(), axis.title.y = element_blank(),
        panel.grid.major = element_blank(), panel.border = element_blank(),
        panel.background = element_blank(), axis.ticks = element_blank(),
        legend.justification = c(0.5, 0.5), legend.position = "bottom",
        legend.direction = "horizontal", legend.box.margin = margin(t = 10, unit = "pt")
      ) +
      guides(fill = guide_colorbar(barwidth = 12, barheight = 1,
                                   title.position = "top", title.hjust = 0.5)) +
      coord_fixed()

    figsave(ggheatmap_env_param, "Heatmap_EnvParam_Correlation.pdf", 20, 10, output_plot_base_dir)
  } else {
    message("Not enough numeric columns or rows in `env_param_rho_matrix_df` to compute and plot correlation matrix for environmental parameters. Skipping.")
  }
} else {
  message("No Spearman results available for environmental parameter correlation analysis. Skipping.")
}

message("\n# ---- Environmental Parameter Correlation Completed ----\n")


# Molecular Formula (MF) Property Correlation
message("\n# ---- Starting MF Property Correlation Analysis ----\n")

if (!exists("rho_MF") || nrow(rho_MF) == 0) {
  message("No `rho_MF` available or it's empty. Skipping MF property correlation analysis.")
} else {
  # STEP 1 — Select molecular formula (MF) columns.
  # Selects a subset of molecular formula properties for correlation analysis,
  # excluding identifiers and the correlation results themselves.
  mf_props_raw_df <- rho_MF %>% # Use the comprehensive final output table
    dplyr::select(dplyr::all_of(expected_mf_cols_props)) %>% # Select only the defined properties
    dplyr::distinct() # Ensures unique rows of properties for a clean correlation matrix

  # STEP 2 — Standardize MF data.
  # Standardizes the numeric columns using Z-score normalization (`scale_robust`).
  mf_props_numeric_only_df <- mf_props_raw_df %>%
    dplyr::select(where(is.numeric)) # Ensure only numeric columns are selected for scaling

  if (ncol(mf_props_numeric_only_df) == 0) {
    message("No numeric MF properties to standardize or correlate. Skipping MF property correlation plots.")
  } else {
    mf_props_scaled_df <- mf_props_numeric_only_df %>%
      dplyr::mutate(across(dplyr::everything(), .fns = scale_robust)) # Apply robust scaling

    # STEP 3 — Create and plot correlation matrix network.
    # Computes Pearson correlation coefficients for the standardized MF data.
    mf_props_cor_matrix <- cor(mf_props_scaled_df, method = "pearson", use = "pairwise.complete.obs")

    if (ncol(mf_props_cor_matrix) > 1 && nrow(mf_props_cor_matrix) > 1) {
      # Creates a correlation network plot for MF properties.
      p_mf_props_network <- mf_props_cor_matrix %>%
        corrr::network_plot(
          min_cor = 0.8, # Only show correlations with absolute value >= 0.8
          repel = TRUE,  # Avoid overlapping labels
          colors = c("skyblue", "white", "indianred") # Custom color scheme
        ) +
        labs(title = "Correlation Network of Standardized MF Descriptors",
             subtitle = expression("Edges represent Pearson correlations (absolute value " >= " 0,8)")) +
        theme_void() + # Minimal theme for network plot
        theme(
          plot.title = element_text(hjust = 0.5, face = "bold", size = 14, margin = margin(b = 10)),
          plot.subtitle = element_text(hjust = 0.5, size = 10),
          legend.position = "bottom",
          plot.margin = margin(1, 1, 1, 1, "cm")
        )

      figsave(p_mf_props_network, "Correlation_network_MF_Props.pdf", 11, 7, output_plot_base_dir)

      # STEP 4 — Prepare correlation matrix for heatmap.
      cormat_mf_props <- round(mf_props_cor_matrix, 2)
      cormat_mf_props <- cormat_mf_props %>% reorder_cormat() %>% get_upper_tri()

      # Reshapes to long format for ggplot2's `geom_tile` (heatmap).
      melted_cormat_mf_props <- cormat_mf_props %>%
        as.data.frame() %>%
        tibble::rownames_to_column("Var1") %>%
        tidyr::pivot_longer(
          cols = -Var1,
          names_to = "Var2",
          values_to = "value"
        ) %>%
        dplyr::filter(!is.na(value)) # Keeps only the upper triangle values

      # STEP 5 — Generate correlation heatmap.
      # Sets factor levels for consistent ordering in the plot.
      ordered_mf_props <- rev(rownames(cormat_mf_props))
      melted_cormat_mf_props$Var1 <- factor(melted_cormat_mf_props$Var1, levels = ordered_mf_props)
      melted_cormat_mf_props$Var2 <- factor(melted_cormat_mf_props$Var2, levels = ordered_mf_props)

      ggheatmap_mf_props <- ggplot(melted_cormat_mf_props, aes(Var2, Var1, fill = value)) +
        geom_tile(color = "black") +
        scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                             midpoint = 0, limit = c(-1, 1), space = "Lab",
                             name = "Pearson\nCorrelation") +
        geom_text(aes(label = value), color = "black", size = 4) +
        theme(
          axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 10),
          axis.text.y = element_text(vjust = 1, hjust = 1, size = 10),
          axis.title.x = element_blank(), axis.title.y = element_blank(),
          panel.grid.major = element_blank(), panel.border = element_blank(),
          panel.background = element_blank(), axis.ticks = element_blank(),
          legend.justification = c(0.5, 0.5), legend.position = "bottom",
          legend.direction = "horizontal", legend.box.margin = margin(t = 10, unit = "pt")
        ) +
        guides(fill = guide_colorbar(barwidth = 12, barheight = 1,
                                     title.position = "top", title.hjust = 0.5)) +
        coord_fixed()

      figsave(ggheatmap_mf_props, "Heatmap_MF_Props_Correlation.pdf", 20, 10, output_plot_base_dir)
    } else {
      message("Not enough numeric columns or rows in `mf_props_scaled_df` to compute and plot correlation matrix for MF properties. Skipping.")
    }
  }
}

message("\n# ---- MF Property Correlation Analysis Completed ----\n")


# Spearman ρ Distribution Plots
message("\n# ---- Starting Spearman ρ Distribution Plots ----\n")

# Defines the threshold for "no correlation" (e.g., critical r-value for a given N and alpha).
# The value 0.2796061 is often associated with N=25, alpha=0.05 for two-tailed test.
# Adjust this value based on your data's sample size (N) and desired alpha level.
no_corr_threshold <- 0.2796061

# Gets unique environmental variables from the `spearman_rho_results_df` for plotting.
unique_env_vars_rho_plots <- unique(spearman_rho_results_df$environmental_variable)

if (length(unique_env_vars_rho_plots) == 0) {
  message("No unique environmental variables found in `spearman_rho_results_df`. Skipping rho distribution plots.")
} else {
  # Iterates over each unique environmental variable to generate its rho distribution plot.
  for (env_var_to_plot in unique_env_vars_rho_plots) {

    # Filters data for the current environmental variable.
    plot_data_rho_dist <- spearman_rho_results_df %>%
      dplyr::filter(environmental_variable == env_var_to_plot)

    if (nrow(plot_data_rho_dist) > 0) {
      # Builds the density plot.
      rho_plot <- ggplot(plot_data_rho_dist, aes(x = rho)) +
        geom_rect( # Adds grey band for "no correlation" region.
          aes(xmin = -no_corr_threshold, xmax = no_corr_threshold, ymin = -Inf, ymax = Inf),
          fill = "grey", alpha = 0.2
        ) +
        geom_density(alpha = 0.5, fill = "blue", adjust = 1) + # Density curve
        geom_vline(xintercept = -no_corr_threshold, linetype = "dashed", color = "red") + # Negative significance threshold
        labs(
          title = paste("Density Distribution of Spearman's ρ for", env_var_to_plot),
          x = expression("Spearman's " * rho), # Using plotmath for the rho symbol
          y = "Density"
        ) +
        theme(
          plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
          axis.title = element_text(face = "bold", color = "black"),
          axis.text = element_text(color = "black")
        )

      # Saves the plot for the current environmental variable.
      filename <- paste0("distribution_rho_", gsub(" ", "_", env_var_to_plot), ".pdf")
      figsave(rho_plot, filename, 10, 6, Dist_plot_figure_sub_dir)
    } else {
      message(paste0("No data for rho distribution plot for ", env_var_to_plot, ". Skipping plot."))
    }
  }
}

message("\n# ---- Spearman ρ Distribution Plots Completed ----\n")


# Van Krevelen (vK) Plots of Spearman Correlated Values
message("\n# ---- Starting Van Krevelen (vK) Plots ----\n")

# Defines the correlation threshold for categorization (same as for distribution plots).
no_corr_threshold_vk <- no_corr_threshold

# Checks for necessary columns and correlation results before proceeding.
if (length(unique_env_vars_rho_plots) == 0 ||
    !all(c("H/C", "O/C", "formula_string") %in% colnames(mf_unique_props_for_final_table_df))) {
  message("Cannot create Van Krevelen plots. Either no unique environmental variables found, or 'H/C', 'O/C', or 'formula_string' columns are missing from `mf_unique_props_for_final_table_df`.")
} else if (exists("spearman_rho_results_df") && nrow(spearman_rho_results_df) == 0) {
  message("No Spearman correlation results available in `spearman_rho_results_df` to generate vK plots.")
} else {
  # Loops through each unique environmental variable to create a vK plot.
  for (env_var_to_plot in unique_env_vars_rho_plots) {

    # STEP 1 — Prepare data for the current vK plot.
    # Merges rho values for the current environmental variable with unique
    # formula data (containing H/C and O/C ratios).
    plot_data_vk <- mf_unique_props_for_final_table_df %>% # Use the specific table for plotting props
      dplyr::left_join(
        spearman_rho_results_df %>%
          dplyr::filter(environmental_variable == env_var_to_plot) %>%
          dplyr::select(formula_string, rho),
        by = "formula_string"
      ) %>%
      dplyr::mutate( # Assigns color category based on correlation thresholds.
        correlation_category = dplyr::case_when(
          is.na(rho) ~ "No Correlation Data",
          rho < -no_corr_threshold_vk ~ "Negative",
          rho > no_corr_threshold_vk ~ "Positive",
          TRUE ~ "Weak" # Correlations within the no_corr_threshold range
        ),
        # Converts to factor for consistent legend ordering and plotting.
        correlation_category = factor(correlation_category,
                                      levels = c("Negative", "Weak", "Positive", "No Correlation Data"))
      )

    # Filters out rows with NA for H/C or O/C, as these are critical for the plot.
    plot_data_vk <- plot_data_vk %>%
      dplyr::filter(!is.na(`H/C`) & !is.na(`O/C`))

    if (nrow(plot_data_vk) == 0) {
      message(paste0("No valid data points for vK plot for ", env_var_to_plot, ". Skipping plot."))
      next # Skips to next iteration if no data.
    }

    # STEP 2 — Builds the Van Krevelen diagram.
    vk_plot <- ggplot(plot_data_vk, aes(x = `O/C`, y = `H/C`)) +
      geom_point( # Plots weak correlations semi-transparently.
        data = plot_data_vk %>% dplyr::filter(correlation_category == "Weak"),
        aes(color = correlation_category),
        alpha = 0.3, size = 1
      ) +
      geom_point( # Plots positive correlations.
        data = plot_data_vk %>% dplyr::filter(correlation_category == "Positive"),
        aes(color = correlation_category),
        size = 1.5
      ) +
      geom_point( # Plots negative correlations.
        data = plot_data_vk %>% dplyr::filter(correlation_category == "Negative"),
        aes(color = correlation_category),
        size = 1.5
      ) +
      geom_point( # Plots formulas with no correlation data as a distinct, semi-transparent category.
        data = plot_data_vk %>% dplyr::filter(correlation_category == "No Correlation Data"),
        aes(color = correlation_category),
        alpha = 0.1, size = 1
      ) +
      scale_color_manual( # Custom color scale for correlation categories.
        values = c(
          "Negative" = "blue",
          "Weak" = "lightgrey",
          "Positive" = "red",
          "No Correlation Data" = "darkgrey"
        ),
        drop = FALSE # Ensure all levels are shown in legend even if no data for a category
      ) +
      labs(
        title = paste("Van Krevelen Diagram for Spearman ρ with", env_var_to_plot),
        x = "O/C Ratio",
        y = "H/C Ratio",
        color = expression("Spearman's " * rho) # Legend title with rho symbol.
      ) +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        axis.title = element_text(face = "bold", color = "black"),
        axis.text = element_text(color = "black"),
        legend.position = "right",
        legend.title = element_text(face = "bold", color = "black"),
        legend.text = element_text(color = "black")
      ) +
      xlim(0, 1) + # Fixed axis limits for consistency in vK diagrams across plots.
      ylim(0, 2)

    # Saves the plot for the current environmental variable.
    filename <- paste0("vK_", gsub(" ", "_", env_var_to_plot), "_rho_colored.pdf")
    figsave(vk_plot, filename, 10, 6, vK_plot_figure_sub_dir)
  }
}

message("\n# ---- Van Krevelen Plots Completed ----\n")


# Export Final Processed Dataset
message("\n# ---- Exporting Final Dataset ----\n")

if (exists("rho_MF") && nrow(rho_MF) > 0) {
  # Remove highly correlated features to reduce redundancy
  columns_to_exclude <- c("H", "C", "N", "S", "O", "AImod", "AIcon", 
                         "DBE/C", "DBE/H", "DBE-O", "DBE/O", "Xc", 
                         "KMD(CH2)", "KMD(NH2)", "ZX")
  
  message(paste("Removing", length(columns_to_exclude), "highly correlated columns to reduce redundancy:", 
                paste(columns_to_exclude, collapse = ", ")))
  
  # Remove specified columns before export
  final_rho_MF_export <- rho_MF %>%
    dplyr::select(
      -any_of(c("formula_class", "structure_class")), # Remove these specific columns
      -any_of(columns_to_exclude), # Remove highly correlated features
      -starts_with("pval(") # Remove all columns starting with "pval("
    )

  # --- Transform 'polarity' column to numerical values before export ---
  # This step converts the categorical polarity column ("LP", "MP", "HP")
  # into numerical representation (1, 2, 3) for potential compatibility
  # with some downstream tools or models that prefer numeric inputs.
  if ("polarity" %in% colnames(final_rho_MF_export)) {
    final_rho_MF_export <- final_rho_MF_export %>%
      mutate(polarity = case_when(
        polarity == "LP" ~ 1,
        polarity == "MP" ~ 2,
        polarity == "HP" ~ 3,
        TRUE ~ NA_real_ # Handle any other unexpected values
      ))
    message("Polarity column converted to numerical representation (LP=1, MP=2, HP=3).")
  } else {
    message("Polarity column not found in `final_rho_MF_export`. Skipping numerical conversion.")
  }
  # --- End of polarity transformation ---

  output_filepath <- file.path(output_processed_data_dir, "rho_MF.csv")

  tryCatch({
    readr::write_csv(final_rho_MF_export, output_filepath)
    message(paste0("Final Spearman analysis results exported successfully to: ", output_filepath))
  }, error = function(e) {
    message(paste0("Failed to export final Spearman analysis results: ", e$message))
  })
} else {
  message("The 'rho_MF' dataset is not available or is empty. Skipping export.")
}

message("\n# ---- Final Dataset Export Completed ----\n")


# Session Cleanup
message("Script execution complete!")
