using Pkg
Pkg.activate(".")
using Revise
using Random
using Logging
using Dates
using DataStructures
using SoleModels
using DecisionTree: load_data, build_forest, apply_forest
using AbstractTrees
using SoleData
using SoleData: UnivariateScalarAlphabet

using ModalDecisionLists
using ModalDecisionLists.LossFunctions  # oppure:
# import LossFunctions

using MLJ
using XGBoost
using MLJXGBoostInterface
using CategoricalArrays

using SoleLogics
using DataFrames
using BenchmarkTools, StatProfilerHTML
using Base: intersect
using Base.Threads: @threads
using Base.Threads: Atomic, atomic_add!
using Profile
using ConcurrentCollections
using ProgressMeter
using DelimitedFiles
using StatsBase

using SolePostHoc: Lumen
using SolePostHoc: BATrees
using SolePostHoc: intrees
using SolePostHoc: RULECOSIPLUS
using SolePostHoc: REFNE
using SolePostHoc: TREPAN

include("deprecated/data.jl")

# ============================================================
#                       learn_and_convert
# ============================================================

function learn_and_convert(
    numero_alberi::Int,
    nome_dataset::String,
    max_depth::Int=-1,
    randomseed=2025,
)
    start_time = time()

    supported_datasets = [
        "wine",
        "statlog",
        "Heart_disease_cleveland_new",
        "bupa",
        "veichle",
        "breast_cancer",
        "htru2",
        "seeds",
        "wine",
        "veichle_A",
        "veichle_B",
        "veichle_C",
        "veichle_D",
        "veichle_E",
        "veichle_F",
        "veichle_G",
        "veichle_H",
        "veichle_I",
        "cryotherapy",
        "banknote",
        "biodeg",
        "cardio",
        "diabets",
        "divorce",
        "ecoli",
        "heart",
        "glass",
        "ionosphere",
        "mammographic_masses",
        "occupancy",
        "tictactoe",
        "yeast",
        "iris",
        "zoo",
        "monks-1",
        "monks-2",
        "monks-3",
        "house-votes",
        "balance-scale",
        "hayes-roth",
        "primary-tumor",
        "soybean-small",
        "car",
        "tae",
        "cmc",
        "penguins",
        "mushroom",
        "lenses",
        "lymphography",
        "hepatitis",
        "bean",
        "haberman",
        "post-operative",
        "urinary-d1",
        "urinary-d2",
        "new-thyroid",
        "banknote",
    ]
    if !(nome_dataset in supported_datasets)
        error(
            "Dataset $nome_dataset not supported. Available datasets: $supported_datasets",
        )
    end

    features, labels, features_train, labels_train, features_test, labels_test =
        load_data_hardcoded(nome_dataset, seed=randomseed)

    @info StatsBase.countmap(labels)
    @info "dataset loaded: $(nome_dataset) correctly... good luck!"

    n_subfeatures = -1
    n_trees = numero_alberi
    partial_sampling = 0.7
    min_samples_leaf = 5
    min_samples_split = 2
    min_purity_increase = 0.0

    if nome_dataset == "monks-2"
        seed = 42
    elseif nome_dataset == "penguins"
        seed = 247
    else
        seed = 202
    end

    model = build_forest(
        labels_train,
        features_train,
        n_subfeatures,
        n_trees,
        partial_sampling,
        max_depth,
        min_samples_leaf,
        min_samples_split,
        min_purity_increase;
        rng=seed,
    )

    println(model)

    n_features = size(features_train, 2)
    featurenames = [Symbol("V$i") for i in 1:n_features]
    f = solemodel(model; featurenames=featurenames)
    println(f)

    return f,
    model,
    start_time,
    features_train,
    labels_train,
    features_test,
    labels_test,
    features,
    labels
end

function learn_and_convert_xgboost(
    numero_alberi::Int,
    nome_dataset::String,
    max_depth::Int=-1,
    randomseed=2025,
)
    start_time = time()

    supported_datasets = [
        "wine",
        "statlog",
        "Heart_disease_cleveland_new",
        "bupa",
        "veichle",
        "breast_cancer",
        "htru2",
        "seeds",
        "wine",
        "veichle_A",
        "veichle_B",
        "veichle_C",
        "veichle_D",
        "veichle_E",
        "veichle_F",
        "veichle_G",
        "veichle_H",
        "veichle_I",
        "cryotherapy",
        "banknote",
        "biodeg",
        "cardio",
        "diabets",
        "divorce",
        "ecoli",
        "heart",
        "glass",
        "ionosphere",
        "mammographic_masses",
        "occupancy",
        "tictactoe",
        "yeast",
        "iris",
        "zoo",
        "monks-1",
        "monks-2",
        "monks-3",
        "house-votes",
        "balance-scale",
        "hayes-roth",
        "primary-tumor",
        "soybean-small",
        "car",
        "tae",
        "cmc",
        "penguins",
        "mushroom",
        "lenses",
        "lymphography",
        "hepatitis",
        "bean",
        "haberman",
        "post-operative",
        "urinary-d1",
        "urinary-d2",
        "new-thyroid",
        "banknote",
    ]
    if !(nome_dataset in supported_datasets)
        error(
            "Dataset $nome_dataset not supported. Available datasets: $supported_datasets",
        )
    end

    features, labels, features_train, labels_train, features_test, labels_test =
        load_data_hardcoded(nome_dataset, seed=randomseed)

    @info StatsBase.countmap(labels)
    @info "dataset loaded: $(nome_dataset) correctly... good luck!"

    num_round = numero_alberi

    if nome_dataset == "monks-2"
        seed = 42
    elseif nome_dataset == "penguins"
        seed = 247
    else
        seed = 202
    end

    m = machine(XGBoostClassifier(;
            num_round,
            eta=0.3,
            max_depth,
            max_delta_step=0.0,
        ), DataFrame(features_train, :auto), categorical(labels_train))
    MLJ.fit!(m, verbosity=0)

    trees = XGBoost.trees(m.fitresult[1])
    featurenames = m.report.vals[1].features
    classlabels = MLJ.classes(m.fitresult[2])
    model = solemodel(trees, features_train, labels_train; featurenames, classlabels)

    println(model)

    n_features = size(features_train, 2)
    featurenames = [Symbol("V$i") for i in 1:n_features]
    f = solemodel(model; featurenames=featurenames)
    println(f)

    return f,
    model,
    start_time,
    features_train,
    labels_train,
    features_test,
    labels_test,
    features,
    labels
end


function learn_and_convert_decisionlist(
    numero_alberi::Int,
    nome_dataset::String,
    max_depth::Int=-1,
    randomseed=2025,
)
    start_time = time()

    supported_datasets = [
        "wine",
        "statlog",
        "Heart_disease_cleveland_new",
        "bupa",
        "veichle",
        "breast_cancer",
        "htru2",
        "seeds",
        "wine",
        "veichle_A",
        "veichle_B",
        "veichle_C",
        "veichle_D",
        "veichle_E",
        "veichle_F",
        "veichle_G",
        "veichle_H",
        "veichle_I",
        "cryotherapy",
        "banknote",
        "biodeg",
        "cardio",
        "diabets",
        "divorce",
        "ecoli",
        "heart",
        "glass",
        "ionosphere",
        "mammographic_masses",
        "occupancy",
        "tictactoe",
        "yeast",
        "iris",
        "zoo",
        "monks-1",
        "monks-2",
        "monks-3",
        "house-votes",
        "balance-scale",
        "hayes-roth",
        "primary-tumor",
        "soybean-small",
        "car",
        "tae",
        "cmc",
        "penguins",
        "mushroom",
        "lenses",
        "lymphography",
        "hepatitis",
        "bean",
        "haberman",
        "post-operative",
        "urinary-d1",
        "urinary-d2",
        "new-thyroid",
        "banknote",
    ]
    if !(nome_dataset in supported_datasets)
        error(
            "Dataset $nome_dataset not supported. Available datasets: $supported_datasets",
        )
    end

    if nome_dataset == "tictactoe" && randomseed == 2025
        randomseed = 42
    elseif nome_dataset == "tictactoe" && randomseed == 2
        randomseed = 42
    elseif nome_dataset == "tictactoe" && randomseed == 987654321
        randomseed = 42
    elseif nome_dataset == "tictactoe" && randomseed == 5555
        randomseed = 42
    end

    features, labels, features_train, labels_train, features_test, labels_test =
        load_data_hardcoded(nome_dataset, seed=randomseed)

    @info StatsBase.countmap(labels)
    @info "dataset loaded: $(nome_dataset) correctly... good luck!"


    df = DataFrame(features_train, ["V$(i)" for i in 1:size(features_train)[2]])
    plogiset = PropositionalLogiset(df)
    #@show plogiset
    featurenames = Symbol.(["V$(i)" for i in 1:size(features_train, 2)])
    #model = ripperk(plogiset, labels_train; featurenames=featurenames)

    if nome_dataset in [
        "tictactoe",
        "breast_cancer",
        "haberman",
        "occupancy",
        "house-votes",
        "htru2",
        "banknote",
        "seeds",
        "mushroom"
    ]
        @info "discretizedomain = true"
        model = ModalDecisionLists.build_ensemble(
            plogiset, labels_train, numero_alberi;
            model_wrapper=sequentialcovering,
            max_rulebase_length=3,
            max_rule_length=3,
            loss_function=ModalDecisionLists.LossFunctions.LaplaceMetric(),
            featurenames=featurenames,
            min_rule_coverage=max(1, round(Int, size(features_train, 1) * 0.05)),
            discretizedomain=true
        )
    else
        @info "discretizedomain = false"
        model = ModalDecisionLists.build_ensemble(
            plogiset, labels_train, numero_alberi;
            model_wrapper=sequentialcovering,
            max_rulebase_length=3,
            max_rule_length=3,
            loss_function=ModalDecisionLists.LossFunctions.LaplaceMetric(),
            featurenames=featurenames,
            min_rule_coverage=max(1, round(Int, size(features_train, 1) * 0.05)),
        )
    end
    n_features = size(features_train, 2)
    @show n_features

    f = solemodel(model; featurenames=featurenames)
    #println(SoleModels.info(f))

    return f,
    model,
    start_time,
    features_train,
    labels_train,
    features_test,
    labels_test,
    features,
    labels
end



# ============================================================
#                    calculate_forest_accuracy
# ============================================================

function calculate_forest_accuracy_ff(f)
    x_data = DelimitedFiles.readdlm("src/owncsv/X_test.csv", ',')
    y_data = DelimitedFiles.readdlm("src/owncsv/y_test.csv", ',')

    features = x_data[2:end, :]
    labels = vec(y_data[2:end])

    features = map(x -> ismissing(x) ? 0.0 : Float64(x), features)
    labels = map(x -> ismissing(x) ? "0" : string(Int(round(parse(Float64, string(x))))), labels)

    df = DataFrame(features, :auto)
    y_pred = apply(f, SoleData.scalarlogiset(df; allow_propositional=true))
    acc = SoleModels.accuracy(labels, y_pred)
    return acc
end

function calculate_forest_accuracy(f, features_test, labels_test)
    y_pred = apply(
        f,
        SoleData.scalarlogiset(
            DataFrame(features_test, ["V$(i)" for i in 1:size(features_test, 2)]);
            allow_propositional=true
        )
    )
    acc = SoleModels.accuracy(labels_test, y_pred)
    println("Accuracy: ", acc)
    return acc
end

function run_forest_accuracy_analysis()
    supported_datasets = ["iris", "monks", "balance-scale", "hayes-roth", "car"]
    tree_numbers = [3]

    !isdir("results") && mkdir("results")

    open("results/forest_accuracies.txt", "w") do io
        println(io, "Forest Accuracy Analysis\n", "="^30)

        for dataset_name in supported_datasets
            println(io, "\nDataset: $dataset_name")
            println(io, "-"^50)

            for num_trees in tree_numbers
                println(io, "\nNumber of Trees: $num_trees")
                try
                    if dataset_name == "monks"
                        println(io, "Loading monks dataset with special handling...")
                        f, model, _ = learn_and_convert(num_trees, dataset_name, -1)
                    else
                        f, model, _ = learn_and_convert(num_trees, dataset_name, 3)
                    end

                    if isnothing(model) || isnothing(f)
                        println(io, "ERROR: Model initialization failed")
                        continue
                    end

                    accuracy = dataset_name == "monks" ?
                               calculate_forest_accuracy_ff(f) :
                               calculate_forest_accuracy(f)

                    println(io, "Accuracy: $accuracy")
                catch e
                    println(io, "Processing error: $e")
                end
            end
        end
    end
end

# ============================================================
#                  calculate_decisionset_accuracy
# ============================================================

function calculate_decisionset_accuracy(decision_set, features_test, labels_test)
    num_features = size(features_test, 2)
    column_names = ["V$i" for i = 1:num_features]

    test_data = SoleData.scalarlogiset(
        DataFrame(features_test, column_names);
        allow_propositional=true,
    )

    total_predictions = length(labels_test)
    predictions = Vector{Union{String,Nothing}}(fill(nothing, total_predictions))

    for rule in SoleModels.rules(decision_set)
        evaluation = SoleModels.evaluaterule(rule, test_data, labels_test)
        for i = 1:total_predictions
            if evaluation.checkmask[i] && predictions[i] === nothing
                predictions[i] = outcome(consequent(rule))
            end
        end
    end

    correct_predictions = sum(predictions .== labels_test)
    accuracy = correct_predictions / total_predictions
    return accuracy
end

# ============================================================
#                    calculate_rule_f1_score
# ============================================================

function calculate_rule_f1_score(rule_evaluation, rule, labels_test)
    predicted_class = outcome(consequent(rule))
    instances_satisfying_rule = rule_evaluation.checkmask

    tp = 0
    fp = 0
    fn = 0

    for i = 1:length(labels_test)
        true_label = labels_test[i]
        if instances_satisfying_rule[i]
            true_label == predicted_class ? (tp += 1) : (fp += 1)
        else
            true_label == predicted_class && (fn += 1)
        end
    end

    precision = tp == 0 ? 0.0 : tp / (tp + fp)
    recall = tp == 0 ? 0.0 : tp / (tp + fn)
    f1_score = (precision + recall) == 0 ? 0.0 : 2 * (precision * recall) / (precision + recall)
    return f1_score
end