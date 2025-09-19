# Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (**DOM-Drivers**)

## 🎯 Introduction

This directory contains a complete data analysis pipeline used in the associated Water Research publication (DOI: 10.1016/j.watres.2024.123018). The pipeline processes molecular formula data, performs comparative analyses, creates publication-ready visualizations, and exports comprehensive results.

The pipeline is implemented in R and Python and includes raw data import and preprocessing, statistical analysis, dimensionality reduction (PCA), correlation assessment, and interpretable machine learning modeling. It is the exact computational workflow used to generate the results and figures reported in the paper.

## 📄 Supporting Research Publication

This project serves as the computational framework for processing and analyzing the data presented in the following scientific paper:

**Title**: "Environmental drivers of dissolved organic matter composition across central European aquatic systems: A novel correlation-based machine learning and FT-ICR MS approach"
**Authors**: Michel Gad, Narjes Tayyebi Sabet Khomami, Ronald Krieg, Jana Schor, Allan Philippe, Oliver J. Lechtenfeld
**Journal**: Water Research
**DOI**: 10.1016/j.watres.2024.123018 (https://doi.org/10.1016/j.watres.2024.123018)

This repository provides the code base necessary to reproduce the data processing, statistical analyses, and machine learning models applied to the Dissolved Organic Matter (DOM) and environmental parameter datasets within Central European aquatic systems, contributing directly to the findings and figures in the publication.

## 🛠️ How It Works

This project is structured as a modular pipeline, primarily leveraging R for data processing and statistical analysis, and Python for advanced machine learning and model interpretability.

---

### 1. Data Import, Preprocessing & Feature Engineering

These scripts are responsible for handling raw data, cleaning it, performing necessary transformations (like decimal conversions), and calculating crucial molecular descriptors. They prepare the data for downstream statistical and machine learning tasks.

* **`1. mf.R`**:
    * Imports and cleans raw molecular formula data (e.g., from FT-ICR MS).
    * Handles comma-separated decimals, polarity indicators, and standardizes names.
    * Computes intensity-weighted averages of these molecular properties for each sample.
    * Analyzes and plots the relative abundance of molecular formula classes (CHO, CHNO, CHNOS, CHOS).
    * Generates density distributions, normality box plots, and correlation networks of molecular formula parameters.

* **`2. env.R`**:
    * Imports and cleans raw environmental parameter data.
    * Handles comma-separated decimals and standardizes names.
    * Performs Z-score normalization.
    * Generates diagnostic plots: density distributions, normality box plots, and correlation networks of environmental parameters.

* **`3. wa.R`**:
    * Processes and aggregates raw molecular data to calculate intensity-weighted average molecular descriptors.
    * Handles polarity fractions and cleans measurement names for consistent grouping.
    * Performs Z-score normalization on weighted averages.
    * Visualizes density distributions, normality box plots, and correlation networks of weighted average parameters.

---

### 2. Dimensionality Reduction

This script applies Principal Component Analysis (PCA) to reduce the complexity of the datasets and visualize the primary sources of variation.

* **`4. pca.R`**:
    * Performs PCA on both environmental parameters and intensity-weighted averaged molecular data.
    * Integrates land class information to color and group samples in PCA biplots, aiding in visual interpretation of environmental influences.
    * Generates scree plots to assess explained variance and guide component selection.
    * Outputs PCA biplots showing relationships between samples and variables.

---

### 3. Inter-data Correlation Analysis

This script quantifies the relationships between molecular features and environmental variables, providing insights into which molecular properties are associated with specific environmental conditions.

* **`5. corr.R`**:
    * Calculates Spearman correlation coefficients between molecular formula peak intensities and environmental parameters.
    * Analyzes the prevalence of molecular formulas across different sites.
    * Generates distribution plots of Spearman's rho values for each environmental variable.
    * Creates correlation networks and heatmaps for:
        * Environmental parameters based on the similarity of their correlation profiles with MFs.
        * Molecular formula properties (e.g., H/C, O/C).
    * Generates Van Krevelen (vK) diagrams where molecular formulas are colored based on their correlation strength (positive, negative, weak) with specific environmental variables.

---

### 4. Machine Learning Regression & Interpretability

This Python-based module builds predictive models to explore how molecular features can explain environmental variations, utilizing advanced techniques for model robustness and interpretability.

* **`6. MRF.py`** (utilizing **`processing.py`**):
    * Prepares data for a Random Forest Regression model, using the comprehensive correlation results from `5. corr.R` as input.
    * Implements outlier detection using Isolation Forest to enhance model robustness.
    * Performs Repeated K-Fold Cross-Validation for rigorous model evaluation.
    * Applies SHapley Additive exPlanations (SHAP) to interpret model predictions, showing how each molecular feature contributes to the output. Generates SHAP summary, bar, and beeswarm plots.
    * Calculates permutation feature importance to identify the most impactful features in the model.

## 🚀 Getting Started

Ready to analyze your environmental omics data? Follow these steps to set up the project and run the complete DOM-Drivers pipeline.

### Detailed Setup

If you prefer manual control or need to troubleshoot, follow these detailed steps:

#### 1. Project Setup

First, clone the repository to your local machine:

```bash
git clone https://github.com/MichelGad/DOM-Drivers.git
cd DOM-Drivers
```

Create the necessary input and output directories:

```bash
mkdir input
mkdir output
mkdir processed
```

#### 2. Obtain Raw Data

The raw data used in this project is openly available through the UFZ Data Repository, ensuring full transparency and reproducibility of the results:

**Raw Data Repository**: https://doi.org/10.48758/ufz.15515

You can manually download the input.zip archive directly from the UFZ Data Repository link provided above, extract its contents, and place the unzipped files into the `input/` directory within your project structure.

**Required Input Files**:
- `input/env_2025-01-21.csv` - Environmental parameter data
- `input/formulas.clean_2025-01-21.csv` - Molecular formula data from FT-ICR MS
- `input/eval.summary.clean_2025-01-21.csv` - Evaluation summary data
- `input/Repository_file_definition_2022_03_20.csv` - Repository file definitions and metadata

#### 3. Automated Environment Setup

For a quick and automated setup of both R and Python environments, you can use the provided setup script.

##### Option 1: Using run_all.sh (Recommended)
```bash
# Make the script executable
chmod +x run_all.sh

# Run the complete pipeline
./run_all.sh
```

The `run_all.sh` script provides a comprehensive, automated solution that:
- ✅ Performs pre-flight checks for R and Python installations
- ✅ Automatically installs all required R packages using `install_r_packages.R`
- ✅ Automatically creates Python virtual environment (`venv/`)
- ✅ Automatically installs all required Python packages from `requirements.txt`
- ✅ Creates necessary output directories
- ✅ Checks for required input data files
- ✅ Runs all analysis scripts in the correct sequence
- ✅ Provides detailed progress feedback with colored output
- ✅ Generates comprehensive execution logs
- ✅ Creates a completion summary with results overview
- ✅ Handles errors gracefully with detailed error reporting

##### Option 2: Manual Setup (Not Recommended)
```bash
# Install R packages
Rscript install_r_packages.R

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python packages
pip install -r requirements.txt
```

**Note**: The `run_all.sh` script automatically handles both R and Python package installation, so manual setup is typically not needed.

#### 4. Run the Analysis Pipeline

The R scripts generate intermediate processed data files in the `processed/` directory, which are then used by subsequent R scripts and the Python script. It's crucial to run them in the following order:

##### 4.1 Run R Scripts (in order)
```bash
Rscript "scripts/1. mf.R"
Rscript "scripts/2. env.R"
Rscript "scripts/3. wa.R"
Rscript "scripts/4. pca.R"
Rscript "scripts/5. corr.R"
```

This will populate the `processed/` directory with cleaned data and generate plots in the `output/` subdirectories (`output/env`, `output/wa`, `output/mf`, `output/pca`, `output/corr`).

##### 4.2 Run Python Script

After all R scripts have successfully run and `processed/rho_MF.csv` has been generated by `5. corr.R`, you can run the Python machine learning script:

```bash
python "scripts/6. MRF.py"
```

This will generate additional plots and results in the `output/MRF` and `processed/MRF` directories.

## 📋 Output Logs and Execution Tracking

The DOM-Drivers pipeline provides comprehensive logging and execution tracking to ensure reproducibility and facilitate debugging. When using `run_all.sh`, detailed logs are automatically generated for each script execution.

### Log File Structure

All execution logs are stored in the `output/logs/` directory with the following naming convention:
```
output/logs/
├── mf_YYYYMMDD_HHMMSS.log           # Molecular formula processing log
├── env_YYYYMMDD_HHMMSS.log          # Environmental parameter processing log
├── wa_YYYYMMDD_HHMMSS.log           # Weighted average calculations log
├── pca_YYYYMMDD_HHMMSS.log          # Principal Component Analysis log
├── corr_YYYYMMDD_HHMMSS.log         # Correlation analysis log
├── MRF_YYYYMMDD_HHMMSS.log          # Machine Learning Random Forest log
└── analysis_completion_summary.txt  # Overall pipeline completion summary
```

### Log File Contents

Each individual log file contains:

1. **Header Information**:
   - Script name and description
   - Execution start time
   - Author and publication information
   - Pipeline version details

2. **Complete Script Output**:
   - All console output from R/Python scripts
   - Error messages and warnings
   - Progress indicators and status updates
   - Package loading confirmations

3. **Execution Summary**:
   - Success/failure status
   - End time and execution duration
   - Exit codes for error diagnosis

### Completion Summary

The `analysis_completion_summary.txt` file provides a high-level overview of the entire pipeline execution:

- ✅ **Execution Status**: Success/failure status for each script
- 📁 **Output Files**: Count and location of generated files
- 📊 **Key Results**: Summary of analysis outputs
- 🔍 **Log Locations**: Paths to detailed execution logs
- 📋 **Next Steps**: Guidance for interpreting results

### Monitoring Pipeline Progress

When running `run_all.sh`, you'll see real-time progress updates:

```bash
[INFO] Running env.R...
[INFO] Description: Environmental parameter data import and preprocessing
[INFO] Log file: output/logs/env_20250121_143022.log
[SUCCESS] env.R completed successfully
[SUCCESS] Log saved to: output/logs/env_20250121_143022.log
```

### Log Analysis and Troubleshooting

#### Checking Script Success
```bash
# View the completion summary
cat output/analysis_completion_summary.txt

# Check if a specific script completed successfully
grep "SCRIPT EXECUTION COMPLETED SUCCESSFULLY" output/logs/env_*.log
```

#### Debugging Failed Scripts
```bash
# View the most recent log for a failed script
ls -t output/logs/env_*.log | head -1 | xargs cat

# Search for error messages in logs
grep -i "error" output/logs/*.log

# Check for missing packages
grep -i "package.*not found" output/logs/*.log
```

#### Performance Monitoring
```bash
# Check execution times
grep "Total execution time" output/analysis_completion_summary.txt

# View detailed timing in individual logs
grep -A5 -B5 "Start Time\|End Time" output/logs/*.log
```

### Log Retention and Management

- **Automatic Timestamping**: Each log file includes a timestamp to prevent overwrites
- **Complete History**: All execution attempts are preserved for debugging
- **Storage Efficiency**: Logs are text-based and typically small (< 1MB each)
- **Easy Cleanup**: Remove old logs with: `rm output/logs/*.log`

### Integration with Publication Workflow

The logging system supports reproducible research by:
- **Documenting Exact Execution**: Timestamps and environment details
- **Enabling Replication**: Complete command history and outputs
- **Facilitating Peer Review**: Transparent execution logs for validation
- **Supporting Methodological Documentation**: Detailed processing steps

## 📚 Dependencies

This project relies on the following R and Python libraries:

Reproducibility:
- R packages are installed from a pinned Posit Package Manager CRAN snapshot (2025-01-21), ensuring consistent versions across machines.
- Python packages are pinned via `requirements.txt` and the provided `venv/`, ensuring consistent versions.

### 📊 R Libraries
| Library        | Version | Description                                       |
| :------------- | :------ | :------------------------------------------------ |
| tidyverse      | 2.0.0   | Collection of core tidyverse packages (dplyr, tidyr, ggplot2, readr, purrr, forcats, stringr, tibble) |
| data.table     | 1.17.8  | Enhanced data frames for efficient large data operations |
| FactoMineR     | 2.12    | Multivariate exploratory data analysis            |
| factoextra     | 1.0.7   | Visualization of multivariate analysis results    |
| corrr          | 0.4.4   | Tidy correlation analysis                         |
| RColorBrewer   | 1.1-3   | Color palettes for attractive plots               |


### 🐍 Python Libraries
| Library        | Version | Description                                       |
| :------------- | :------ | :------------------------------------------------ |
| pandas         | 2.3.2   | Data manipulation and analysis                    |
| numpy          | 2.2.6   | Numerical computing                               |
| matplotlib     | 3.10.6  | Static plotting                                   |
| scikit-learn   | 1.7.2   | Machine learning algorithms                       |
| plotly         | 6.3.0   | Interactive graphing library                      |
| shap           | 0.48.0  | SHapley Additive exPlanations (model interpretability) |
 

## 📁 Output Structure

```
output/
├── env/                           # Environmental parameter processing results
│   ├── Correlation_map_env.pdf
│   ├── Density_distributions_env.pdf
│   └── Normality_env.pdf
├── wa/                            # Weighted average calculations
│   ├── Correlation_map_wa.pdf
│   ├── Density_distributions_wa.pdf
│   └── Normality_WA.pdf
├── mf/                            # Molecular formula processing results
│   ├── Correlation_map_mf.pdf
│   ├── Density_distributions_mf.pdf
│   └── Normality_mf.pdf
├── pca/                           # Principal Component Analysis results
│   ├── PCA_para.pdf
│   ├── PCA_wa.pdf
│   ├── scree_para.pdf
│   └── scree_wa.pdf
├── corr/                          # Correlation analysis results
│   ├── Correlation_network_EnvParams.pdf
│   ├── Correlation_network_MF_Props.pdf
│   ├── Heatmap_EnvParam_Correlation.pdf
│   ├── Heatmap_MF_Props_Correlation.pdf
│   ├── Prevalent_MF_barplot.pdf
│   ├── spearman_rho_boxplot.pdf
│   ├── distribution/              # Spearman rho distribution plots
│   │   ├── distribution_rho_AAP.pdf
│   │   ├── distribution_rho_AAT.pdf
│   │   ├── distribution_rho_Alcalinity.pdf
│   │   ├── distribution_rho_Ca.pdf
│   │   ├── distribution_rho_Cl.pdf
│   │   ├── distribution_rho_Coverage.pdf
│   │   ├── distribution_rho_E2_E3.pdf
│   │   ├── distribution_rho_EC.pdf
│   │   ├── distribution_rho_F.pdf
│   │   ├── distribution_rho_K.pdf
│   │   ├── distribution_rho_Mg.pdf
│   │   ├── distribution_rho_Na.pdf
│   │   ├── distribution_rho_NO3.pdf
│   │   ├── distribution_rho_pH.pdf
│   │   ├── distribution_rho_Slope.pdf
│   │   ├── distribution_rho_SO2.pdf
│   │   ├── distribution_rho_SR.pdf
│   │   ├── distribution_rho_SUV.pdf
│   │   └── distribution_rho_TOC.pdf
│   └── vKs/                       # Van Krevelen diagrams colored by correlation
│       ├── vK_AAP_rho_colored.pdf
│       ├── vK_AAT_rho_colored.pdf
│       ├── vK_Alcalinity_rho_colored.pdf
│       ├── vK_Ca_rho_colored.pdf
│       ├── vK_Cl_rho_colored.pdf
│       ├── vK_Coverage_rho_colored.pdf
│       ├── vK_E2_E3_rho_colored.pdf
│       ├── vK_EC_rho_colored.pdf
│       ├── vK_F_rho_colored.pdf
│       ├── vK_K_rho_colored.pdf
│       ├── vK_Mg_rho_colored.pdf
│       ├── vK_Na_rho_colored.pdf
│       ├── vK_NO3_rho_colored.pdf
│       ├── vK_pH_rho_colored.pdf
│       ├── vK_Slope_rho_colored.pdf
│       ├── vK_SO2_rho_colored.pdf
│       ├── vK_SR_rho_colored.pdf
│       ├── vK_SUV_rho_colored.pdf
│       └── vK_TOC_rho_colored.pdf
└── MRF/                           # Machine Learning Random Forest results
    ├── Feature_importance.pdf
    ├── box_plot.html
    ├── histogram_plot.html
    └── beeswarm/                  # SHAP beeswarm plots
        ├── rho(AAP)_beeswarm_plot.pdf
        ├── rho(AAT)_beeswarm_plot.pdf
        ├── rho(Alcalinity)_beeswarm_plot.pdf
        ├── rho(Ca)_beeswarm_plot.pdf
        ├── rho(Cl)_beeswarm_plot.pdf
        ├── rho(Coverage)_beeswarm_plot.pdf
        ├── rho(E2_E3)_beeswarm_plot.pdf
        ├── rho(EC)_beeswarm_plot.pdf
        ├── rho(F)_beeswarm_plot.pdf
        ├── rho(K)_beeswarm_plot.pdf
        ├── rho(Mg)_beeswarm_plot.pdf
        ├── rho(Na)_beeswarm_plot.pdf
        ├── rho(NO3)_beeswarm_plot.pdf
        ├── rho(pH)_beeswarm_plot.pdf
        ├── rho(Slope)_beeswarm_plot.pdf
        ├── rho(SO2)_beeswarm_plot.pdf
        ├── rho(SR)_beeswarm_plot.pdf
        ├── rho(SUV)_beeswarm_plot.pdf
        └── rho(TOC)_beeswarm_plot.pdf

processed/
├── parameters_env_processed.csv   # Cleaned environmental data
├── wa_mean_processed.csv          # Weighted average data
├── mf_processed.csv               # Processed molecular formula data
├── rho_MF.csv                     # Correlation matrix
├── pca/                           # PCA results
│   ├── loadings_para.csv
│   └── loadings_wa.csv
└── MRF/                           # ML model outputs
    └── CV_results.csv             # Cross-validation results
```

## 🔧 Troubleshooting

### Common Issues with run_all.sh

#### 1. Permission Denied Error
```bash
# Error: Permission denied: ./run_all.sh
# Solution: Make the script executable
chmod +x run_all.sh
```

#### 2. Missing Input Files
```bash
# Error: Missing DOM-Drivers input files
# Solution: Download and place required files in input/ directory
# Required files:
# - input/env_2025-01-21.csv
# - input/formulas.clean_2025-01-21.csv  
# - input/eval.summary.clean_2025-01-21.csv
```

#### 3. R/Python Not Found
```bash
# Error: Rscript is not installed or not in PATH
# Solution: Install R from https://www.r-project.org/

# Error: Python3 is not installed or not in PATH
# Solution: Install Python 3.8+ from https://www.python.org/
```

#### 4. Missing R Packages
```bash
# Error: Missing R packages
# Solution: The run_all.sh script automatically handles this, but if you need manual installation:

# Install missing packages using the provided script
Rscript install_r_packages.R

# Or install manually:
Rscript -e "install.packages(c('tidyverse', 'FactoMineR', 'factoextra', 'corrr', 'data.table', 'RColorBrewer', 'patchwork', 'MASS', 'ggpubr', 'ggsci', 'htmltools', 'scales'), repos='https://cran.rstudio.com/')"
```

#### 5. Missing Python Packages
```bash
# Error: Missing Python packages (especially scikit-learn, xgboost)
# Solution: The run_all.sh script automatically handles this with improved installation methods

# If automatic installation fails, try manual installation:

# Activate virtual environment (created by run_all.sh)
source venv/bin/activate

# Upgrade build tools first
pip install --upgrade pip setuptools wheel

# Install packages with pre-compiled wheels (recommended for scikit-learn/xgboost)
pip install --only-binary=all scikit-learn xgboost

# Install remaining packages
pip install -r requirements.txt

# Or install individually with no cache:
pip install pandas numpy matplotlib plotly shap scipy --no-cache-dir
```

#### 6. Script Execution Failures
```bash
# Check the specific log file for detailed error information
ls -t output/logs/*.log | head -1 | xargs cat

# Look for specific error patterns
grep -i "error" output/logs/*.log
grep -i "failed" output/logs/*.log
```

#### 7. Memory Issues
```bash
# For large datasets, you may need to increase memory limits
# In R, before running scripts:
Rscript -e "memory.limit(size = 16000)"  # Windows
# Or set environment variable:
export R_MAX_MEM_SIZE=16G  # Linux/macOS
```

#### 8. Partial Pipeline Execution
```bash
# If some scripts fail, you can run individual scripts:
Rscript "scripts/1. mf.R"
Rscript "scripts/2. env.R"
Rscript "scripts/3. wa.R"
Rscript "scripts/4. pca.R"
Rscript "scripts/5. corr.R"
python "scripts/6. MRF.py"

# Check which scripts completed successfully:
cat output/analysis_completion_summary.txt
```

### Getting Help

1. **Check Logs First**: Always examine the log files in `output/logs/` for detailed error information
2. **Review Completion Summary**: Check `output/analysis_completion_summary.txt` for overall status
3. **Verify Dependencies**: Ensure all required packages are installed
4. **Check System Requirements**: Verify R 4.0+ and Python 3.8+ are installed
5. **Consult Documentation**: Review the Water Research publication for methodological guidance

### Performance Optimization

For large datasets or slower systems:

```bash
# Run with increased verbosity for debugging
Rscript --verbose "scripts/2. env.R"

# Monitor system resources during execution
top -p $(pgrep -f "Rscript\|python")

# Use parallel processing where available
export R_PARALLEL=4  # Adjust based on CPU cores
```

## 🔬 Scientific Context

This pipeline was developed to support research on **environmental drivers of dissolved organic matter composition** in Central European aquatic systems. The analysis framework enables:

- **Comprehensive DOM Characterization**: Through molecular formula analysis and descriptor calculation
- **Environmental Correlation Analysis**: Identifying key drivers of DOM composition
- **Predictive Modeling**: Using machine learning to understand DOM-environment relationships
- **Interpretable Results**: Through SHAP analysis and feature importance ranking

## 📖 Citation

If you use this pipeline in your research, please cite:

```
Gad, M., Tayyebi Sabet Khomami, N., Krieg, R., Schor, J., Philippe, A., & Lechtenfeld, O. J. (2024). 
Environmental drivers of dissolved organic matter composition across central European aquatic systems: 
A novel correlation-based machine learning and FT-ICR MS approach. Water Research, 123018.
DOI: 10.1016/j.watres.2024.123018
```

## 🤝 Contributing

Contributions are welcome to improve this pipeline. Please feel free to:

1. Report bugs or issues
2. Suggest new features
3. Submit pull requests with improvements
4. Share your analysis results and insights

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Michel Gad** - Corresponding Author
- **Narjes Tayyebi Sabet Khomami** - Co-author
- **Ronald Krieg** - Co-author
- **Jana Schor** - Co-author
- **Allan Philippe** - Co-author
- **Oliver J. Lechtenfeld** - Senior Author

## 📞 Contact

For questions about this pipeline or the associated research, please contact me:

- **Michel Gad**: michel.gad@outlook.com

---

