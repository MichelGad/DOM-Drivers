# =============================================================================
# Script: processing.py
# Purpose: Processing module for machine learning analysis in DOM-environment correlation study
# Author: Michel Gad
# Date: 2025-09-15
# Description: 
#   - Provide essential functions for machine learning analysis
#   - Data preparation, outlier detection, cross-validation
#   - SHAP analysis and feature importance evaluation for Random Forest models
#   - Supporting functions for 6. MRF.py script
#   - Supporting Publication: Water Research 2024 - DOI: 10.1016/j.watres.2024.123018
# =============================================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.inspection import permutation_importance
import shap
from shap.explainers._tree import TreeExplainer as OriginalTreeExplainer
import warnings

# The CustomTreeExplainer class remains largely the same,
# as its __init__ properly handles kwargs, and its shap_values
# method handles check_additivity. The issue was in the *call* to it.
class CustomTreeExplainer(OriginalTreeExplainer):
    """
    Initializes the CustomTreeExplainer class, which is an extension of the OriginalTreeExplainer class.
    This class is used for explaining the predictions of tree-based models using SHAP values.

    Parameters:
    model: The tree-based machine learning model (like XGBoost, LightGBM, etc.) to be explained.
    data: Optional dataset used for initializing the explainer and understanding the model's decisions.
    model_output: Specifies the type of model output ("raw", "probability", etc.). Default is "raw".
    feature_perturbation: Method used for perturbing features to understand their impact. Options include
                          "interventional", "tree_path_dependent", and "global_path_dependent".
    **kwargs: Additional keyword arguments.

    The class also defines two dictionaries, 'feature_perturbation_codes' and 'output_transform_codes',
    to translate the string options to numerical codes used in underlying calculations.
    """
    def __init__(self, model, data=None, model_output="raw", feature_perturbation="interventional", **kwargs):
        # Define the feature perturbation and output transform codes
        self.feature_perturbation_codes = {
            "interventional": 0,
            "tree_path_dependent": 1,
            "global_path_dependent": 2
        }
        self.output_transform_codes = {
            "identity": 0,
            "logistic": 1,
            "logistic_nlogloss": 2,
            "squared_loss": 3
        }

        # IMPORTANT: Remove check_additivity from kwargs if it somehow makes it here
        # Although the primary fix is at the call site, this makes the class more robust.
        kwargs.pop('check_additivity', None)
        super().__init__(model, data, model_output=model_output, feature_perturbation=feature_perturbation, **kwargs)

    def shap_values(self, X, y=None, tree_limit=None, approximate=False, check_additivity=False, from_call=False):
        """
        Calculate SHAP values for the given input data. SHAP values provide insights into how each feature in the dataset
        contributes to the model's prediction.

        Parameters:
        X: Input data for which SHAP values are to be computed.
        y: Optional labels for the input data. Required if model_output is set to "log_loss".
        tree_limit: Limit the number of trees used in the calculation. If None, use all trees.
        approximate: If True, use an approximate algorithm for speed. Default is False.
        check_additivity: Check if the SHAP values sum up to the model output. Default is False.
        from_call: Internal parameter, indicates if called from another method.

        Returns:
        out: Calculated SHAP values for the input data.
        """
        # see if we have a default tree_limit in place.
        if tree_limit is None:
            tree_limit = -1 if self.model.tree_limit is None else self.model.tree_limit

        X, y, X_missing, flat_output, tree_limit, _ = self._validate_inputs(
            X, y, tree_limit, check_additivity=check_additivity # check_additivity is passed here
        )
        transform = self.model.get_transform()

        # run the core algorithm using the C extension
        phi = np.zeros((X.shape[0], X.shape[1]+1, self.model.num_outputs))
        if not approximate:
            shap._cext.dense_tree_shap(
                self.model.children_left, self.model.children_right, self.model.children_default,
                self.model.features, self.model.thresholds, self.model.values, self.model.node_sample_weight,
                self.model.max_depth, X, X_missing, y, self.data, self.data_missing, tree_limit,
                self.model.base_offset, phi, self.feature_perturbation_codes[self.feature_perturbation],
                self.output_transform_codes[transform], False
            )
        else:
            shap._cext.dense_tree_saabas(
                self.model.children_left, self.model.children_right, self.model.children_default,
                self.model.features, self.model.thresholds, self.model.values,
                self.model.max_depth, tree_limit, self.model.base_offset, self.output_transform_codes[transform],
                X, X_missing, y, phi
            )

        out = self._get_shap_output(phi, flat_output)

        return out

    def _validate_inputs(self, X, y, tree_limit, check_additivity):
        """
        Validates and preprocesses the input data and parameters for the SHAP value calculation.

        Parameters:
        X: Input data for which SHAP values are to be calculated.
        y: Optional labels, required if model_output is set to 'log_loss'.
        tree_limit: The limit on the number of trees to use. If None, uses all available trees in the model.
        check_additivity: Flag to check if SHAP values sum up to the model output.

        The method ensures that:
        - The tree_limit is within valid range.
        - Input data X is in the correct format.
        - Input data types match the model's expected input types.
        - If model_output is 'log_loss', both X and y are provided and have compatible dimensions.
        - The feature_perturbation setting is compatible with the provided model.

        Returns:
        Tuple containing processed X, y, X_missing (boolean array indicating missing values),
        flat_output (flag indicating if the output should be flat), tree_limit, and check_additivity.
        """
        # see if we have a default tree_limit in place.
        if tree_limit is None:
            tree_limit = -1 if self.model.tree_limit is None else self.model.tree_limit

        if tree_limit < 0 or tree_limit > self.model.values.shape[0]:
            tree_limit = self.model.values.shape[0]
        # convert dataframes
        if isinstance(X, (pd.Series, pd.DataFrame)):
            X = X.values
        flat_output = False
        if len(X.shape) == 1:
            flat_output = True
            X = X.reshape(1, X.shape[0])
        if X.dtype != self.model.input_dtype:
            X = X.astype(self.model.input_dtype)
        X_missing = np.isnan(X, dtype=bool)
        assert isinstance(X, np.ndarray), "Unknown instance type: " + str(type(X))
        assert len(X.shape) == 2, "Passed input data matrix X must have 1 or 2 dimensions!"

        if self.model.model_output == "log_loss":
            if y is None:
                emsg = (
                    "Both samples and labels must be provided when model_output = \"log_loss\" "
                    "(i.e. `explainer.shap_values(X, y)`)!"
                )
                raise Exception(emsg) # Changed ExplainerError to Exception for wider compatibility
            if X.shape[0] != len(y):
                emsg = (
                    f"The number of labels ({len(y)}) does not match the number of samples "
                    f"to explain ({X.shape[0]})!"
                )
                raise Exception(emsg) # Changed DimensionError to Exception

        if self.feature_perturbation == "tree_path_dependent":
            if not self.model.fully_defined_weighting:
                emsg = (
                    "The background dataset you provided does "
                    "not cover all the leaves in the model, "
                    "so TreeExplainer cannot run with the "
                    "feature_perturbation=\"tree_path_dependent\" option! "
                    "Try providing a larger background "
                    "dataset, no background dataset, or using "
                    "feature_perturbation=\"interventional\"."
                )
                raise Exception(emsg) # Changed ExplainerError to Exception

        if check_additivity and self.model.model_type == "pyspark":
            warnings.warn(
                "check_additivity requires us to run predictions which is not supported with "
                "spark, "
                "ignoring."
                " Set check_additivity=False to remove this warning")
            check_additivity = False

        return X, y, X_missing, flat_output, tree_limit, check_additivity

    def _get_shap_output(self, phi, flat_output):
        """
           Processes the raw SHAP values (phi) and extracts the final output.

           Parameters:
           phi: Raw SHAP values array.
           flat_output: Flag indicating if the output should be flattened.

           This method adjusts the SHAP values based on the model's output type and expected value settings.
           It handles single and multiple output scenarios and formats the SHAP values accordingly.

           Returns:
           The final SHAP values in the format corresponding to the model's output requirements.
           """
        if self.model.num_outputs == 1:
            if self.expected_value is None and self.model.model_output != "log_loss":
                self.expected_value = phi[0, -1, 0]
            if flat_output:
                out = phi[0, :-1, 0]
            else:
                out = phi[:, :-1, 0]
        else:
            if self.expected_value is None and self.model.model_output != "log_loss":
                self.expected_value = [phi[0, -1, i] for i in range(phi.shape[2])]
            if flat_output:
                out = [phi[0, :-1, i] for i in range(self.model.num_outputs)]
            else:
                out = [phi[:, :-1, i] for i in range(self.model.num_outputs)]

        # if our output format requires binary classification to be represented as two outputs then we do that here
        if self.model.model_output == "probability_doubled":
            out = [-out, out]
        return out


# --- Data Preparation Functions (unchanged for this fix) ---
def prepare_data(file_path):
    """
    Prepare the dataset for analysis.
    ... (function body unchanged) ...
    """
    # Set a seed for reproducibility
    random_state = 123
    np.random.seed(random_state)

    # Import the dataset from the specified file path
    data = pd.read_csv(file_path)

    # Remove un-needed variables and features
    columns_to_remove = ['formula_string']

    # Check and remove columns if they exist in the DataFrame
    for col in columns_to_remove:
        if col in data.columns:
            data = data.drop(col, axis=1)

    # Add synthetic data for experimentation or further analysis
    # The synthetic data is generated uniformly between -1 and 1
    data['generated'] = np.round(np.random.uniform(-1, 1, size=(len(data), 1)), 7)

    # Collect the variable names for features and target variables
    col = list(data.columns)
    y = [column for column in col if column.startswith("rho")]  # Target variables (start with 'rho')
    Y = data[y]  # DataFrame of target variables
    x = list(set(col) - set(y))  # Feature names after removing target variable names
    X = data[x]  # DataFrame of features

    # Return the feature names, target names, and processed DataFrames
    return x, y, X, Y

def outlier_threshold(normality, k=1.5):
    """
    Calculates the lower threshold for identifying outliers in a dataset.
    ... (function body unchanged) ...
    """
    q1 = np.quantile(normality, 0.25)
    q3 = np.quantile(normality, 0.75)
    threshold = q1 - k * (q3 - q1)
    return threshold

def cross_validation_results(model, X, y, cv):
    """
    Perform cross-validation on the given model using the provided dataset and cross-validator.
    ... (function body unchanged) ...
    """
    metrics_data = []

    for train_index, test_index in cv.split(X):
        X_train, X_test = X.iloc[train_index], X.iloc[test_index]
        y_train, y_test = y.iloc[train_index], y.iloc[test_index]

        # Train and predict using the current fold
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)

        # Calculating metrics for each fold
        mae = mean_absolute_error(y_test, y_pred)
        mse = mean_squared_error(y_test, y_pred)
        rmse = np.sqrt(mse)
        r2 = r2_score(y_test, y_pred)

        metrics_data.append([mae, mse, rmse, r2])

    df = pd.DataFrame(metrics_data, columns=['MAE', 'MSE', 'RMSE', 'R2'])
    return df

def plot_shap_beewarm(model, data, features, num_samples=100, random_state=42, output_dir="output/MRF/beeswarm"):
    """
    Generates and exports SHAP beeswarm plots for each output of the given model and data.
    """
    import os
    import matplotlib
    matplotlib.use('Agg')  # Use non-interactive backend
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Sample the training data
    X_sampled = data.sample(n=num_samples, random_state=random_state)
    print(f"Sampled {len(X_sampled)} rows for SHAP analysis")

    # Create the explainer
    explainer = CustomTreeExplainer(model, data=X_sampled)

    # Compute SHAP values
    shap_values = explainer.shap_values(X_sampled)
    print(f"SHAP values shape: {np.array(shap_values).shape}")

    # Handle different SHAP value structures
    if isinstance(shap_values, list):
        # Multi-output case
        for index, values in enumerate(shap_values):
            values = np.array(values)
            print(f"Processing output {index}, SHAP values shape: {values.shape}")
            
            # Create the Explanation object
            expected_value = explainer.expected_value
            if isinstance(expected_value, list):
                expected_value = expected_value[index]
            
            explanation = shap.Explanation(values=values, base_values=expected_value, data=X_sampled)
            
            # Set figure size and plot the beeswarm plot
            plt.figure(figsize=(12, 8))
            try:
                shap.plots.beeswarm(explanation, show=False)
                plt.tight_layout()
                
                # Get feature name
                feature_name = features[index] if index < len(features) else f"output_{index}"
                
                # Save the plot in the output directory
                output_path = os.path.join(output_dir, f"{feature_name}_beeswarm_plot.pdf")
                plt.savefig(output_path, dpi=300, bbox_inches='tight')
                plt.close()
                print(f"SHAP beeswarm plot saved to: {output_path}")
            except Exception as e:
                print(f"Error creating beeswarm plot for output {index}: {e}")
                # Try alternative approach with summary plot
                plt.figure(figsize=(12, 8))
                shap.summary_plot(values, X_sampled, show=False)
                plt.tight_layout()
                
                feature_name = features[index] if index < len(features) else f"output_{index}"
                output_path = os.path.join(output_dir, f"{feature_name}_summary_plot.pdf")
                plt.savefig(output_path, dpi=300, bbox_inches='tight')
                plt.close()
                print(f"SHAP summary plot saved to: {output_path} (beeswarm failed)")
    else:
        # Single output case
        values = np.array(shap_values)
        print(f"Single output case, SHAP values shape: {values.shape}")
        
        # Create the Explanation object
        expected_value = explainer.expected_value
        explanation = shap.Explanation(values=values, base_values=expected_value, data=X_sampled)
        
        # Set figure size and plot the beeswarm plot
        plt.figure(figsize=(12, 8))
        try:
            shap.plots.beeswarm(explanation, show=False)
            plt.tight_layout()
            
            # Get feature name
            feature_name = features[0] if len(features) > 0 else "output"
            
            # Save the plot in the output directory
            output_path = os.path.join(output_dir, f"{feature_name}_beeswarm_plot.pdf")
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            plt.close()
            print(f"SHAP beeswarm plot saved to: {output_path}")
        except Exception as e:
            print(f"Error creating beeswarm plot: {e}")
            # Try alternative approach with summary plot
            plt.figure(figsize=(12, 8))
            shap.summary_plot(values, X_sampled, show=False)
            plt.tight_layout()
            
            feature_name = features[0] if len(features) > 0 else "output"
            output_path = os.path.join(output_dir, f"{feature_name}_summary_plot.pdf")
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            plt.close()
            print(f"SHAP summary plot saved to: {output_path} (beeswarm failed)")

def bar_shap_plot(model, X_train, num_samples=10, output_file='bar_shap_plot.pdf'):
    """
    Generate an interactive SHAP bar plot for models with multi-dimensional SHAP values and save it as a PDF file.
    ... (function body unchanged) ...
    """
    # Ensure X_train is a DataFrame
    if not isinstance(X_train, pd.DataFrame):
        raise ValueError("X_train must be a pandas DataFrame.")

    # Ensure num_samples is an integer
    if not isinstance(num_samples, int):
        raise ValueError("num_samples must be an integer.")

    # Sample a subset of the training data
    X_sampled = X_train.sample(n=min(num_samples, len(X_train)), random_state=0)

    # Initialize the SHAP explainer with the model
    explainer = CustomTreeExplainer(model, X_sampled)

    # Calculate SHAP values for the sampled training data
    shap_values = explainer(X_sampled)

    # Handle multi-dimensional SHAP values by averaging across the outputs
    if len(shap_values.values.shape) == 3:
        shap_values_avg = np.abs(shap_values.values).mean(axis=2)
    else:
        shap_values_avg = np.abs(shap_values.values)

    shap_values_df = pd.DataFrame(shap_values_avg, columns=X_train.columns)

    # Calculate the mean SHAP values for each feature
    shap_sum = shap_values_df.mean().sort_values(ascending=False).reset_index()
    shap_sum.columns = ['Feature', 'SHAP Value']

    # Create a bar plot using matplotlib.pyplot
    plt.figure(figsize=(10, 8))  # Adjust figure size
    plt.barh(shap_sum['Feature'], shap_sum['SHAP Value'])
    plt.xlabel('Mean Absolute SHAP Values')
    plt.title('Mean Absolute SHAP Values')

    # Save the plot as a PDF file with high quality
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"SHAP bar plot saved to: {output_file}")

def plot_shap_summary(model, X_train, num_samples=100, output_file='plot_shap_summary.pdf'):
    """
    Generate SHAP summary plot and save it as a PDF file.
    """
    import os
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    
    # Sample the training data
    X_sampled = X_train.sample(n=min(num_samples, len(X_train)), random_state=42)

    # Create the explainer
    explainer = CustomTreeExplainer(model, X_sampled)

    # Compute SHAP values
    shap_values = explainer.shap_values(X_sampled)

    # Create the summary plot
    plt.figure(figsize=(12, 8))
    shap.summary_plot(shap_values, X_sampled, show=False)
    plt.tight_layout()
    
    # Save the plot
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"SHAP summary plot saved to: {output_file}")

def plot_feature_importance(model, X_test, y_test, feature_names, n_repeats=30, random_state=123, n_jobs=1):
    """
    Calculate and plot feature importance using permutation importance, with bars
    sorted from lowest to highest importance.
    ... (function body unchanged) ...
    """

    # Calculating feature importance
    try:
        result = permutation_importance(
            model, X_test, y_test, scoring='neg_root_mean_squared_error', n_repeats=n_repeats,
            random_state=random_state, n_jobs=n_jobs
        )
    except Exception as e:
        print(f"Error with parallel processing: {e}")
        print("Falling back to single-threaded calculation...")
        result = permutation_importance(
            model, X_test, y_test, scoring='neg_root_mean_squared_error', n_repeats=n_repeats,
            random_state=random_state, n_jobs=1
        )

    forest_importances = pd.Series(result.importances_mean, index=feature_names)

    # Sorting the importances
    forest_importances = forest_importances.sort_values()

    # Plotting
    fig, ax = plt.subplots()
    forest_importances.plot.bar(yerr=result.importances_std, ax=ax)
    ax.set_title("Feature importances using permutation on full model")
    ax.set_ylabel("Mean decrease in RMSE")
    fig.tight_layout()

    # Tilt x-axis labels
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')

    # Save the plot
    plt.savefig("Feature_importance.pdf", format='pdf', dpi=300, bbox_inches='tight')
    plt.close()
    print("Feature importance plot saved to: Feature_importance.pdf")

