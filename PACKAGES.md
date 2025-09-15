# Required Packages for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)

This document lists all the R and Python packages required for the Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) pipeline, which supports the analysis of dissolved organic matter (DOM) composition and environmental drivers in Central European aquatic systems.

**Supporting Publication**: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018

## R Packages

### Core Data Manipulation Packages
- **tidyverse**: Collection of core tidyverse packages (dplyr, tidyr, ggplot2, readr, purrr, forcats, stringr, tibble)
- **data.table**: Enhanced data frames for efficient large data operations

### Statistical Analysis Packages
- **FactoMineR**: Multivariate exploratory data analysis for PCA and dimensionality reduction
- **factoextra**: Extract and visualize results from multivariate data analyses
- **corrr**: Tidy correlation analysis for DOM-environment relationships

### Visualization Packages
- **ggplot2**: Grammar of graphics plotting system
- **RColorBrewer**: Color palettes for attractive plots

### Optional Packages
- **rgl**: 3D visualization (optional for certain plots)

## Python Packages

### Core Data Manipulation Packages
- **pandas**: Data manipulation and analysis library
- **numpy**: Fundamental package for scientific computing

### Visualization Packages
- **matplotlib**: Comprehensive plotting library
- **plotly**: Interactive graphing library

### Machine Learning and Analysis Packages
- **scikit-learn**: Machine learning library with regression, classification, and model evaluation tools
- **xgboost**: Scalable, Portable, and Distributed Gradient Boosting (used for tree models)

### Model Interpretability
- **shap**: SHapley Additive exPlanations for model interpretability

### Additional Utilities
- **scipy**: Scientific computing library

## Installation

All packages are automatically installed when running `run_all.sh`. The script will:

1. **Python Environment Setup:**
   - Check if Python 3.8+ is available
   - Install Python packages from `requirements.txt`
   - Verify all packages can be imported

2. **R Package Setup:**
   - Check which R packages are already installed
   - Install any missing packages from CRAN using `install_r_packages.R`
   - Verify that all packages can be loaded successfully

## Manual Installation

### Python Packages

Install packages using pip:

```bash
# Install all packages from requirements.txt
pip install -r requirements.txt
```

Or install individually:

```bash
pip install pandas numpy matplotlib plotly scikit-learn xgboost shap scipy
```

### R Packages

Install all required R packages:

```r
# Install all required packages
install.packages(c(
  "tidyverse", "data.table", "stringr", "forcats",
  "FactoMineR", "factoextra", "corrr", "MASS",
  "ggplot2", "RColorBrewer", "patchwork", "ggpubr", "ggsci", "htmltools", "scales"
), repos="https://cran.rstudio.com/", dependencies=TRUE)
```

Or use the standalone installation script:

```bash
Rscript install_r_packages.R
```

## Package Usage by Script

### R Scripts

#### env.R (Environmental Parameter Processing)
- tidyverse (dplyr, tidyr, readr, purrr)
- data.table
- stringr
- ggplot2
- RColorBrewer
- scales

#### wa.R (Weighted Average Calculations)
- tidyverse (dplyr, tidyr, readr)
- data.table
- ggplot2
- RColorBrewer
- scales

#### mf.R (Molecular Formula Processing)
- tidyverse (dplyr, tidyr, readr, purrr, stringr)
- data.table
- ggplot2
- RColorBrewer
- scales

#### pca.R (Principal Component Analysis)
- tidyverse (dplyr, tidyr, ggplot2)
- FactoMineR
- factoextra
- RColorBrewer
- patchwork
- scales

#### corr.R (Correlation Analysis)
- tidyverse (dplyr, tidyr, ggplot2)
- corrr
- RColorBrewer
- patchwork
- scales
- htmltools

### Python Scripts

#### MRF.py (Machine Learning Random Forest)
- pandas
- numpy
- matplotlib
- plotly
- scikit-learn
- xgboost
- shap
- scipy

## System Requirements

### R
- **Version**: R 4.0 or higher
- **Platform**: Windows, macOS, Linux
- **Memory**: Minimum 8GB RAM recommended (for large FT-ICR MS datasets)
- **Storage**: 1GB for packages and dependencies

### Python
- **Version**: Python 3.8 or higher
- **Platform**: Windows, macOS, Linux
- **Memory**: Minimum 8GB RAM recommended (for machine learning models)
- **Storage**: 2GB for packages and dependencies

## Scientific Context

This package collection supports the Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) pipeline designed for:

- **DOM Characterization**: Analysis of dissolved organic matter composition from FT-ICR MS data
- **Environmental Correlation**: Understanding relationships between molecular features and environmental parameters
- **Predictive Modeling**: Machine learning approaches to predict DOM composition from environmental drivers
- **Interpretable Analysis**: SHAP analysis for understanding model predictions and feature importance

## Data Requirements

The DOM-Drivers pipeline expects specific input files:

- `input/env_2025-01-21.csv`: Environmental parameter data
- `input/formulas.clean_2025-01-21.csv`: Molecular formula data from FT-ICR MS
- `input/eval.summary.clean_2025-01-21.csv`: Evaluation summary data

These files are available from the UFZ Data Repository: https://doi.org/10.48758/ufz.15515

## Troubleshooting

### Common Installation Issues

1. **R Package Installation Failures:**
   - Ensure you have the latest version of R
   - Check internet connection for CRAN access
   - Try installing packages individually
   - On macOS, you may need to install Xcode command line tools

2. **Python Package Installation Failures:**
   - Ensure you have pip installed and updated
   - Check Python version compatibility
   - Consider using a virtual environment
   - On some systems, you may need to install system dependencies

3. **Memory Issues with Large Datasets:**
   - Increase R memory limit: `memory.limit(size = 16000)` (Windows)
   - Use data.table for efficient data processing
   - Consider processing data in chunks for very large datasets

### Getting Help

If you encounter issues with package installation:

1. Check the package documentation
2. Search for error messages online
3. Ensure your system meets the minimum requirements
4. Consider using conda or virtual environments for Python packages
5. Check the Water Research publication for methodological guidance

## Version Compatibility

This pipeline has been tested with the following package versions:

- R 4.2.0+
- Python 3.8+
- tidyverse 1.3.0+
- pandas 1.3.0+
- scikit-learn 1.0.0+
- shap 0.40.0+
- xgboost 1.5.0+

For the most up-to-date compatibility information, refer to the individual package documentation and the supporting publication.

## Citation

If you use this package collection in your research, please cite:

```
Gad, M., Tayyebi Sabet Khomami, N., Krieg, R., Schor, J., Philippe, A., & Lechtenfeld, O. J. (2024). 
Environmental drivers of dissolved organic matter composition across central European aquatic systems: 
A novel correlation-based machine learning and FT-ICR MS approach. Water Research, 123018.
DOI: 10.1016/j.watres.2024.123018
```