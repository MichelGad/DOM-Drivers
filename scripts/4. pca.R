# =============================================================================
# Script: 4. pca.R
# Purpose: Principal Component Analysis and dimensionality reduction for DOM analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Perform PCA on both environmental parameters and intensity-weighted averaged molecular data
#   - Integrate land class information to color and group samples in PCA biplots
#   - Generate scree plots to assess explained variance and guide component selection
#   - Output PCA biplots showing relationships between samples and variables
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Print script header information
cat("=============================================================================\n")
cat("Script: 4. pca.R\n")
cat("Purpose: Principal Component Analysis and dimensionality reduction for DOM analysis\n")
cat("Author: Michel Gad\n")
cat("Date: 2025-09-15\n")
cat("Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018\n")
cat("=============================================================================\n\n")

# 0. Load essential packages
# These libraries provide critical functions for data manipulation, visualization,
# and multivariate statistical analysis, adhering to the tidyverse principles.
message("\n--- Loading essential packages for principal component analysis ---")
library(tidyverse)    # Data science package collection (includes dplyr, tidyr, ggplot2, readr)
library(data.table)   # Efficient large data import (fread)
library(FactoMineR)   # Multivariate exploratory data analysis (for PCA)
library(factoextra)   # Visualizing multivariate analysis results (for fviz_pca_biplot)
message("Essential packages loaded successfully.")

# --- Define Output Directories and Global Settings ---
# These paths specify where processed data and plots will be saved.
# Directories are created if they do not already exist to prevent errors,
# ensuring a structured output organization.
message("\n--- Setting up output directories and global plotting theme ---")
output_plot_dir <- "output/pca"
output_processed_data_dir <- "processed/pca" # Sub-directory for PCA-specific processed data

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
              legend.title = element_text(face = "bold", color = "black"),
              legend.text = element_text(color = "black"),
              panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
              panel.grid.minor = element_line(color = "grey95", linewidth = 0.25),
              strip.background = element_rect(fill = "grey85", color = "black"),
              strip.text = element_text(face = "bold", color = "black")
            ))

# Set numerical output to not use scientific notation for better readability.
options(scipen = 999)
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

# --- Land Class Definitions and Colors ---
# These constants define the mapping rules for converting raw numeric 'Coverage'
# codes into descriptive land class labels and specify a consistent color palette
# for visualizing these land classes in plots.
land_class_mapping_rules <- c(
  "2" = "DB", "4" = "NEE", "13" = "HCCO", "14" = "SpHerb",
  "16" = "SSC", "17" = "MCTO", "22" = "ASA"
)

# Define color palette for each land class label.
land_class_colors_map <- c(
  "DB" = "#0273C2", "NEE" = "#FFBF00", "HCCO" = "#868686", "MCTO" = "#CD534C",
  "SSC" = "#7AA6DC", "SpHerb" = "#8F7700", "ASA" = "#013D68", "Other" = "grey50" # 'Other' for unmapped values
)

# --- PCA Helper Functions ---
# This section defines custom functions to streamline the PCA process,
# including computing PCA, preparing data for scree plots, and generating
# visually informative scree plots and biplots.

# PCA Computation Function
# This wrapper function for `FactoMineR::PCA` performs Principal Component Analysis
# on the input data. It handles infinite values, drops NAs, and ensures sufficient
# data for PCA, returning both the PCA result object and the data subset actually used.
compute_pca <- function(data, ncp = 5) {
  # Convert to data.frame to ensure row names are preserved
  data_for_pca <- as.data.frame(data) %>%
    # Replace infinite values with NA, then remove rows with any NA values
    dplyr::mutate(across(where(is.numeric), ~ replace(.x, is.infinite(.x), NA))) %>%
    tidyr::drop_na()

  # Check if enough valid data remains for PCA
  if (nrow(data_for_pca) < 2 || ncol(data_for_pca) < 2) {
    stop("Not enough valid data (at least 2 rows and 2 numeric columns) after NA/Inf removal for PCA.")
  }

  # Perform PCA: scale.unit = TRUE standardizes data (mean 0, variance 1)
  res.pca <- FactoMineR::PCA(data_for_pca, ncp = ncp, scale.unit = TRUE, graph = FALSE)

  # Return both the PCA result and the actual data rows used for PCA
  list(pca_result = res.pca, data_used_for_pca = data_for_pca)
}

# Prepare Scree Plot Data Function
# This function extracts eigenvalues and cumulative variance explained from a PCA
# result object and structures them into a data frame suitable for plotting a scree plot.
prepare_scree_data <- function(pca_result) {
  eigenvalues <- pca_result$eig[, 1]  # Extract eigenvalues
  cumulative_variance <- cumsum(pca_result$eig[, 2])  # Calculate cumulative variance
  components <- 1:length(eigenvalues)

  plot_data <- data.table(
    Component = components,
    Eigenvalue = eigenvalues,
    CumulativeVariance = cumulative_variance
  )
  return(plot_data)
}

# Create Scree Plot Function
# This function generates a scree plot, which is used to determine the optimal number
# of principal components to retain in a PCA. It visually represents eigenvalues and
# cumulative explained variance, often highlighting an "elbow point."
create_scree_plot <- function(plot_data, elbow_point, file_name, output_dir) {
  scree.plot <- ggplot(plot_data, aes(x = Component)) +
    geom_point(aes(y = Eigenvalue, color = "Eigenvalue")) +
    geom_line(aes(y = Eigenvalue, color = "Eigenvalue")) +
    geom_point(aes(y = CumulativeVariance / max(CumulativeVariance) * max(Eigenvalue), color = "Cumulative Variance")) +
    geom_line(aes(y = CumulativeVariance / max(CumulativeVariance) * max(Eigenvalue), color = "Cumulative Variance")) +
    geom_vline(xintercept = elbow_point, linetype = "dashed", color = "green", linewidth = 1, aes(color = "Elbow Point")) +
    scale_x_continuous(breaks = plot_data$Component, labels = plot_data$Component) +
    scale_y_continuous(name = "Eigenvalue",
                       sec.axis = sec_axis(~ . / max(plot_data$Eigenvalue) * 100, name="Cumulative Variance (%)")) +
    scale_color_manual(values = c("Eigenvalue" = "blue", "Cumulative Variance" = "red", "Elbow Point" = "green")) +
    labs(title = "Scree Plot with Cumulative Variance", x = "Principal Component Number") +
    theme(legend.title = element_blank(), legend.position = "top")

  figsave(scree.plot, file_name, width = 11, height = 7, output_dir) # Consistent plot dimensions
}

# Create PCA Biplot Function
# This function generates a PCA biplot using `factoextra::fviz_pca_biplot`,
# which simultaneously visualizes the relationships between observations (points)
# and variables (arrows) in the PCA space. It includes customizations for colors,
# labels, and transparency based on variable contributions.
create_pca_biplot <- function(res.pca, file_name, individual_colors_factor, output_dir,
                              colors_map, plot_title, hide_individuals = FALSE) {
  # Determine if individual points should be drawn
  geom_ind = if(hide_individuals) "none" else c("point")

  # Prepare variable coloring based on their names (e.g., "wa_" prefix for weighted aggregated)
  variable_df <- as.data.frame(res.pca$var$coord) %>%
    tibble::rownames_to_column("Variable") %>%
    dplyr::mutate(Type = dplyr::case_when(
      grepl("^wa", Variable, ignore.case = TRUE) ~ "Weighted Aggregated",
      TRUE ~ "Water Parameter"
    ))

  # Define specific colors for variable types
  var_colors_palette_for_biplot <- c("Weighted Aggregated" = "#E41A1C", "Water Parameter" = "#377EB8")

  PCA.plot <- factoextra::fviz_pca_biplot(res.pca,
                               geom.ind = geom_ind,
                               fill.ind = individual_colors_factor, # Set fill color for individuals
                               col.ind = "transparent", # Set outline color to transparent for solid dots
                               repel = TRUE, # Avoid overlapping labels
                               pointshape = 21, pointsize = 5, # Use specified point shape and size
                               col.var = var_colors_palette_for_biplot[variable_df$Type], # Explicit colors for variables
                               alpha.var = "contrib", # Transparency of variables based on their contribution
                               labelsize = 7,  # Variable labels size
                               addlabels.ind = TRUE,  # Add individual labels
                               labelsize.ind = 6 # Individual labels size
                               ) +
              # Manually set colors and labels for individual points (land_class)
              scale_fill_manual(values = colors_map, labels = names(colors_map), name = "Land Class") +
              labs(title = plot_title) +
              theme(
                 plot.title = ggplot2::element_text(size = 16, hjust = 0.5, face = "bold"),
                 axis.title = ggplot2::element_text(size = 14, face = "bold", color = "black"),
                 axis.text = ggplot2::element_text(size = 12, color = "black"), # Consistent axis text size
                 legend.title = ggplot2::element_text(size = 14, face = "bold", color = "black"),
                 legend.text = ggplot2::element_text(size = 12, color = "black") # Consistent legend text size
              )

  figsave(PCA.plot, file_name, width = 11, height = 7, output_dir) # Consistent plot dimensions
}

# --- Data Import and Initial Cleaning ---
# This section imports the necessary processed environmental and weighted averaged
# data files, as well as raw coverage information. It performs initial checks
# and processing to ensure data consistency and readiness for PCA.
message("\n--- Importing and preparing data for PCA analysis ---")

# 1. Import necessary data files
# Loads three critical datasets: processed environmental parameters, processed
# weighted averaged data, and raw environmental data for land class information.
# Includes robust error handling for file loading and checks for essential columns.
tryCatch({
  # Import processed environmental parameters
  parameters <- as.data.table(fread(file.path(getwd(), "processed/parameters_env_processed.csv"), na.strings = c("", "NA"), encoding = "UTF-8"))
  # Import processed weighted averaged data
  wa.mean.samples <- as.data.table(fread(file.path(getwd(), "processed/wa_mean_processed.csv"), na.strings = c("", "NA"), encoding = "UTF-8"))
  # Load coverage information from original environment file to extract land_class
  coverage_raw <- as.data.table(fread(file.path(getwd(), "input/env_2025-01-21.csv"), na.strings = c("", "NA"), encoding = "UTF-8"))

  # Check if 'Coverage' column exists in the raw coverage data
  if (!"Coverage" %in% colnames(coverage_raw)) {
    stop("'Coverage' column not found in 'env_2025-01-21.csv'. Please check the file.")
  }

  # Select relevant columns from coverage and process 'Coverage' to 'land_class' factor
  # This step maps numeric coverage codes to descriptive labels and converts them to factors
  # for consistent plotting and grouping in PCA biplots.
  coverage_processed <- coverage_raw %>%
    dplyr::select(measurement_name, Coverage) %>%
    dplyr::rename(land_class = Coverage) %>%
    dplyr::mutate(
      measurement_name = as.character(measurement_name),
      # Use recode to map numeric codes to descriptive labels, with a default for unmapped values
      land_class = dplyr::recode(as.character(land_class), !!!land_class_mapping_rules, .default = "Other"),
      # Set factor levels for consistent plotting order and colors
      land_class = factor(land_class, levels = names(land_class_colors_map))
    )

  # Check if essential data frames are loaded and not empty
  if (nrow(parameters) == 0 || nrow(wa.mean.samples) == 0 || nrow(coverage_processed) == 0) {
    stop("One or more essential input files are empty after loading. Cannot proceed with PCA.")
  }

  # Ensure 'measurement_name' is character for merging consistency for all data tables
  parameters[, measurement_name := as.character(measurement_name)]
  wa.mean.samples[, measurement_name := as.character(measurement_name)]

}, error = function(e) {
  stop(paste("Error loading or processing initial data files for PCA:", e$message))
})
message("Data files loaded and processed successfully.")

# --- PCA for Water Parameters ---
# This section performs Principal Component Analysis on the environmental
# (water quality) parameters, generates a scree plot to assess explained
# variance, and creates a biplot to visualize the PCA results, including
# sample grouping by land class.
message("\n--- Performing PCA on environmental parameters ---")

# 1. Prepare data for PCA
# Selects only the numeric columns from the environmental parameters dataframe,
# excluding identifiers like `measurement_name`, to prepare the data matrix for PCA.
parameters_for_pca_data <- parameters %>%
  dplyr::select(-any_of("measurement_name")) %>%
  dplyr::select(where(is.numeric))

# 2. Perform PCA and capture results along with the data rows used
# Calls the `compute_pca` helper function to run PCA on the prepared environmental
# data, storing the PCA results object and the exact data rows used for the analysis.
pca_results_para <- compute_pca(parameters_for_pca_data, ncp = 9)
res.pca.para <- pca_results_para$pca_result
data_used_for_para_pca <- pca_results_para$data_used_for_pca

# 3. Extract loadings from PCA results
# Extracts the variable coordinates (loadings) from the PCA result, which represent
# the contribution of each original variable to the principal components.
loadings.para <- data.table(Variable = rownames(res.pca.para$var$coord), res.pca.para$var$coord)

# 4. Prepare data for Scree Plot
# Uses the `prepare_scree_data` helper function to extract eigenvalues and
# cumulative variance for the scree plot of environmental parameters.
plot_data.para <- prepare_scree_data(res.pca.para)

# 5. Create and save Scree Plot for parameters
# Generates and saves the scree plot for environmental parameters, aiding in
# determining the optimal number of components to retain (e.g., using an elbow point).
create_scree_plot(plot_data.para, 5, "scree_para.pdf", output_plot_dir) # Elbow point 5 from RMD

# 6. Prepare individual colors for PCA Biplot
# Maps the `measurement_name` of the samples used in PCA to their corresponding
# `land_class` from the processed coverage data. This is crucial for coloring
# sample points in the biplot according to their land class.
pca_individual_names_para <- rownames(data_used_for_para_pca)
individual_colors_para <- data.frame(measurement_name = pca_individual_names_para) %>%
  dplyr::left_join(coverage_processed, by = "measurement_name") %>%
  dplyr::pull(land_class)

# Handle potential NAs in colors (e.g., if a measurement_name was not found in coverage_processed)
if (any(is.na(individual_colors_para))) {
  warning("Some 'measurement_name' from 'parameters' PCA individuals did not match 'land_class' data. Missing 'land_class' values will be assigned 'Other'.")
  individual_colors_para[is.na(individual_colors_para)] <- "Other"
}
# Ensure it's a factor with the correct levels for consistent plotting
individual_colors_para <- factor(individual_colors_para, levels = names(land_class_colors_map))

# 7. Create and save PCA Biplot for parameters
# Generates and saves the PCA biplot for environmental parameters, visually
# representing sample distributions and variable contributions in the PCA space,
# colored by their associated land class.
create_pca_biplot(res.pca.para, "PCA_para.pdf", individual_colors_para, output_plot_dir,
                  land_class_colors_map, "PCA of Water Parameters")

# --- PCA for Weighted Averaged Data ---
# This section mirrors the PCA for environmental parameters but applies it
# to the weighted averaged molecular data. It includes data preparation, PCA
# computation, scree plot generation, and biplot visualization based on land class.
message("\n--- Performing PCA on weighted averaged molecular data ---")

# 1. Prepare data for PCA
# Selects relevant `wa_` prefixed columns from the weighted averaged data,
# excluding specific molecular descriptors that are not part of this PCA,
# and retaining only numeric data for the PCA input matrix.
wa_data_for_pca_prep <- wa.mean.samples %>%
  dplyr::select(measurement_name, starts_with("wa_")) %>%
  dplyr::left_join(coverage_processed, by = "measurement_name") %>% # Join for land_class for later coloring
  dplyr::select(
    -starts_with("wa_z_star"), # Specific 'wa_' columns to exclude from PCA calculation
    -starts_with("wa_f_star"),
    -starts_with("wa_ai_mod_"),
    -any_of(c("measurement_name", "land_class")) # Exclude identifiers and grouping variable from PCA input
  ) %>%
  dplyr::select(where(is.numeric))

# 2. Perform PCA and capture results along with the data rows used
# Calls the `compute_pca` helper function to run PCA on the prepared weighted
# averaged data, storing the PCA results object and the exact data rows used.
pca_results_wa <- compute_pca(wa_data_for_pca_prep, ncp = 5)
res.pca.wa <- pca_results_wa$pca_result
data_used_for_wa_pca <- pca_results_wa$data_used_for_pca

# 3. Extract loadings from PCA results
# Extracts the variable coordinates (loadings) from the PCA result for weighted
# averaged data, showing how each molecular descriptor contributes to the components.
loadings.wa <- data.table(Variable = rownames(res.pca.wa$var$coord), res.pca.wa$var$coord)

# 4. Prepare data for Scree Plot
# Uses the `prepare_scree_data` helper function to extract eigenvalues and
# cumulative variance for the scree plot of weighted averaged data.
plot_data.wa <- prepare_scree_data(res.pca.wa)

# 5. Create and save Scree Plot for weighted averaged data
# Generates and saves the scree plot for weighted averaged data, helping to
# identify the optimal number of principal components.
create_scree_plot(plot_data.wa, 5, "scree_wa.pdf", output_plot_dir) # Elbow point 5 from RMD

# 6. Prepare individual colors for PCA Biplot
# Maps the `measurement_name` of the samples used in PCA to their corresponding
# `land_class` from the processed coverage data. This is crucial for coloring
# sample points in the biplot according to their land class.
pca_individual_names_wa <- rownames(data_used_for_wa_pca)
individual_colors_wa <- data.frame(measurement_name = pca_individual_names_wa) %>%
  dplyr::left_join(coverage_processed, by = "measurement_name") %>%
  dplyr::pull(land_class)

# Handle potential NAs in colors
if (any(is.na(individual_colors_wa))) {
  warning("Some 'measurement_name' from 'wa.mean.samples' PCA individuals did not match 'land_class' data. Missing 'land_class' values will be assigned 'Other'.")
  individual_colors_wa[is.na(individual_colors_wa)] <- "Other"
}
# Ensure it's a factor with the correct levels for consistent plotting
individual_colors_wa <- factor(individual_colors_wa, levels = names(land_class_colors_map))

# 7. Create and save PCA Biplot for weighted averaged data
# Generates and saves the PCA biplot for weighted averaged data, visualizing
# sample distributions and molecular descriptor contributions, colored by
# associated land class.
create_pca_biplot(res.pca.wa, "PCA_wa.pdf", individual_colors_wa, output_plot_dir,
                  land_class_colors_map, "PCA of Weighted Averaged Data")

# --- Export Loadings ---
# This section exports the PCA loadings (variable contributions to principal components)
# for both environmental parameters and weighted averaged data to CSV files.
# These files are useful for external analysis or reporting of PCA results.
message("\n--- Exporting PCA loadings ---")

# Export the loadings for weighted averaged data
write_csv(loadings.wa, file.path(output_processed_data_dir, "loadings_wa.csv"))
# Export the loadings for environmental parameters
write_csv(loadings.para, file.path(output_processed_data_dir, "loadings_para.csv"))
message("PCA loadings exported successfully.")

message("Script execution complete!")
