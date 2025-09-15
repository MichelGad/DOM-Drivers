#!/bin/bash

# =============================================================================
# Script: run_all.sh
# Purpose: Execute the complete Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) pipeline
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Run all DOM-Drivers analysis scripts in the correct sequence
#   - Provide progress feedback and error handling
#   - Create comprehensive analysis results for DOM-environment correlation study
#   - Support reproduction of Water Research publication findings
#   - Save detailed logs for each script execution
# =============================================================================

# Set script options
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if R is available
check_r() {
    if ! command -v Rscript &> /dev/null; then
        print_error "Rscript is not installed or not in PATH"
        print_error "Please install R and ensure Rscript is available"
        exit 1
    fi
    print_success "Rscript found: $(which Rscript)"
}

# Function to check if Python is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed or not in PATH"
        print_error "Please install Python 3.8 or higher"
        exit 1
    fi
    print_success "Python3 found: $(which python3)"
}

# Function to install R packages
install_r_packages() {
    print_status "Installing R packages..."
    
    if [ -f "install_r_packages.R" ]; then
        print_status "Running R package installation script..."
        if Rscript install_r_packages.R; then
            print_success "R packages installed successfully"
        else
            print_error "Failed to install R packages using install_r_packages.R"
            print_error "Trying manual package installation..."
            
            # Fallback: install packages manually
            packages=("tidyverse" "FactoMineR" "factoextra" "corrr" "data.table" "RColorBrewer" 
                      "patchwork" "MASS" "ggpubr" "ggsci" "htmltools" "scales")
            
            for package in "${packages[@]}"; do
                print_status "Installing R package: $package"
                if Rscript -e "install.packages('$package', repos='https://cran.rstudio.com/', dependencies=TRUE)" > /dev/null 2>&1; then
                    print_success "$package installed successfully"
                else
                    print_error "Failed to install $package"
                fi
            done
        fi
    else
        print_error "install_r_packages.R not found"
        exit 1
    fi
}

# Function to check if required R packages are installed
check_r_packages() {
    print_status "Checking required R packages..."
    
    # List of required packages for DOM-Drivers
    packages=("tidyverse" "FactoMineR" "factoextra" "corrr" "data.table" "RColorBrewer" 
              "patchwork" "MASS" "ggpubr" "ggsci" "htmltools" "scales")
    
    missing_packages=()
    
    for package in "${packages[@]}"; do
        if ! Rscript -e "library($package)" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        print_success "All required R packages are installed"
    else
        print_warning "Missing R packages: ${missing_packages[*]}"
        print_status "Installing missing R packages..."
        install_r_packages
        
        # Re-check after installation
        missing_packages=()
        for package in "${packages[@]}"; do
            if ! Rscript -e "library($package)" &> /dev/null; then
                missing_packages+=("$package")
            fi
        done
        
        if [ ${#missing_packages[@]} -eq 0 ]; then
            print_success "All required R packages are now installed"
        else
            print_error "Still missing R packages: ${missing_packages[*]}"
            print_error "Please check your R installation and internet connection"
            exit 1
        fi
    fi
}

# Function to create Python virtual environment
create_python_environment() {
    print_status "Setting up Python virtual environment..."
    
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        if python3 -m venv venv; then
            print_success "Python virtual environment created successfully"
        else
            print_error "Failed to create Python virtual environment"
            exit 1
        fi
    else
        print_success "Python virtual environment already exists"
    fi
    
    # Activate virtual environment
    print_status "Activating Python virtual environment..."
    source venv/bin/activate
    
    # Upgrade pip and essential build tools
    print_status "Upgrading pip and build tools..."
    pip install --upgrade pip setuptools wheel > /dev/null 2>&1
}

# Function to install Python packages
install_python_packages() {
    print_status "Installing Python packages..."
    
    # Ensure virtual environment is activated
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source venv/bin/activate
    fi
    
    if [ -f "requirements.txt" ]; then
        print_status "Installing packages from requirements.txt..."
        
        # First try with verbose output to see any errors
        if pip install -r requirements.txt; then
            print_success "Python packages installed successfully"
        else
            print_warning "Bulk installation failed, trying individual package installation..."
            
            # Install packages individually with better error handling
            packages=("pandas" "numpy" "matplotlib" "scipy" "plotly" "shap" "scikit-learn" "xgboost")
            
            for package in "${packages[@]}"; do
                print_status "Installing $package..."
                
                # Special handling for packages that might need compilation
                case "$package" in
                    "scikit-learn")
                        print_status "Installing scikit-learn (this may take a few minutes)..."
                        if pip install scikit-learn --no-cache-dir; then
                            print_success "scikit-learn installed successfully"
                        else
                            print_warning "Failed to install scikit-learn, trying with pre-compiled wheel..."
                            pip install scikit-learn --only-binary=all || print_error "Failed to install scikit-learn"
                        fi
                        ;;
                    "xgboost")
                        print_status "Installing xgboost (this may take a few minutes)..."
                        if pip install xgboost --no-cache-dir; then
                            print_success "xgboost installed successfully"
                        else
                            print_warning "Failed to install xgboost, trying with pre-compiled wheel..."
                            pip install xgboost --only-binary=all || print_error "Failed to install xgboost"
                        fi
                        ;;
                    *)
                        if pip install "$package" --no-cache-dir; then
                            print_success "$package installed successfully"
                        else
                            print_error "Failed to install $package"
                        fi
                        ;;
                esac
            done
        fi
    else
        print_error "requirements.txt not found"
        exit 1
    fi
}

# Function to check if required Python packages are installed
check_python_packages() {
    print_status "Checking Python environment..."
    
    # Ensure virtual environment is activated
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source venv/bin/activate
    fi
    
    # Verify we're using the virtual environment's Python
    python_path=$(which python)
    print_status "Using Python from: $python_path"
    print_status "Virtual environment: $VIRTUAL_ENV"
    
    # Simple Python test to verify Python is working
    print_status "Testing basic Python functionality..."
    if python -c "print('Python is working')" 2>/dev/null; then
        print_success "Python is working correctly"
    else
        print_error "Python is not working correctly"
        return 1
    fi
    
    # Check if packages are installed via pip (faster than import testing)
    print_status "Checking installed packages via pip..."
    installed_packages=$(pip list --format=freeze 2>/dev/null | cut -d'=' -f1)
    
    required_packages=("pandas" "numpy" "matplotlib" "scikit-learn" "xgboost" "plotly" "shap")
    missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if echo "$installed_packages" | grep -q "^$package$"; then
            print_status "✓ $package is installed"
        else
            print_warning "✗ $package is not installed"
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        print_success "All required Python packages are installed"
    else
        print_warning "Some packages may be missing: ${missing_packages[*]}"
        print_warning "Attempting to install missing packages..."
        install_python_packages
    fi
    
    print_status "Python package checking completed"
}

# Function to create output directories
create_directories() {
    print_status "Creating output directories..."
    
    directories=(
        "output"
        "output/env"
        "output/wa"
        "output/mf"
        "output/pca"
        "output/corr"
        "output/MRF"
        "output/MRF/models"
        "output/MRF/plots"
        "output/MRF/beeswarm"
        "output/MRF/results"
        "output/logs"
        "processed"
        "processed/MRF"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
    
    print_success "All output directories created"
}

# Function to check input files
check_input_files() {
    print_status "Checking for input data files..."
    
    # Check for DOM-Drivers-specific input files
    input_files=(
        "input/env_2025-01-21.csv"
        "input/formulas.clean_2025-01-21.csv"
        "input/eval.summary.clean_2025-01-21.csv"
    )
    
    found_files=()
    missing_files=()
    
    for file in "${input_files[@]}"; do
        if [ -f "$file" ]; then
            found_files+=("$file")
        else
            missing_files+=("$file")
        fi
    done
    
    if [ ${#found_files[@]} -gt 0 ]; then
        print_success "Found DOM-Drivers input files:"
        for file in "${found_files[@]}"; do
            echo "  - $file"
        done
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Missing DOM-Drivers input files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_warning "Download from: https://doi.org/10.48758/ufz.15515"
    fi
}

# Function to run R script with error handling and logging
run_r_script() {
    local script_name="$1"
    local description="$2"
    # Clean script name for log file (remove spaces and dots)
    local clean_name=$(echo "$script_name" | sed 's/[[:space:]]/_/g' | sed 's/\./_/g')
    local log_file="output/logs/${clean_name%.R}_$(date +%Y%m%d_%H%M%S).log"
    
    print_status "Running $script_name..."
    print_status "Description: $description"
    print_status "Log file: $log_file"
    
    if [ ! -f "scripts/$script_name" ]; then
        print_error "Script not found: scripts/$script_name"
        echo "ERROR: Script not found: scripts/$script_name" >> "$log_file"
        return 1
    fi
    
    # Create log file header
    cat > "$log_file" << EOF
=============================================================================
DOM-Drivers Pipeline Script Execution Log
=============================================================================
Script: $script_name
Description: $description
Start Time: $(date)
Author: Michel Gad
Pipeline: Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)
Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
=============================================================================

EOF

    # Run the script and capture all output to log file
    print_status "Executing script and logging output..."
    
    if Rscript "scripts/$script_name" >> "$log_file" 2>&1; then
        # Add success message to log
        echo "" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        echo "SCRIPT EXECUTION COMPLETED SUCCESSFULLY" >> "$log_file"
        echo "End Time: $(date)" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        
        print_success "$script_name completed successfully"
        print_success "Log saved to: $log_file"
        return 0
    else
        # Add error message to log
        echo "" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        echo "SCRIPT EXECUTION FAILED" >> "$log_file"
        echo "End Time: $(date)" >> "$log_file"
        echo "Exit Code: $?" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        
        print_error "$script_name failed"
        print_error "Check the log file: $log_file"
        return 1
    fi
}

# Function to run Python script with error handling and logging
run_python_script() {
    local script_name="$1"
    local description="$2"
    # Clean script name for log file (remove spaces and dots)
    local clean_name=$(echo "$script_name" | sed 's/[[:space:]]/_/g' | sed 's/\./_/g')
    local log_file="output/logs/${clean_name%.py}_$(date +%Y%m%d_%H%M%S).log"
    
    print_status "Running $script_name..."
    print_status "Description: $description"
    print_status "Log file: $log_file"
    
    if [ ! -f "scripts/$script_name" ]; then
        print_error "Script not found: scripts/$script_name"
        echo "ERROR: Script not found: scripts/$script_name" >> "$log_file"
        return 1
    fi
    
    # Create log file header
    cat > "$log_file" << EOF
=============================================================================
DOM-Drivers Pipeline Script Execution Log
=============================================================================
Script: $script_name
Description: $description
Start Time: $(date)
Author: Michel Gad
Pipeline: Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)
Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
=============================================================================

EOF

    # Ensure virtual environment is activated
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source venv/bin/activate
    fi

    # Run the script and capture all output to log file
    print_status "Executing script and logging output..."
    
    if python "scripts/$script_name" >> "$log_file" 2>&1; then
        # Add success message to log
        echo "" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        echo "SCRIPT EXECUTION COMPLETED SUCCESSFULLY" >> "$log_file"
        echo "End Time: $(date)" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        
        print_success "$script_name completed successfully"
        print_success "Log saved to: $log_file"
        return 0
    else
        # Add error message to log
        echo "" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        echo "SCRIPT EXECUTION FAILED" >> "$log_file"
        echo "End Time: $(date)" >> "$log_file"
        echo "Exit Code: $?" >> "$log_file"
        echo "=============================================================================" >> "$log_file"
        
        print_error "$script_name failed"
        print_error "Check the log file: $log_file"
        return 1
    fi
}

# Function to generate completion summary
generate_summary() {
    print_status "Generating completion summary..."
    
    summary_file="output/analysis_completion_summary.txt"
    
    cat > "$summary_file" << EOF
Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) PIPELINE - COMPLETION SUMMARY
=====================================================================

Analysis Date: $(date)
Pipeline Version: 1.0
Author: Michel Gad
Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018

EXECUTION SUMMARY:
==================

EOF

    # Check which DOM-Drivers scripts completed successfully
    scripts=("1. mf.R" "2. env.R" "3. wa.R" "4. pca.R" "5. corr.R" "6. MRF.py")
    
    for script in "${scripts[@]}"; do
        # Find the most recent log file for this script
        # Clean script name for log file matching (remove spaces and dots)
        clean_script_name=$(echo "$script" | sed 's/[[:space:]]/_/g' | sed 's/\./_/g')
        latest_log=$(ls -t output/logs/${clean_script_name%.*}_*.log 2>/dev/null | head -n1)
        if [ -n "$latest_log" ] && grep -q "SCRIPT EXECUTION COMPLETED SUCCESSFULLY" "$latest_log"; then
            echo "✓ $script - COMPLETED" >> "$summary_file"
            echo "  Log: $latest_log" >> "$summary_file"
        else
            echo "✗ $script - FAILED" >> "$summary_file"
            if [ -n "$latest_log" ]; then
                echo "  Log: $latest_log" >> "$summary_file"
            fi
        fi
    done
    
    echo "" >> "$summary_file"
    echo "OUTPUT FILES GENERATED:" >> "$summary_file"
    echo "=======================" >> "$summary_file"
    
    # Count output files
    if [ -d "output" ]; then
        find output -name "*.csv" -o -name "*.pdf" -o -name "*.txt" -o -name "*.md" | wc -l | xargs echo "Total files:" >> "$summary_file"
        echo "" >> "$summary_file"
        echo "Key output directories:" >> "$summary_file"
        echo "- output/env/: Environmental parameter processing results" >> "$summary_file"
        echo "- output/wa/: Weighted average molecular descriptor calculations" >> "$summary_file"
        echo "- output/mf/: Molecular formula processing and feature engineering" >> "$summary_file"
        echo "- output/pca/: Principal Component Analysis and dimensionality reduction" >> "$summary_file"
        echo "- output/corr/: Inter-data correlation analysis and Van Krevelen diagrams" >> "$summary_file"
        echo "- output/MRF/: Machine Learning Random Forest regression with SHAP" >> "$summary_file"
        echo "- output/logs/: Detailed execution logs for each script" >> "$summary_file"
        echo "- processed/: Intermediate data files for pipeline dependencies" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    echo "EXECUTION LOGS:" >> "$summary_file"
    echo "===============" >> "$summary_file"
    if [ -d "output/logs" ]; then
        echo "Detailed logs for each script execution:" >> "$summary_file"
        for log in output/logs/*.log; do
            if [ -f "$log" ]; then
                echo "- $(basename "$log")" >> "$summary_file"
            fi
        done
    fi
    
    echo "" >> "$summary_file"
    echo "NEXT STEPS:" >> "$summary_file"
    echo "===========" >> "$summary_file"
    echo "1. Review the generated plots in output/ directories" >> "$summary_file"
    echo "2. Check the processed data files for downstream analysis" >> "$summary_file"
    echo "3. Examine the DOM-environment correlation results and PCA plots" >> "$summary_file"
    echo "4. Review the Random Forest model performance and SHAP interpretability" >> "$summary_file"
    echo "5. Consult the Water Research publication for interpretation guidance" >> "$summary_file"
    echo "6. Check individual script logs in output/logs/ for detailed execution information" >> "$summary_file"
    
    print_success "Completion summary saved to: $summary_file"
}

# Main execution function
main() {
    echo "============================================================================="
    echo "Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers) PIPELINE"
    echo "============================================================================="
    echo "Author: Michel Gad"
    echo "Date: $(date)"
    echo "Version: 1.0"
    echo "Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018"
    echo "============================================================================="
    echo ""
    
    # Pre-flight checks
    print_status "Performing pre-flight checks..."
    check_r
    check_python
    check_r_packages
    
    # Python environment setup
    print_status "Setting up Python environment..."
    create_python_environment
    check_python_packages
    
    create_directories
    check_input_files
    
    echo ""
    print_status "All pre-flight checks completed successfully"
    print_status "Starting analysis pipeline..."
    echo ""
    
    # Track execution time
    start_time=$(date +%s)
    
    # Run DOM-Drivers scripts in sequence (correct order for data dependencies)
    scripts=(
        "1. mf.R:Molecular formula data processing and feature engineering"
        "2. env.R:Environmental parameter data import and preprocessing"
        "3. wa.R:Weighted average molecular descriptor calculations"
        "4. pca.R:Principal Component Analysis and dimensionality reduction"
        "5. corr.R:Inter-data correlation analysis and Van Krevelen diagrams"
        "6. MRF.py:Machine Learning Random Forest regression with SHAP interpretability"
    )
    
    print_status "Preparing to execute ${#scripts[@]} analysis scripts"
    failed_scripts=()
    
    for script_info in "${scripts[@]}"; do
        IFS=':' read -r script_name description <<< "$script_info"
        
        echo "-------------------------------------------------------------------------"
        print_status "Step: $description"
        print_status "Script: $script_name"
        print_status "Starting script execution loop iteration"
        echo "-------------------------------------------------------------------------"
        
        # Check if script file exists
        if [ ! -f "scripts/$script_name" ]; then
            print_error "Script file not found: scripts/$script_name"
            failed_scripts+=("$script_name")
            continue
        fi
        
        if [[ "$script_name" == *.py ]]; then
            if run_python_script "$script_name" "$description"; then
                print_success "$script_name completed successfully"
            else
                print_error "$script_name failed"
                failed_scripts+=("$script_name")
            fi
        else
            if run_r_script "$script_name" "$description"; then
                print_success "$script_name completed successfully"
            else
                print_error "$script_name failed"
                failed_scripts+=("$script_name")
            fi
        fi
        
        echo ""
    done
    
    # Calculate execution time
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    hours=$((execution_time / 3600))
    minutes=$(((execution_time % 3600) / 60))
    seconds=$((execution_time % 60))
    
    echo "============================================================================="
    echo "PIPELINE EXECUTION COMPLETE"
    echo "============================================================================="
    
    if [ ${#failed_scripts[@]} -eq 0 ]; then
        print_success "All scripts completed successfully!"
        echo ""
        print_success "Total execution time: ${hours}h ${minutes}m ${seconds}s"
        echo ""
        print_success "Results are available in the output/ directory"
        print_success "Check individual output subdirectories for specific results"
        print_success "Detailed logs are available in output/logs/"
    else
        print_error "Pipeline completed with errors"
        print_error "Failed scripts: ${failed_scripts[*]}"
        echo ""
        print_warning "Partial results may be available in the output/ directory"
        print_warning "Check individual log files in output/logs/ for error details"
    fi
    
    # Generate completion summary
    generate_summary
    
    echo ""
    echo "============================================================================="
    echo "For detailed information, see:"
    echo "- README.md: Complete pipeline documentation"
    echo "- output/analysis_completion_summary.txt: Execution summary"
    echo "- output/logs/: Detailed execution logs for each script"
    echo "- Individual log files in output/logs/ for script-specific details"
    echo "============================================================================="
}

# Run main function
print_status "Starting main function execution"
main "$@"
print_status "Main function execution completed"