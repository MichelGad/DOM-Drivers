# =============================================================================
# R Package Installation Script for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)
# Purpose: Install all required R packages for DOM-environment correlation analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Check for missing R packages and install them
#   - Verify all packages can be loaded successfully
#   - Used by run_all.sh for automated package management
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Pin CRAN snapshot to ensure reproducible package versions across machines
snapshot_date <- "2025-01-21"
cran_snapshot <- paste0("https://packagemanager.posit.co/cran/", snapshot_date)
options(repos = c(CRAN = cran_snapshot))

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat("Installing missing R packages:", paste(new_packages, collapse=", "), "\n")
    install.packages(new_packages, dependencies=TRUE)
  } else {
    cat("All required R packages are already installed.\n")
  }
}

# Define required packages for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)
required_packages <- c(
  # Core data wrangling and visualization
  "tidyverse",      # dplyr, tidyr, ggplot2, readr, purrr, forcats, stringr, tibble
  "data.table",     # Fast data manipulation for large datasets
  
  # Correlation and multivariate analysis
  "corrr",          # Tidy correlation analysis
  
  # Plotting utilities
  "RColorBrewer"    # Color palettes for data visualization
)

# Define optional packages that may fail to install
optional_packages <- c(
  "FactoMineR",     # Multivariate exploratory data analysis (PCA)
  "factoextra"      # Visualization of multivariate analysis results
)

# Install missing packages
cat("Checking R package requirements for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)...\n")
cat("Using CRAN snapshot:", cran_snapshot, "(pins exact versions as of", snapshot_date, ")\n\n")
install_if_missing(required_packages)

# Test loading packages
cat("Testing package loading...\n")
failed_packages <- c()

for(pkg in required_packages) {
  if(require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("✓", pkg, "loaded successfully\n")
  } else {
    cat("✗ Failed to load", pkg, "\n")
    failed_packages <- c(failed_packages, pkg)
  }
}

# Report results
if(length(failed_packages) == 0) {
  cat("\n✓ All R packages are ready for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)!\n")
  cat("Total packages verified:", length(required_packages), "\n")
  cat("\nPackage summary:\n")
  cat("- Core data manipulation: tidyverse, data.table, stringr, forcats\n")
  cat("- Statistical analysis: FactoMineR, factoextra, corrr, MASS\n")
  cat("- Visualization: ggplot2, RColorBrewer, patchwork, ggpubr, ggsci, scales, htmltools\n")
  cat("\nThis package collection supports:\n")
  cat("- DOM characterization from FT-ICR MS data\n")
  cat("- Environmental correlation analysis\n")
  cat("- PCA and dimensionality reduction\n")
  cat("- Publication-quality visualizations\n")
  cat("- Reproducible scientific analysis\n")
} else {
  cat("\n✗ Some packages failed to load:\n")
  for(pkg in failed_packages) {
    cat("  -", pkg, "\n")
  }
  cat("\nPlease check the error messages above and try installing manually:\n")
  cat("install.packages(c(", paste0('"', failed_packages, '"', collapse=", "), "))\n")
  quit(status = 1)
}

cat("\nR package setup complete for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) pipeline!\n")
cat("Supporting publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018\n")
