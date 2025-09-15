# =============================================================================
# Script: 6. MRF.py
# Purpose: Machine Learning Random Forest regression with SHAP interpretability for DOM analysis
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Prepare data for Random Forest Regression model using correlation results from corr.R
#   - Implement outlier detection using Isolation Forest to enhance model robustness
#   - Perform Repeated K-Fold Cross-Validation for rigorous model evaluation
#   - Apply SHAP analysis to interpret model predictions and feature contributions
#   - Calculate permutation feature importance to identify most impactful features
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

# Print script header information
print("=============================================================================")
print("Script: 6. MRF.py")
print("Purpose: Machine Learning Random Forest regression with SHAP interpretability for DOM analysis")
print("Author: Michel Gad")
print("Date: 2025-09-15")
print("Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018")
print("=============================================================================")
print()

# Import libraries
from processing import (prepare_data, outlier_threshold, cross_validation_results, 
                        plot_shap_beewarm, plot_feature_importance)
import numpy as np
import pandas as pd
import plotly.express as px
from sklearn.ensemble import IsolationForest
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import RepeatedKFold, train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.inspection import permutation_importance
import os # For creating output directories

# --- Global Settings ---
# Seed value for reproducibility
random_state = 123
np.random.seed(random_state)
print("\n--- Initializing Random Forest machine learning analysis ---")

# Define output directories
output_plot_dir = "output/MRF"
output_data_dir = "processed/MRF"

# Create directories if they don't exist
os.makedirs(output_plot_dir, exist_ok=True)
os.makedirs(output_data_dir, exist_ok=True)
print(f"Created plot output directory: {output_plot_dir}")
print(f"Created data output directory: {output_data_dir}")
print("Output directories created successfully.")

# --- Data Preparation ---
# 1. Import dataset
print("\n## --- Data Preparation ---")
print("Importing dataset from 'rho_MF.csv' and preparing features/targets...")
x, y, X, Y = prepare_data("processed/rho_MF.csv")

print("\n--- Displaying extracted feature names (x) ---")
print(x)
print("\n--- Displaying extracted target names (y) ---")
print(y)
print("\n--- Displaying features DataFrame (X, first 5 rows) ---")
print(X.head())
print("\n--- Displaying targets DataFrame (Y, first 5 rows) ---")
print(Y.head())

# 2. Split the data into training, validation, and test sets
print("\nSplitting data into training, validation, and test sets (80/10/10 split)...")
X_train, X_temp, y_train, y_temp = train_test_split(X, Y, train_size=.8, random_state=random_state)
X_valid, X_test, y_valid, y_test = train_test_split(X_temp, y_temp, test_size=.5, random_state=random_state)

print(f"\n--- Training set dimensions: X_train {X_train.shape}, y_train {y_train.shape} ---")
print(f"--- Validation set dimensions: X_valid {X_valid.shape}, y_valid {y_valid.shape} ---")
print(f"--- Test set dimensions: X_test {X_test.shape}, y_test {y_test.shape} ---")

print("\n--- Displaying X_train (first 5 rows) ---")
print(X_train.head())
print("\n--- Displaying y_train (first 5 rows) ---")
print(y_train.head())

# --- Outlier Detection ---
print("\n## --- Outlier Detection ---")
print("Applying Isolation Forest to detect outliers in the training set...")

clf = IsolationForest(
    n_estimators=100,
    max_samples='auto',
    n_jobs=-1,
    random_state=random_state # Added random_state for reproducibility
)

clf.fit(X_train)
normality_df = pd.DataFrame(clf.decision_function(X_train), columns=['normality'])

print("\n--- Displaying normality_df (first 5 rows) ---")
print(normality_df.head())

threshold = outlier_threshold(normality_df['normality'].values, k=1.5)
print(f"\nCalculated outlier threshold: {threshold:.4f}")

# Histogram plot
print("Generating histogram plot of normality scores...")
fig = px.histogram(normality_df, x='normality')
fig.add_vline(x=threshold, line_width=3, line_dash="dash", line_color="red")
fig.write_html(os.path.join(output_plot_dir, "histogram_plot.html"))
print(f"Histogram plot saved to: {os.path.join(output_plot_dir, 'histogram_plot.html')}")

# Box plot
print("Generating box plot of normality scores...")
fig = px.box(normality_df, x='normality', orientation='h')
fig.add_vline(x=threshold, line_width=3, line_dash="dash", line_color="red")
fig.write_html(os.path.join(output_plot_dir, "box_plot.html"))
print(f"Box plot saved to: {os.path.join(output_plot_dir, 'box_plot.html')}")

# Remove outliers
print(f"\nRemoving outliers from training data (normality_df['normality'].values < {threshold:.4f})...")
initial_train_rows = X_train.shape[0]
X_train = X_train[normality_df['normality'].values >= threshold]
y_train = y_train[normality_df['normality'].values >= threshold]
rows_removed = initial_train_rows - X_train.shape[0]
print(f"Removed {rows_removed} outliers. New X_train shape: {X_train.shape}, y_train shape: {y_train.shape}")

print("\n--- Displaying X_train after outlier removal (first 5 rows) ---")
print(X_train.head())
print("\n--- Displaying y_train after outlier removal (first 5 rows) ---")
print(y_train.head())

# --- Modelling ---
print("\n## --- Modelling ---")

# RepeatedKFold parameters:
n_splits = 5
n_repeats = 10
rkf = RepeatedKFold(n_splits=n_splits, n_repeats=n_repeats, random_state=random_state)
print(f"Repeated K-Fold Cross-Validation configured with {n_splits} splits and {n_repeats} repeats.")

# best Model Hyperparameters
parameters = {
    'max_depth': 45,
    'max_features': 'sqrt',
    'n_estimators': 300,
    'random_state': 18 # Note: Original code uses 18, not global random_state
}
print("\nRandom Forest Regressor hyperparameters defined:")
for param, value in parameters.items():
    print(f"- {param}: {value}")

# Define base regressor
base_regr = RandomForestRegressor(**parameters)
print("\nRandom Forest Regressor model instantiated.")

# Fit the model
print("Fitting the model on the cleaned training data...")
best_model = base_regr.fit(X_train, y_train)
print("Model fitting complete.")

# Model performance on training set
model_score = best_model.score(X_train, y_train)
print(f"\nBest Model R-squared Score on Training Set: {model_score:.4f}")

# --- Cross-Validation ---
print("\n### --- Cross-Validation ---")
print("Performing cross-validation on the training data...")
results = cross_validation_results(best_model, X_train, y_train, cv=rkf)
print("Cross-validation completed.")

print("\n--- Displaying Cross-Validation Results DataFrame (results, first 5 rows) ---")
print(results.head())

# Export the DataFrame to CSV
cv_results_file = os.path.join(output_data_dir, "CV_results.csv")
results.to_csv(cv_results_file, index=False)
print(f"Cross-validation results exported to: {cv_results_file}")

# --- Prediction and Evaluation ---
print("\n## --- Prediction and Evaluation ---")
print("Making predictions on the test data...")
Y_pred = best_model.predict(X_test)
print("Predictions complete.")

# Convert Y_pred to DataFrame for consistent head() display if needed
if isinstance(Y_pred, np.ndarray):
    Y_pred_df = pd.DataFrame(Y_pred, columns=y, index=X_test.index)
else:
    Y_pred_df = Y_pred

print("\n--- Displaying predicted values (Y_pred, first 5 rows) ---")
print(Y_pred_df.head())

# Compute evaluation metrics
mse = mean_squared_error(y_test, Y_pred)
rmse = mse ** .5
score = r2_score(y_test, Y_pred)
output_errors = np.sqrt(np.average((y_test - Y_pred) ** 2, axis=0))

# Print results
print(f"\nBest Model R-squared Score on Testing Set: {score:.4f}")
print(f"Best Model Mean Squared Error (MSE) on Testing Set: {mse:.4f}")
print(f"Best Model Root Mean Squared Error (RMSE) on Testing Set: {rmse:.4f}")
print("RMSE for each target (output_errors):")
print(output_errors)

# --- SHAP Analysis and Plotting ---
print("\n## --- SHAP Analysis and Plotting ---")

# Plot the beeswarm plot
print("Generating SHAP beeswarm plot...")
plot_shap_beewarm(best_model, X_train, y, num_samples=min(10, len(X_train)), 
                  random_state=random_state)

# --- Feature Importance ---
print("\n## --- Feature Importance ---")
print("Calculating feature importance using permutation importance...")
try:
    result = permutation_importance(
            best_model, X_test, y_test, scoring='neg_root_mean_squared_error', n_repeats=n_repeats,
            random_state=random_state, n_jobs = 1  # Reduced to 1 to avoid multiprocessing issues
        )
except Exception as e:
    print(f"Error with parallel processing: {e}")
    print("Falling back to single-threaded calculation...")
    result = permutation_importance(
            best_model, X_test, y_test, scoring='neg_root_mean_squared_error', n_repeats=n_repeats,
            random_state=random_state, n_jobs = 1
        )

forest_importances = pd.Series(result.importances_mean, index=x)
print("\n--- Displaying Feature Importances (forest_importances) ---")
print(forest_importances)

# Plot feature importance
print("Generating feature importance plot...")
# Change to output directory for saving
original_dir = os.getcwd()
os.chdir(output_plot_dir)
plot_feature_importance(best_model, X_test, y_test, feature_names=x,
                        n_repeats=n_repeats, random_state=random_state, n_jobs=1)
os.chdir(original_dir)
print(f"Feature importance plot saved to: {os.path.join(output_plot_dir, 'Feature_importance.pdf')}")

print("\nScript execution complete!")
