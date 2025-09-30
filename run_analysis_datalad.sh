#!/bin/bash
# =============================================================================
# DataLad Run Script for Unraveling Environmental Drivers of DOM Composition in Central European Aquatic Systems (DOM-Drivers)
# Author: Michel Gad
# Date: 2025-01-21
# Description: Complete reproducible analysis pipeline using datalad run with Python virtual environment
# Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

set -e  # Exit on any error

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

# Function to check if datalad is available
check_datalad() {
    if ! command -v datalad &> /dev/null; then
        print_error "DataLad is not installed. Please install DataLad first."
        exit 1
    fi
}

# Function to check if virtual environment is available
check_venv() {
    if [ ! -d "venv" ]; then
        print_error "Virtual environment not found. Please create it first:"
        print_error "python3 -m venv venv"
        print_error "source venv/bin/activate"
        print_error "pip install -r requirements.txt"
        exit 1
    fi
    
    if [ ! -f "venv/bin/activate" ]; then
        print_error "Virtual environment activation script not found."
        exit 1
    fi
}

# Function to activate virtual environment
activate_venv() {
    print_status "Activating virtual environment..."
    
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        print_success "Virtual environment activated!"
    else
        print_error "Virtual environment activation script not found."
        exit 1
    fi
}

# Function to check if we're in a datalad dataset
check_dataset() {
    if [ ! -d ".datalad" ]; then
        print_error "Not in a DataLad dataset. Please run this script from the dataset root."
        exit 1
    fi
}

# Function to create logs directory
setup_logs() {
    print_status "Setting up logging directory..."
    
    # Create logs directory if it doesn't exist
    mkdir -p output/logs
    
    print_success "Logging directory ready!"
}

# Function to ensure data is available
ensure_data() {
    print_status "Ensuring input data is available..."
    
    # Check if input dataset exists and is properly configured
    if [ ! -d "input/.datalad" ]; then
        print_error "Input dataset not found. The input/ directory should be a DataLad dataset."
        print_error "Please ensure the nested input dataset is properly configured."
        exit 1
    fi
    
    # Check if input files exist
    required_files=(
        "input/env_2025-01-21.csv"
        "input/formulas.clean_2025-01-21.csv"
        "input/eval.summary.clean_2025-01-21.csv"
        "input/Repository_file_definition_2022_03_20.csv"
    )
    
    missing_files=()
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_status "Getting missing input files from Google Drive (nested dataset)..."
        datalad get input/
    else
        print_success "All input files are available!"
    fi
}

# Function to run script 1: Molecular Formula Processing
run_mf_analysis() {
    print_status "Running Script 1: Molecular Formula Processing (mf.R)"
    
    datalad run \
        --explicit \
        --input "input/formulas.clean_2025-01-21.csv" \
        --input "input/eval.summary.clean_2025-01-21.csv" \
        --output "processed/mf_processed.csv" \
        --output "output/mf/" \
        -m "Process molecular formula data: import, clean, and analyze molecular formula data from FT-ICR MS" \
        "Rscript scripts/1.\ mf.R 2>&1 | tee output/logs/script_1_mf.log"
    
    print_success "Molecular formula processing completed!"
}

# Function to run script 2: Environmental Parameters
run_env_analysis() {
    print_status "Running Script 2: Environmental Parameters Processing (env.R)"
    
    datalad run \
        --explicit \
        --input "input/env_2025-01-21.csv" \
        --output "processed/parameters_env_processed.csv" \
        --output "output/env/" \
        -m "Process environmental parameters: import, clean, and normalize environmental data" \
        "Rscript scripts/2.\ env.R 2>&1 | tee output/logs/script_2_env.log"
    
    print_success "Environmental parameters processing completed!"
}

# Function to run script 3: Weighted Averages
run_wa_analysis() {
    print_status "Running Script 3: Weighted Averages Processing (wa.R)"
    
    datalad run \
        --explicit \
        --input "processed/mf_processed.csv" \
        --output "processed/wa_mean_processed.csv" \
        --output "output/wa/" \
        -m "Calculate weighted averages: process molecular data to calculate intensity-weighted averages" \
        "Rscript scripts/3.\ wa.R 2>&1 | tee output/logs/script_3_wa.log"
    
    print_success "Weighted averages processing completed!"
}

# Function to run script 4: Principal Component Analysis
run_pca_analysis() {
    print_status "Running Script 4: Principal Component Analysis (pca.R)"
    
    datalad run \
        --explicit \
        --input "processed/parameters_env_processed.csv" \
        --input "processed/wa_mean_processed.csv" \
        --output "processed/pca/" \
        --output "output/pca/" \
        -m "Perform PCA: dimensionality reduction on environmental and molecular data" \
        "Rscript scripts/4.\ pca.R 2>&1 | tee output/logs/script_4_pca.log"
    
    print_success "Principal Component Analysis completed!"
}

# Function to run script 5: Correlation Analysis
run_corr_analysis() {
    print_status "Running Script 5: Correlation Analysis (corr.R)"
    
    datalad run \
        --explicit \
        --input "processed/mf_processed.csv" \
        --input "processed/parameters_env_processed.csv" \
        --output "processed/rho_MF.csv" \
        --output "output/corr/" \
        -m "Analyze correlations: calculate Spearman correlations between molecular features and environmental parameters" \
        "Rscript scripts/5.\ corr.R 2>&1 | tee output/logs/script_5_corr.log"
    
    print_success "Correlation analysis completed!"
}

# Function to run script 6: Machine Learning
run_ml_analysis() {
    print_status "Running Script 6: Machine Learning Analysis (MRF.py)"
    
    datalad run \
        --explicit \
        --input "processed/rho_MF.csv" \
        --input "scripts/processing.py" \
        --output "processed/MRF/" \
        --output "output/MRF/" \
        -m "Machine learning analysis: Random Forest regression with SHAP interpretability" \
        "python3 scripts/6.\ MRF.py 2>&1 | tee output/logs/script_6_mrf.log"
    
    print_success "Machine learning analysis completed!"
}

# Function to create completion summary
create_completion_summary() {
    print_status "Creating analysis completion summary..."
    
    local summary_file="output/logs/analysis_completion_summary.txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$summary_file" << EOF
DOM-Drivers Analysis Pipeline Completion Summary
===============================================
Completion Time: $timestamp
Environment: Python Virtual Environment
DataLad Dataset: $(pwd)

Analysis Steps Completed:
------------------------
1. Molecular Formula Processing (mf.R) - ✅ COMPLETED
2. Environmental Parameters Processing (env.R) - ✅ COMPLETED  
3. Weighted Averages Processing (wa.R) - ✅ COMPLETED
4. Principal Component Analysis (pca.R) - ✅ COMPLETED
5. Correlation Analysis (corr.R) - ✅ COMPLETED
6. Machine Learning Analysis (MRF.py) - ✅ COMPLETED

Output Files Generated:
-----------------------
- Processed data: processed/
- Analysis plots: output/
- Execution logs: output/logs/
- Completion summary: $summary_file

Reproducibility:
----------------
- All script executions tracked in git history
- Input/output dependencies recorded
- Complete provenance chain maintained
- All scripts executed in Python virtual environment

For detailed execution logs, see individual log files in output/logs/
EOF

    print_success "Analysis completion summary created!"
}

# Function to save all results
save_results() {
    print_status "Saving all analysis results to DataLad..."
    
    datalad save \
        -m "Complete DOM-Drivers analysis pipeline results" \
        output/ processed/
    
    print_success "All results saved to DataLad dataset!"
}

# Function to show analysis summary
show_summary() {
    print_status "Analysis Summary:"
    echo "=================="
    echo "📊 Input Data:"
    echo "  - Environmental parameters: input/env_2025-01-21.csv"
    echo "  - Molecular formulas: input/formulas.clean_2025-01-21.csv"
    echo "  - Evaluation summary: input/eval.summary.clean_2025-01-21.csv"
    echo "  - Repository definitions: input/Repository_file_definition_2022_03_20.csv"
    echo ""
    echo "📁 Processed Data:"
    echo "  - Molecular formula data: processed/mf_processed.csv"
    echo "  - Environmental data: processed/parameters_env_processed.csv"
    echo "  - Weighted averages: processed/wa_mean_processed.csv"
    echo "  - Correlation matrix: processed/rho_MF.csv"
    echo "  - PCA results: processed/pca/"
    echo "  - ML results: processed/MRF/"
    echo ""
    echo "📈 Output Plots:"
    echo "  - Molecular formula plots: output/mf/"
    echo "  - Environmental parameter plots: output/env/"
    echo "  - Weighted average plots: output/wa/"
    echo "  - PCA plots: output/pca/"
    echo "  - Correlation plots: output/corr/"
    echo "  - Machine learning plots: output/MRF/"
    echo ""
    echo "🔍 Reproducibility:"
    echo "  - All script executions tracked in git history"
    echo "  - Input/output dependencies recorded"
    echo "  - Complete provenance chain maintained"
    echo "  - All scripts executed in Python virtual environment for consistent environment"
}

# Main execution function
main() {
    print_status "Starting DOM-Drivers Analysis Pipeline with DataLad + Virtual Environment"
    print_status "========================================================================"
    
    # Check prerequisites
    check_datalad
    check_venv
    check_dataset
    
    # Activate virtual environment
    activate_venv
    
    # Setup logging
    setup_logs
    
    # Ensure data is available
    ensure_data
    
    # Run analysis pipeline in correct order
    print_status "Starting analysis pipeline..."
    echo ""
    
    run_mf_analysis
    echo ""
    
    run_env_analysis
    echo ""
    
    run_wa_analysis
    echo ""
    
    run_pca_analysis
    echo ""
    
    run_corr_analysis
    echo ""
    
    run_ml_analysis
    echo ""
    
    # Create completion summary
    create_completion_summary
    echo ""
    
    # Save all results
    save_results
    echo ""
    
    # Show summary
    show_summary
    
    print_success "DOM-Drivers analysis pipeline completed successfully!"
    print_status "All results are tracked in DataLad for full reproducibility."
    print_status "All scripts executed in Python virtual environment for consistent environment."
}

# Run main function
main "$@"
