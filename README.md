# Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (**DOM-Drivers**)

## 🎯 Introduction

This directory contains a complete data analysis pipeline used in the associated Water Research publication (DOI: https://doi.org/10.1016/j.watres.2024.123018). The pipeline processes molecular formula data, performs comparative analyses, creates publication-ready visualizations, and exports comprehensive results.

The pipeline is implemented in R and Python and includes raw data import and preprocessing, statistical analysis, dimensionality reduction (PCA), correlation assessment, and interpretable machine learning modeling. It is the exact computational workflow used to generate the results and figures reported in the paper.

## 🔄 DataLad Integration for Reproducibility

This project leverages **DataLad** for comprehensive data management and computational reproducibility. The project uses a **nested dataset structure** where the `input/` directory is a separate DataLad dataset. DataLad provides:

- **🔄 Complete Provenance Tracking**: Every input file, output file, and computational step is automatically tracked
- **📊 Data Versioning**: All data files are version-controlled with git-annex, enabling easy access to specific data versions
- **🔗 Dependency Management**: Automatic detection and tracking of input-output relationships between analysis steps
- **🐍 Python Virtual Environment**: Isolated Python environment with all required packages for consistent execution
- **📈 Reproducible Execution**: Use `datalad rerun` to replay any analysis step with identical results
- **🌐 Data Distribution**: Data is accessible via multiple sources (Google Drive, UFZ Data Repository) with automatic retrieval
- **🤝 Collaboration**: Easy sharing of complete analysis workflows including data, code, and execution history
- **📁 Nested Dataset Structure**: The `input/` directory is a separate DataLad dataset that can be cloned and managed independently

The entire analysis pipeline can be reproduced on any system with DataLad installed, ensuring that the scientific results are fully verifiable and reproducible.

## 📁 Nested Dataset Structure

This project uses a **nested DataLad dataset structure** for optimal data management:

- **Main Dataset**: Contains code, scripts, and analysis pipeline
- **Input Dataset**: The `input/` directory is a separate DataLad dataset with Google Drive integration
- **Large Files**: Input data files (>100MB) are stored on Google Drive and retrieved as needed
- **Git-annex Integration**: Efficient large file management with automatic retrieval
- **Independent Management**: The input dataset can be cloned and managed separately

**Dataset Structure:**
```
DOM-Drivers/                    # Main dataset
├── input/                      # Nested dataset (Google Drive integrated)
│   ├── .datalad/              # DataLad configuration
│   ├── env_2025-01-21.csv     # Environmental data
│   ├── formulas.clean_2025-01-21.csv  # Molecular formula data
│   └── ...                     # Other input files
├── scripts/                    # Analysis scripts
├── output/                     # Analysis results
└── processed/                  # Intermediate data
```

## 🌐 Google Drive Data Access

The input data files are stored on Google Drive and can be accessed using rclone. The data is available at:
**Google Drive Folder**: https://drive.google.com/drive/folders/1g-l6JclTWdDfgvewtokYzux-U9GnUXDD?usp=sharing

### Prerequisites for Data Access

1. **Install rclone**: 
   ```bash
   # macOS
   brew install rclone
   
   # Linux
   curl https://rclone.org/install.sh | sudo bash
   ```

2. **Configure rclone for Google Drive**:
   ```bash
   rclone config
   # Follow the prompts to set up Google Drive access
   # Name your remote (e.g., "mygdrive")
   ```

### Quick Data Setup

**Option 1: Automated Setup (Recommended)**
```bash
# Run the complete analysis pipeline with automatic data download
./run_analysis_datalad.sh
```

**Option 2: Manual Data Download**
```bash
# Download data files from Google Drive
rclone copy mygdrive:git-annex-rclone/MD5E-s319430610--f1a5758478cd90525d317bcf8446f7a3.csv input/formulas.clean_2025-01-21.csv
rclone copy mygdrive:git-annex-rclone/MD5E-s86392--c6fd7208939b9488303faefc673c776c.csv input/env_2025-01-21.csv
rclone copy mygdrive:git-annex-rclone/MD5E-s8831--5f2a2cc18d2915b1208ee764f4a1da59.csv input/eval.summary.clean_2025-01-21.csv
rclone copy mygdrive:git-annex-rclone/MD5E-s5868--b1ca17b55e079055c703e51c02ed39e2.csv input/Repository_file_definition_2022_03_20.csv

# Verify data is available
ls -la input/
```

### Data File Mapping

The Google Drive files are stored with git-annex naming convention. Here's the mapping:

| Google Drive File | Expected Name | Description | Size |
|------------------|---------------|-------------|------|
| `MD5E-s319430610--f1a5758478cd90525d317bcf8446f7a3.csv` | `formulas.clean_2025-01-21.csv` | Molecular formulas (FT-ICR MS data) | 304.6 MB |
| `MD5E-s86392--c6fd7208939b9488303faefc673c776c.csv` | `env_2025-01-21.csv` | Environmental parameters | 84 KB |
| `MD5E-s8831--5f2a2cc18d2915b1208ee764f4a1da59.csv` | `eval.summary.clean_2025-01-21.csv` | Evaluation summary | 9 KB |
| `MD5E-s5868--b1ca17b55e079055c703e51c02ed39e2.csv` | `Repository_file_definition_2022_03_20.csv` | Repository definitions | 6 KB |

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

## 🐍 Python Virtual Environment Setup (Recommended)

For the easiest and most reproducible setup, we recommend using a Python virtual environment:

### Quick Start
```bash
# 1. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Get the data (from Google Drive via DataLad)
datalad get input/

# 4. Make the analysis script executable
chmod +x run_analysis_datalad.sh

# 5. Run the complete analysis
./run_analysis_datalad.sh
```

### Virtual Environment Features
- ✅ **Isolated Environment**: Python with all required packages
- ✅ **Reproducible Results**: Consistent across different systems
- ✅ **Easy Setup**: Simple virtual environment creation
- ✅ **Interactive Development**: Jupyter notebook support
- ✅ **Resource Management**: Automatic memory and CPU limits

For detailed setup instructions, see the sections below.

## 📦 Installing DataLad

DataLad is a data management tool, so we advise you to install it wherever you would be working with actual data. This may not be your laptop, but a server that you connect to with your laptop. In that case, please consider installing DataLad on that server. Installation on such systems does not require administrator privileges and works with regular user accounts.

### Step 1: DataLad needs Git

Many systems have Git already installed. Try running `git --version` in a terminal to check.

If you do not have Git installed, visit https://git-scm.com/downloads, pick your operating system, download, and run the Git installer.

If you are using Conda, Brew, or a system with another package manager, there are simpler ways to install Git, and you likely know how.

### Step 2: Install UV

UV is a smart little helper that is available for all platforms and offers the simplest way to install DataLad. DataLad is written in Python and UV takes care of automatically creating the right environment for DataLad to run, whether or not you know or have Python already.

Visit https://docs.astral.sh/uv/getting-started/installation/#standalone-installer and run the standalone installer. Experts can also use any other method listed on that page.

### Step 3: Install git-annex

With UV installed, you can now install the git-annex software, a core tool that DataLad builds upon. Run:

```bash
uv tool install git-annex
```

Afterwards run:

```bash
git annex version
```

to verify that you have a functional installation.

### Step 4: Install DataLad

DataLad is installed exactly like git-annex. However, we also install a particular DataLad extension package, like so:

```bash
uv tool install datalad --with-executables-from datalad-next
git config --global --add datalad.extensions.load next
```

Verify the installation by running:

```bash
datalad wtf
```

(it should report all kinds of information on your system).

## 📊 Data Requirements

The raw data used in this project is available through multiple sources, ensuring full transparency and reproducibility of the results:

### 🗂️ Data Sources

**Primary Source - UFZ Data Repository**: https://doi.org/10.48758/ufz.15515
- Download the input.zip archive from the UFZ Data Repository link above
- Extract its contents and place the unzipped files into the `input/` directory

**Alternative Source - Google Drive (via DataLad)**:
- The data is stored in a nested DataLad dataset with Google Drive integration
- The `input/` directory is a separate DataLad dataset that can be cloned independently
- Use DataLad to automatically retrieve the data:

```bash
# Get all input data from Google Drive (nested dataset)
datalad get input/

# Or get specific files from the nested dataset
datalad get input/env_2025-01-21.csv
datalad get input/formulas.clean_2025-01-21.csv
datalad get input/eval.summary.clean_2025-01-21.csv
datalad get input/Repository_file_definition_2022_03_20.csv
```

### 📁 Required Input Files

- `input/env_2025-01-21.csv` - Environmental parameter data
- `input/formulas.clean_2025-01-21.csv` - Molecular formula data from FT-ICR MS
- `input/eval.summary.clean_2025-01-21.csv` - Evaluation summary data
- `input/Repository_file_definition_2022_03_20.csv` - Repository file definitions and metadata

## 🔄 Analysis Pipeline

The analysis follows a specific sequence where R scripts generate intermediate processed data files in the `processed/` directory, which are then used by subsequent scripts. The virtual environment setup automatically runs all scripts in the correct order:

1. **Data Preprocessing** (`1. mf.R`, `2. env.R`, `3. wa.R`)
2. **Dimensionality Reduction** (`4. pca.R`)
3. **Correlation Analysis** (`5. corr.R`)
4. **Machine Learning** (`6. MRF.py`)

Results are automatically saved to the `output/` directory with organized subdirectories for each analysis step.

## 🔄 Complete Workflow (DataLad + Virtual Environment)

For the most reproducible and complete workflow, use DataLad to manage data and track analysis execution:

### Option 1: DataLad Run (Recommended for Reproducibility)

#### Automated Pipeline
```bash
# Clone the DataLad dataset
datalad clone <repository-url>
cd DOM-Drivers

# Get all required data from Google Drive
datalad get input/

# Run complete analysis with full provenance tracking
./run_analysis_datalad.sh
```

#### Individual Scripts
```bash
# Run each script individually with datalad run
datalad run --explicit --input "input/formulas.clean_2025-01-21.csv" --input "input/eval.summary.clean_2025-01-21.csv" --output "processed/mf_processed.csv" --output "output/mf/" -m "Process molecular formula data" "Rscript scripts/1.\ mf.R"

datalad run --explicit --input "input/env_2025-01-21.csv" --output "processed/parameters_env_processed.csv" --output "output/env/" -m "Process environmental parameters" "Rscript scripts/2.\ env.R"

# ... continue with remaining scripts
```

### Option 2: Virtual Environment + DataLad

#### Setup and Run
```bash
# Clone the DataLad dataset
datalad clone https://codeberg.org/MichelGad/DOM-Drivers.git
cd DOM-Drivers

# Get all required data from Google Drive
datalad get input/

# Activate virtual environment and run analysis
source venv/bin/activate  # On Windows: venv\Scripts\activate
chmod +x run_analysis_datalad.sh
./run_analysis_datalad.sh
```

#### Save Results
```bash
# Save analysis results to the dataset
datalad save -m "Complete DOM analysis results" output/ processed/
```

### 3. Share Results
```bash
# Push results to remote repository
datalad push --to origin

# Or push data to Google Drive
datalad push --to mygoogledrive
```

## 🔬 Reproducibility Features

### DataLad Run Benefits
- **Complete Provenance**: Every input and output is tracked
- **Reproducible Execution**: `datalad rerun` can replay any analysis step
- **Dependency Management**: Automatic detection of required inputs
- **Version Control**: All intermediate files are tracked in git
- **Collaboration**: Easy sharing of complete analysis workflows

### Verification Commands
```bash
# Check what files were created/modified by a specific run
datalad diff --from HEAD~1

# Rerun a specific analysis step
datalad rerun <commit-hash>

# Check the provenance of a specific file
datalad what-rev <file-path>

# View complete run history
git log --oneline
```

### Individual Script Commands
For detailed individual script commands, see [datalad_run_commands.md](datalad_run_commands.md).

## 📋 Output Logs and Execution Tracking

The DOM-Drivers pipeline provides comprehensive logging and execution tracking to ensure reproducibility and facilitate debugging. When using the virtual environment, detailed logs are automatically generated for each script execution.

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

This project uses a Python virtual environment to provide a complete, reproducible environment with all required Python libraries pre-installed.

### 🐍 Virtual Environment

The virtual environment includes:

**System Requirements:**
- Python 3.8+ with all required packages
- Isolated package management
- Cross-platform compatibility
- Memory efficient execution
**Python Libraries (automatically installed):**
- pandas, numpy, matplotlib, plotly, scikit-learn, xgboost, shap, scipy
- All packages pinned to specific versions for reproducibility

### 🔧 Manual Installation (Not Recommended)

If you prefer to run without the virtual environment, you would need to manually install:

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

### Common Virtual Environment Issues

#### 1. Virtual Environment Not Activated
```bash
# Error: Python packages not found
# Solution: Activate the virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

#### 2. Permission Denied Error
```bash
# Error: Permission denied: ./run_analysis_datalad.sh
# Solution: Make the script executable
chmod +x run_analysis_datalad.sh
```

#### 3. Missing Input Files
```bash
# Error: Missing DOM-Drivers input files
# Solution: Get data using DataLad (nested dataset)
datalad get input/

# If nested dataset is not properly configured:
# Check if input/.datalad exists
ls -la input/.datalad

# If missing, the input dataset needs to be properly set up
# The input/ directory should be a separate DataLad dataset

# Or download manually from UFZ Data Repository
# https://doi.org/10.48758/ufz.15515
# Required files:
# - input/env_2025-01-21.csv
# - input/formulas.clean_2025-01-21.csv  
# - input/eval.summary.clean_2025-01-21.csv
```

#### 4. Package Installation Failures
```bash
# Error: Package installation failed
# Solution: Reinstall packages in virtual environment
pip install --upgrade pip
pip install -r requirements.txt

# Or recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 5. Memory Issues
```bash
# Error: Out of memory during analysis
# Solution: Check available memory and optimize data processing
# The scripts automatically sample large datasets for visualization
```

#### 6. Interactive Debugging
```bash
# Activate virtual environment for debugging
source venv/bin/activate

# Check installed packages
python3 --version
pip list

# Run individual scripts for debugging
python3 scripts/6.\ MRF.py
```

#### 7. View Analysis Logs
```bash
# Check analysis logs
ls -la output/logs/

# View specific log files
cat output/logs/script_1_mf.log
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

