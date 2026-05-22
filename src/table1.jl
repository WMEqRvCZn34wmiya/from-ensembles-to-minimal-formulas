using Pkg
Pkg.activate(".")
using Revise
include("utilsForTest.jl")
include("suitfortest.jl")
using DataFrames
using ComplexityMeasures
using DecisionTree
using Random
using CSV

using MLJ, MLJDecisionTreeInterface
using MLJ: fit!, machine, predict_mode, evaluate, StratifiedCV

using DataFrames
using Statistics
using StatsBase
using StatsBase: sample, countmap


# Function to balance a dataset using oversampling or undersampling
function balance_dataset(X_df, y_cat; method = :undersample)
    # Count occurrences of each class
    class_counts = countmap(y_cat)

    # Check that there are classes
    if isempty(class_counts)
        error("Empty dataset or no valid classes")
    end

    max_count = maximum(values(class_counts))
    min_count = minimum(values(class_counts))

    X_balanced = DataFrame()
    y_balanced = []

    for class in keys(class_counts)
        # Get indices for this class
        class_indices = findall(x -> x == class, y_cat)

        # Check that the class is not empty
        if length(class_indices) == 0
            continue
        end

        X_class = X_df[class_indices, :]
        y_class = y_cat[class_indices]

        current_count = length(class_indices)

        if method == :oversample
            # Oversample up to max_count
            if current_count < max_count
                # Calculate how many samples to add
                n_to_add = max_count - current_count

                # Sample with replacement
                additional_indices = sample(1:current_count, n_to_add, replace = true)
                X_additional = X_class[additional_indices, :]
                y_additional = y_class[additional_indices]

                # Combine original + additional
                X_class_balanced = vcat(X_class, X_additional)
                y_class_balanced = vcat(y_class, y_additional)
            else
                X_class_balanced = X_class
                y_class_balanced = y_class
            end
        elseif method == :undersample
            # Undersample to minority class
            if current_count > min_count
                sampled_indices = sample(1:current_count, min_count, replace = false)
                X_class_balanced = X_class[sampled_indices, :]
                y_class_balanced = y_class[sampled_indices]
            else
                X_class_balanced = X_class
                y_class_balanced = y_class
            end
        else
            error("Unsupported method. Use :oversample or :undersample")
        end

        # Add to balanced dataset
        if nrow(X_balanced) == 0
            X_balanced = X_class_balanced
            y_balanced = y_class_balanced
        else
            X_balanced = vcat(X_balanced, X_class_balanced)
            y_balanced = vcat(y_balanced, y_class_balanced)
        end
    end

    # Shuffle the data
    n_samples = nrow(X_balanced)
    if n_samples > 0
        shuffle_indices = shuffle(1:n_samples)
        return X_balanced[shuffle_indices, :], y_balanced[shuffle_indices]
    else
        error("No samples after balancing")
    end
end

# Function to create stratified folds manually
function create_stratified_folds(y, n_folds = 10)
    n_samples = length(y)
    class_counts = countmap(y)

    # Initialize folds
    folds = [Int[] for _ = 1:n_folds]

    for class in keys(class_counts)
        class_indices = findall(x -> x == class, y)
        n_class_samples = length(class_indices)

        # Shuffle class indices
        shuffled_indices = shuffle(class_indices)

        # Distribute across folds
        for i = 1:n_class_samples
            fold_idx = ((i - 1) % n_folds) + 1
            push!(folds[fold_idx], shuffled_indices[i])
        end
    end

    return folds
end

# Function for cross-validation with training fold balancing
function evaluate_random_forest_balanced(
    X,
    y;
    n_trees = 100,
    max_depth = 3,
    n_folds = 10,
    balance_method = :undersample,
    verbosity = 1,
)
    # Input validation
    if isempty(y)
        error("Empty dataset")
    end

    # Convert X to DataFrame if not already
    if isa(X, Matrix)
        if size(X, 1) == 0
            error("Empty matrix X")
        end
        n_features = size(X, 2)
        feature_names = [Symbol("feature_$i") for i = 1:n_features]
        X_df = DataFrame(X, feature_names)
    elseif isa(X, DataFrame)
        if nrow(X) == 0
            error("Empty DataFrame X")
        end
        X_df = X
    else
        error("X must be a Matrix or DataFrame")
    end

    # Check dimension consistency
    if nrow(X_df) != length(y)
        error(
            "Number of rows in X ($(nrow(X_df))) different from length of y ($(length(y)))",
        )
    end

    # Convert y to CategoricalArray
    y_cat = categorical(y)

    # Check that there are at least 2 classes
    n_classes = length(levels(y_cat))
    if n_classes < 2
        error("At least 2 classes needed for classification")
    end

    # Check that n_folds is reasonable
    if n_folds < 2
        error("n_folds must be at least 2")
    end
    if n_folds > nrow(X_df)
        error(
            "n_folds ($(n_folds)) cannot be greater than number of samples ($(nrow(X_df)))",
        )
    end

    # Prepare the model
    RandomForest = @load RandomForestClassifier pkg=DecisionTree
    if max_depth == -1
        rf_model = RandomForest(n_trees = n_trees)
    else
        rf_model = RandomForest(n_trees = n_trees, max_depth = max_depth)
    end

    # Create stratified folds
    folds = create_stratified_folds(y_cat, n_folds)

    f1_scores = Float64[]

    for fold = 1:n_folds
        if verbosity > 0
            println("Fold $fold/$n_folds")
        end

        # Create indices for test and train
        test_indices = folds[fold]
        train_indices = setdiff(1:nrow(X_df), test_indices)

        # Check that there are samples in both sets
        if length(train_indices) == 0 || length(test_indices) == 0
            @warn "Fold $fold has empty train or test set, skipping..."
            continue
        end

        # Extract train and test sets
        X_train = X_df[train_indices, :]
        y_train = y_cat[train_indices]
        X_test = X_df[test_indices, :]
        y_test = y_cat[test_indices]

        # Check that train set has at least 2 classes
        train_classes = length(levels(y_train))
        if train_classes < 2
            @warn "Fold $fold has less than 2 classes in training set, skipping..."
            continue
        end

        try
            # Balance the training set
            X_train_balanced, y_train_balanced =
                balance_dataset(X_train, y_train, method = balance_method)

            if verbosity > 1
                println("  Original train distribution: $(countmap(y_train))")
                println("  Balanced train distribution: $(countmap(y_train_balanced))")
            end

            # Train the model
            mach = machine(rf_model, X_train_balanced, y_train_balanced)
            fit!(mach, verbosity = 0)

            # Predictions
            y_pred = predict_mode(mach, X_test)

            # Calculate F1 macro
            f1 = macro_f1score(y_pred, y_test)
            push!(f1_scores, f1)

            if verbosity > 0
                println("  F1 Score: $f1")
            end

        catch e
            @warn "Error in fold $fold: $e"
            continue
        end
    end

    # Check that there are results
    if length(f1_scores) == 0
        error("No fold completed successfully")
    end

    return f1_scores
end

function evaluate_random_forest(
    X,
    y;
    n_trees = 100,
    max_depth = 3,
    n_folds = 10,
    verbosity = 1,
)
    return evaluate_random_forest_balanced(
        X,
        y,
        n_trees = n_trees,
        max_depth = max_depth,
        n_folds = n_folds,
        balance_method = :undersample,
        verbosity = verbosity,
    )
end

# Function to print results
function print_results(f1_scores)
    if length(f1_scores) == 0
        println("No results to print")
        return
    end

    println("Average F1 Score: $(mean(f1_scores))")
    println("F1 Score std: $(std(f1_scores))")
    println("Min F1 Score: $(minimum(f1_scores))")
    println("Max F1 Score: $(maximum(f1_scores))")
    println("F1 Score per fold: $f1_scores")
end

# Function to save results to CSV
function save_results_to_csv(results_dict, filename = "rf_results.csv")
    # Create DataFrame for results
    results_df = DataFrame(
        Dataset = String[],
        AvgF1Score = Float64[],
        StdF1Score = Float64[],
        MinF1Score = Float64[],
        MaxF1Score = Float64[],
    )

    for (dataset, f1_scores) in results_dict
        if length(f1_scores) > 0
            push!(
                results_df,
                (
                    dataset,
                    mean(f1_scores),
                    std(f1_scores),
                    minimum(f1_scores),
                    maximum(f1_scores),
                ),
            )
        end
    end

    # Save to CSV
    CSV.write(filename, results_df)
    println("Results saved to $filename")

    return results_df
end

# Example usage with different datasets
function main_usage(;
    n_trees = 100,
    max_depth = 3,
    n_folds = 10,
    csv_filename = "rf_FINAL_results.csv",
)
    datasets = [
        "lenses",
        "veichle_I",
        "ecoli",
        "yeast",
        "veichle_H",
        "veichle_F",
        "tae",
        "post-operative",
        "veichle_A",
        "veichle_G",
        "veichle_B",
        "glass",
        "monks-2",
        "bean",
        "balance-scale",
        "cmc",
        "lymphography",
        "primary-tumor",
        "veichle_C",  #19
        "car",
        "hayes-roth",
        "tictactoe",
        "monks-3",
        "breast_cancer",
        "urinary-d1",
        "iris",
        "urinary-d2",
        "monks-1",
        "divorce",
        "soybean-small",
        "haberman",
        "mammographic_masses",
        "cryotherapy",
        "penguins",
        "occupancy",
        "house-votes",
        "htru",
        "banknote",
        "seeds",
        "mushroom",
        "veichle_E",
        "heart",
        "statlog",
        "diabets", #25
    ]


    results_dict = Dict{String,Vector{Float64}}()

    for dataset in datasets
        println("_________ Dataset: $dataset _________")
        try
            X, y = load_data_hardcoded(dataset, seed = 1) # We can use a dummy value for seed because we use MLJ for real fold analysis.
            # With this function we only want to obtain X, y entirely
            f1_scores = evaluate_random_forest(
                X,
                y,
                n_trees = n_trees,
                max_depth = max_depth,
                n_folds = n_folds,
            )
            print_results(f1_scores)
            results_dict[dataset] = f1_scores
        catch e
            println("Error with dataset $dataset: $e")
            results_dict[dataset] = Float64[]
        end
        println()
    end

    # Save results to CSV
    save_results_to_csv(results_dict, csv_filename)

    return results_dict
end

# Simplified version with balancing - undersample as default
function quick_rf_evaluate(
    X,
    y;
    n_trees = 100,
    max_depth = 3,
    n_folds = 10,
    balance_method = :undersample,
)
    # Automatic conversion
    if isa(X, Matrix)
        X_df = DataFrame(X, [Symbol("feature_$i") for i = 1:size(X, 2)])
    else
        X_df = X
    end

    y_cat = categorical(y)

    # Evaluation with balancing
    f1_scores = evaluate_random_forest_balanced(
        X_df,
        y_cat,
        n_trees = n_trees,
        max_depth = max_depth,
        n_folds = n_folds,
        balance_method = balance_method,
        verbosity = 1,
    )

    println("Average F1 Score: $(mean(f1_scores))")
    println("F1 Score per fold: $f1_scores")

    return f1_scores
end

# Function to compare results with and without balancing
function compare_balanced_vs_unbalanced(X, y; n_trees = 100, max_depth = 3, n_folds = 5)
    println("=== Comparison With/Without Balancing ===")

    # Input validation
    if isempty(y)
        error("Empty dataset")
    end

    # Conversion
    if isa(X, Matrix)
        X_df = DataFrame(X, [Symbol("feature_$i") for i = 1:size(X, 2)])
    else
        X_df = X
    end
    y_cat = categorical(y)

    # Check that there are at least 2 classes
    if length(levels(y_cat)) < 2
        error("At least 2 classes needed for comparison")
    end

    RandomForest = @load RandomForestClassifier pkg=DecisionTree
    if max_depth == -1
        rf_model = RandomForest(n_trees = n_trees)
    else
        rf_model = RandomForest(n_trees = n_trees, max_depth = max_depth)
    end

    # Without balancing (normal stratified CV)
    println("\nWithout balancing:")
    try
        results_normal = evaluate(
            rf_model,
            X_df,
            y_cat,
            resampling = StratifiedCV(nfolds = n_folds),
            measure = macro_f1score,
            verbosity = 0,
        )

        f1_normal = results_normal.per_fold[1]
        println("Average F1: $(mean(f1_normal)) ± $(std(f1_normal))")
    catch e
        println("Error in normal evaluation: $e")
        f1_normal = Float64[]
    end

    # With balancing oversample
    println("\nWith balancing (oversample):")
    try
        f1_balanced = evaluate_random_forest_balanced(
            X_df,
            y_cat,
            n_trees = n_trees,
            max_depth = max_depth,
            n_folds = n_folds,
            balance_method = :oversample,
            verbosity = 0,
        )
        println("Average F1: $(mean(f1_balanced)) ± $(std(f1_balanced))")
    catch e
        println("Error in oversample balancing: $e")
        f1_balanced = Float64[]
    end

    # With balancing undersample
    println("\nWith balancing (undersample):")
    try
        f1_under = evaluate_random_forest_balanced(
            X_df,
            y_cat,
            n_trees = n_trees,
            max_depth = max_depth,
            n_folds = n_folds,
            balance_method = :undersample,
            verbosity = 0,
        )
        println("Average F1: $(mean(f1_under)) ± $(std(f1_under))")
    catch e
        println("Error in undersample balancing: $e")
        f1_under = Float64[]
    end

    return f1_normal, f1_balanced, f1_under
end

# Function to get dataset statistics
function dataset_stats(X, y)
    println("=== Dataset Statistics ===")
    println("Number of samples: $(length(y))")
    println("Number of features: $(size(X, 2))")

    class_counts = countmap(y)
    println("Class distribution:")
    for (class, count) in sort(collect(class_counts))
        percentage = round(count / length(y) * 100, digits = 2)
        println("  $class: $count ($percentage%)")
    end

    # Calculate imbalance ratio
    max_count = maximum(values(class_counts))
    min_count = minimum(values(class_counts))
    imbalance_ratio = max_count / min_count
    println("Imbalance ratio: $(round(imbalance_ratio, digits=2)):1")

    return class_counts
end

# Function to evaluate with progressive number of trees (powers of 2) using proper Decision Tree for n_trees=1
function evaluate_progressive_trees(
    X,
    y;
    max_depth = 3,
    n_folds = 10,
    min_f1_threshold = 0.6,
    balance_method = :undersample,
    verbosity = 1,
)
    # Input validation
    if isempty(y)
        error("Empty dataset")
    end

    # Convert X to DataFrame if not already
    if isa(X, Matrix)
        if size(X, 1) == 0
            error("Empty matrix X")
        end
        n_features = size(X, 2)
        feature_names = [Symbol("feature_$i") for i = 1:n_features]
        X_df = DataFrame(X, feature_names)
    elseif isa(X, DataFrame)
        if nrow(X) == 0
            error("Empty DataFrame X")
        end
        X_df = X
    else
        error("X must be a Matrix or DataFrame")
    end

    # Check dimension consistency
    if nrow(X_df) != length(y)
        error(
            "Number of rows in X ($(nrow(X_df))) different from length of y ($(length(y)))",
        )
    end

    # Convert y to CategoricalArray
    y_cat = categorical(y)

    # Check that there are at least 2 classes
    n_classes = length(levels(y_cat))
    if n_classes < 2
        error("At least 2 classes needed for classification")
    end

    # Powers of 2 from 1 to 64
    tree_counts = [1, 2, 4, 8, 16, 32, 64, 100]

    results = Dict{Int,Vector{Float64}}()

    for n_trees in tree_counts
        if verbosity > 0
            if n_trees == 1
                println("Evaluating with 1 tree (Pure Decision Tree)...")
            else
                println("Evaluating with $n_trees trees (Random Forest)...")
            end
        end

        try
            if n_trees == 1
                # Use pure Decision Tree
                f1_scores = evaluate_decision_tree_balanced(
                    X_df,
                    y_cat,
                    max_depth = max_depth,
                    n_folds = n_folds,
                    balance_method = balance_method,
                    verbosity = 0,
                )
            else
                # Use Random Forest
                f1_scores = evaluate_random_forest_balanced(
                    X_df,
                    y_cat,
                    n_trees = n_trees,
                    max_depth = max_depth,
                    n_folds = n_folds,
                    balance_method = balance_method,
                    verbosity = 0,
                )
            end

            avg_f1 = mean(f1_scores)
            results[n_trees] = f1_scores

            if verbosity > 0
                model_type = n_trees == 1 ? "Decision Tree" : "Random Forest"
                println("  Average F1 Score: $(round(avg_f1, digits=4)) ($model_type)")
                if n_trees == 1
                    println("  ✓ Decision Tree (always saved)")
                elseif avg_f1 >= min_f1_threshold
                    println("  ✓ Above threshold ($(min_f1_threshold))")
                else
                    println("  ✗ Below threshold ($(min_f1_threshold))")
                end
            end

        catch e
            @warn "Error evaluating $n_trees trees: $e"
            results[n_trees] = Float64[]
        end
    end

    return results
end

# Function to evaluate Decision Tree with cross-validation and balancing
function evaluate_decision_tree_balanced(
    X_df,
    y_cat;
    max_depth = 3,
    n_folds = 10,
    balance_method = :undersample,
    verbosity = 1,
)
    # Input validation
    if nrow(X_df) == 0
        error("Empty DataFrame X")
    end

    if length(y_cat) == 0
        error("Empty target vector y")
    end

    # Check dimension consistency
    if nrow(X_df) != length(y_cat)
        error(
            "Number of rows in X ($(nrow(X_df))) different from length of y ($(length(y_cat)))",
        )
    end

    # Check that there are at least 2 classes
    n_classes = length(levels(y_cat))
    if n_classes < 2
        error("At least 2 classes needed for classification")
    end

    # Check that n_folds is reasonable
    if n_folds < 2
        error("n_folds must be at least 2")
    end
    if n_folds > nrow(X_df)
        error(
            "n_folds ($(n_folds)) cannot be greater than number of samples ($(nrow(X_df)))",
        )
    end

    # Load the Decision Tree model
    DecisionTreeClassifier = @load DecisionTreeClassifier pkg=DecisionTree
    if max_depth == -1
        dt_model = DecisionTreeClassifier()
    else
        dt_model = DecisionTreeClassifier(max_depth = max_depth)
    end

    # Create stratified folds
    folds = create_stratified_folds(y_cat, n_folds)

    f1_scores = Float64[]

    for fold = 1:n_folds
        if verbosity > 0
            println("Fold $fold/$n_folds")
        end

        # Create indices for test and train
        test_indices = folds[fold]
        train_indices = setdiff(1:nrow(X_df), test_indices)

        # Check that there are samples in both sets
        if length(train_indices) == 0 || length(test_indices) == 0
            @warn "Fold $fold has empty train or test set, skipping..."
            continue
        end

        # Extract train and test sets
        X_train = X_df[train_indices, :]
        y_train = y_cat[train_indices]
        X_test = X_df[test_indices, :]
        y_test = y_cat[test_indices]

        # Check that train set has at least 2 classes
        train_classes = length(levels(y_train))
        if train_classes < 2
            @warn "Fold $fold has less than 2 classes in training set, skipping..."
            continue
        end

        try
            # Balance the training set
            X_train_balanced, y_train_balanced =
                balance_dataset(X_train, y_train, method = balance_method)

            if verbosity > 1
                println("  Original train distribution: $(countmap(y_train))")
                println("  Balanced train distribution: $(countmap(y_train_balanced))")
            end

            # Train the Decision Tree model
            mach = machine(dt_model, X_train_balanced, y_train_balanced)
            fit!(mach, verbosity = 0)

            # Predictions
            y_pred = predict_mode(mach, X_test)

            # Calculate F1 macro
            f1 = macro_f1score(y_pred, y_test)
            push!(f1_scores, f1)

            if verbosity > 0
                println("  F1 Score: $f1")
            end

        catch e
            @warn "Error in fold $fold: $e"
            continue
        end
    end

    # Check that there are results
    if length(f1_scores) == 0
        error("No fold completed successfully")
    end

    return f1_scores
end

# Function to save progressive results to CSV (always save n_trees=1, others only if >= threshold)
function save_progressive_results_to_csv(
    results_dict,
    dataset_name;
    min_f1_threshold = 0.6,
    filename = "progressive_trees_results.csv",
)
    # Create DataFrame for results
    results_df = DataFrame(
        Dataset = String[],
        NumTrees = Int[],
        ModelType = String[],
        AvgF1Score = Float64[],
        StdF1Score = Float64[],
        MinF1Score = Float64[],
        MaxF1Score = Float64[],
    )

    for (n_trees, f1_scores) in sort(collect(results_dict))
        if length(f1_scores) > 0
            avg_f1 = mean(f1_scores)
            model_type = n_trees == 1 ? "DecisionTree" : "RandomForest"

            # Always add if n_trees = 1 (Decision Tree) OR if average F1 >= threshold
            if n_trees == 1 || avg_f1 >= min_f1_threshold
                push!(
                    results_df,
                    (
                        dataset_name,
                        n_trees,
                        model_type,
                        avg_f1,
                        std(f1_scores),
                        minimum(f1_scores),
                        maximum(f1_scores),
                    ),
                )
            end
        end
    end

    # Only save if there are results above threshold OR Decision Tree results
    if nrow(results_df) > 0
        # Check if file exists to append or create
        if isfile(filename)
            # Read existing data and append
            existing_df = CSV.read(filename, DataFrame)
            combined_df = vcat(existing_df, results_df)
            CSV.write(filename, combined_df)
            println("Results appended to $filename")
        else
            # Create new file
            CSV.write(filename, results_df)
            println("Results saved to $filename")
        end

        return results_df
    else
        println(
            "No results above threshold ($(min_f1_threshold)) and no Decision Tree results for dataset: $dataset_name",
        )
        return DataFrame()
    end
end

# Function to run progressive evaluation on all datasets
function main_progressive_usage(;
    max_depth = 3,
    n_folds = 10,
    min_f1_threshold = 0.0,
    csv_filename = "progressive_trees_results.csv",
)
    datasets = [
        "lenses",
        "veichle_I",
        "ecoli",
        "yeast",
        "veichle_H",
        "veichle_F",
        "tae",
        "post-operative",
        "veichle_A",
        "veichle_G",
        "veichle_B",
        "glass",
        "monks-2",
        "bean",
        "balance-scale",
        "cmc",
        "lymphography",
        "primary-tumor",
        "veichle_C",  #19
        "car",
        "hayes-roth",
        "tictactoe",
        "monks-3",
        "breast_cancer",
        "urinary-d1",
        "iris",
        "urinary-d2",
        "monks-1",
        "divorce",
        "soybean-small",
        "haberman",
        "mammographic_masses",
        "cryotherapy",
        "penguins",
        "occupancy",
        "house-votes",
        "htru",
        "banknote",
        "seeds",
        "mushroom",
        "veichle_E",
        "heart",
        "statlog",
        "diabets", #25
    ]

    # Clear existing file if it exists
    if isfile(csv_filename)
        rm(csv_filename)
        println("Cleared existing results file: $csv_filename")
    end

    total_datasets_processed = 0

    for dataset in datasets
        println("=" ^ 60)
        println("Dataset: $dataset")
        println("=" ^ 60)

        try
            X, y = load_data_hardcoded(dataset, seed = 1)  # We can use a dummy value for seed because we use MLJ for real fold analysis.
            # With this function we only want to obtain X, y entirely
            # Show dataset statistics
            class_counts = countmap(y)
            println("Dataset size: $(size(X, 1)) samples, $(size(X, 2)) features")
            println("Class distribution: $class_counts")

            # Calculate imbalance ratio
            max_count = maximum(values(class_counts))
            min_count = minimum(values(class_counts))
            imbalance_ratio = max_count / min_count
            println("Imbalance ratio: $(round(imbalance_ratio, digits=2)):1")

            # Evaluate with progressive trees
            results = evaluate_progressive_trees(
                X,
                y,
                max_depth = max_depth,
                n_folds = n_folds,
                min_f1_threshold = min_f1_threshold,
            )

            # Save results
            saved_df = save_progressive_results_to_csv(
                results,
                dataset,
                min_f1_threshold = min_f1_threshold,
                filename = csv_filename,
            )

            if nrow(saved_df) > 0
                total_datasets_processed += 1
                dt_results = saved_df[saved_df.NumTrees .== 1, :]
                rf_results = saved_df[saved_df.NumTrees .> 1, :]

                println("\n RESULTS SUMMARY for $dataset:")
                if nrow(dt_results) > 0
                    println(
                        "  Decision Tree: F1 = $(round(dt_results.AvgF1Score[1], digits=4))",
                    )
                end
                if nrow(rf_results) > 0
                    println(
                        "  Random Forest: $(nrow(rf_results)) configurations above threshold",
                    )
                    for i = 1:nrow(rf_results)
                        trees = rf_results.NumTrees[i]
                        f1 = rf_results.AvgF1Score[i]
                        println("    - $trees trees: F1 = $(round(f1, digits=4))")
                    end
                end
            else
                println("❌ Dataset $dataset: No results saved")
            end

        catch e
            println("❌ Error with dataset $dataset: $e")
        end

        println()
    end

    println("=" ^ 60)
    println(" FINAL SUMMARY")
    println("=" ^ 60)
    println("Total datasets processed: $total_datasets_processed/$(length(datasets))")

    if isfile(csv_filename)
        final_df = CSV.read(csv_filename, DataFrame)
        println("Total configurations saved: $(nrow(final_df))")
        println("Results saved in: $csv_filename")

        # Show detailed summary statistics
        if nrow(final_df) > 0
            println("\n DETAILED SUMMARY:")

            # Decision Tree results
            dt_results = final_df[final_df.ModelType .== "DecisionTree", :]
            if nrow(dt_results) > 0
                avg_dt_f1 = mean(dt_results.AvgF1Score)
                println("  Decision Tree:")
                println("    - Datasets: $(nrow(dt_results))")
                println("    - Average F1: $(round(avg_dt_f1, digits=4))")
                println("    - Best F1: $(round(maximum(dt_results.AvgF1Score), digits=4))")
                println(
                    "    - Worst F1: $(round(minimum(dt_results.AvgF1Score), digits=4))",
                )
            end

            # Random Forest results
            rf_results = final_df[final_df.ModelType .== "RandomForest", :]
            if nrow(rf_results) > 0
                println("  Random Forest:")
                for n_trees in sort(unique(rf_results.NumTrees))
                    subset = rf_results[rf_results.NumTrees .== n_trees, :]
                    avg_f1 = mean(subset.AvgF1Score)
                    println(
                        "    - $n_trees trees: $(nrow(subset)) datasets, avg F1 = $(round(avg_f1, digits=4))",
                    )
                end
            end

            # Overall best performers
            println("\n TOP PERFORMERS:")
            sorted_results = sort(final_df, :AvgF1Score, rev = true)
            for i = 1:min(5, nrow(sorted_results))
                row = sorted_results[i, :]
                println(
                    "    $i. $(row.Dataset) ($(row.ModelType), $(row.NumTrees) trees): F1 = $(round(row.AvgF1Score, digits=4))",
                )
            end
        end
    else
        println("❌ No results file created - no datasets processed successfully")
    end

    return csv_filename
end

main_usage(
    n_trees = 100,
    max_depth = 3,
    n_folds = 10,
    csv_filename = "rf_FINAL_results.csv",
)
main_progressive_usage(
    min_f1_threshold = 0.0,
    csv_filename = "progressive_FINAL_trees_0percent.csv",
)
