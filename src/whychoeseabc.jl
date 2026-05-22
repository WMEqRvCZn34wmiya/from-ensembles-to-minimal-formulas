using Pkg
Pkg.activate(".")
using Revise
using DataFrames
using ComplexityMeasures
using DecisionTree
using Statistics

# Include all files at the beginning to avoid world age problems
include("utilsForTest.jl")
include("suitfortest.jl")
include("apiIntrees.jl")
include("apiRefne.jl")


datasets = [
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
    "diabets",
]

minimization_schemes = [:mitespresso, :abc, :abc_balanced, :abc_thorough]

# Dictionary to store all results for averaging
all_results = Dict()

# Initialize the results dictionary
for dataset in datasets
    all_results[dataset] = Dict()
end

for dataset in datasets
    for randomseed in [153, 2025, 2, 987654321, 5555, 789987, 98529, 7, 2806, 1548]
        for m in minimization_schemes
            println(
                "\n\n$COLORED_ULTRA_OTT$TITLE\n ADDESTRAMENTO ALBERO $dataset (seed: $randomseed, minimization: $m) \n$TITLE$RESET",
            )

            if (dataset in ["car", "hayes-roth"])
                f,
                model,
                start_time,
                features_train,
                labels_train,
                features_test,
                labels_test,
                features,
                labels = learn_and_convert(32, dataset, 3, randomseed)
            elseif (dataset in ["tictactoe", "monks-3"])
                f,
                model,
                start_time,
                features_train,
                labels_train,
                features_test,
                labels_test,
                features,
                labels = learn_and_convert(16, dataset, 3, randomseed)
            elseif (
                dataset in ["breast_cancer", "urinary-d1", "iris", "urinary-d2", "monks-1"]
            )
                f,
                model,
                start_time,
                features_train,
                labels_train,
                features_test,
                labels_test,
                features,
                labels = learn_and_convert(8, dataset, 3, randomseed)
            elseif (
                dataset in [
                    "divorce",
                    "soybean-small",
                    "haberman",
                    "mammographic_masses",
                    "cryotherapy",
                    "penguins",
                    "occupancy",
                    "veichle_E",
                    "heart",
                    "statlog",
                    "seeds",
                    "banknote",
                ]
            )
                f,
                model,
                start_time,
                features_train,
                labels_train,
                features_test,
                labels_test,
                features,
                labels = learn_and_convert(4, dataset, 3, randomseed)
            elseif (dataset in ["diabets", "mushroom", "htru", "house-votes"])
                f,
                model,
                start_time,
                features_train,
                labels_train,
                features_test,
                labels_test,
                features,
                labels = learn_and_convert(2, dataset, 3, randomseed)
            end

            accuracy = calculate_forest_accuracy(f, features_test, labels_test)
            println("Model accuracy: $(round(accuracy * 100, digits=2))%")

            println(
                "importance vector:",
                create_importance_vector(impurity_importance(model)),
            )

            #======================================================================================================================================
                                                                    LUMEN
            ======================================================================================================================================#
            println(
                "\n\n$COLORED_ULTRA_OTT$TITLE\n LUMEN (minimization: $m) \n$TITLE$RESET",
            )

            timelumen = @elapsed begin
                result = lumen(
                    model;
                    ott_mode=true,
                    controllo=false,
                    silent=true,
                    apply_function=apply_forest,
                    vetImportance=create_importance_vector(impurity_importance(model)),
                    minimization_scheme=m,
                )
                dslumen = result.decision_set
                Lumeninfo = result.info
            end

            println("Running time: $timelumen seconds")

            #======================================================================================================================================
                                                                    Evaluate all DS
            ======================================================================================================================================#
            algorithm_name = "Lumen_$(m)"
            algorithms = [(algorithm_name, dslumen, timelumen, m),]

            # Prepare test data
            X, y = begin
                features_test = float.(features_test)
                labels_test = string.(labels_test)
                features_test, labels_test
            end

            # Create logiset from test features
            logiset = scalarlogiset(
                DataFrame(X, ["V$(i)" for i = 1:size(X, 2)]);
                allow_propositional=true,
            )

            # Predict
            y_pred = apply(
                f,
                SoleData.scalarlogiset(
                    DataFrame(features_test, :auto);
                    allow_propositional=true,
                ),
            )

            # Store results for each algorithm
            for (name, algorithm, exec_time, min_scheme) in algorithms
                # Calculate DecisionSet accuracy
                decisionset_accuracy =
                    calculate_decisionset_accuracy(algorithm, features_test, labels_test)

                # Evaluate rules
                rule_evaluations = map(
                    r -> SoleModels.evaluaterule(
                        r,
                        logiset,
                        y_pred,
                        compute_explanations=true,
                    ),
                    SoleModels.rules(algorithm),
                )
                num_terms = nterm(rules(algorithm))

                # Initialize algorithm results if not exists
                if !haskey(all_results[dataset], name)
                    all_results[dataset][name] = Dict()
                end

                # Store results for each rule
                for (rule_id, eval) in enumerate(rule_evaluations)
                    # Get rule identifier
                    rule = SoleModels.rules(algorithm)[rule_id]
                    rule_idd = strip(
                        replace(
                            string(consequent(SoleModels.rules(algorithm)[rule_id])),
                            r"\x1B\[[0-9;]*[a-zA-Z]|▣|\n" => "",
                        ),
                    )

                    # Initialize rule results if not exists
                    if !haskey(all_results[dataset][name], rule_idd)
                        all_results[dataset][name][rule_idd] = Dict(
                            "num_terms" => Any[],
                            "exec_time" => Float64[],
                            "sensitivity" => Float64[],
                            "specificity" => Float64[],
                            "min_avg" => Float64[],
                            "min_std" => Float64[],
                            "max_avg" => Float64[],
                            "avg_avg" => Float64[],
                            "std_avg" => Float64[],
                            "num_atoms" => Any[],
                            "decisionset_accuracy" => Float64[],
                            "rule_f1_score" => Float64[],
                            "minimization_scheme" => Symbol[],
                        )
                    end

                    # Extract sensitivity and specificity
                    sensitivity = eval.sensitivity
                    specificity = eval.specificity

                    # Calculate F1 score for this specific rule
                    rule_f1_score = calculate_rule_f1_score(eval, rule, labels_test)

                    # Calculate explanation statistics
                    min_avg = 0.0
                    min_std = 0.0
                    max_avg = 0.0
                    avg_avg = 0.0
                    std_avg = 0.0

                    natoms_expl = map(
                        expls -> let
                            x = Float64[natoms(e) for e in expls]
                            length(unique(x)) == 1 ?
                            (minimum(x), maximum(x), mean(x), 0.0) :
                            (minimum(x), maximum(x), mean(x), std(x))
                        end,
                        filter(!isempty, eval.explanations),
                    )

                    if !isempty(natoms_expl)
                        min_avg = StatsBase.mean(Float64[x[1] for x in natoms_expl])
                        min_std = StatsBase.std(Float64[x[1] for x in natoms_expl])
                        max_avg = StatsBase.mean(Float64[x[2] for x in natoms_expl])
                        avg_avg = StatsBase.mean(Float64[x[3] for x in natoms_expl])
                        std_avg = StatsBase.mean(Float64[x[4] for x in natoms_expl])
                    end

                    # Calculate number of atoms in the rule's antecedent
                    num_atoms = natoms(antecedent(rule))

                    # Store num_terms
                    if isa(num_terms, Number)
                        push!(
                            all_results[dataset][name][rule_idd]["num_terms"],
                            Float64(num_terms),
                        )
                    else
                        push!(all_results[dataset][name][rule_idd]["num_terms"], num_terms)
                    end

                    # Store scalar metrics
                    push!(
                        all_results[dataset][name][rule_idd]["exec_time"],
                        Float64(exec_time),
                    )
                    push!(
                        all_results[dataset][name][rule_idd]["sensitivity"],
                        Float64(sensitivity),
                    )
                    push!(
                        all_results[dataset][name][rule_idd]["specificity"],
                        Float64(specificity),
                    )
                    push!(all_results[dataset][name][rule_idd]["min_avg"], Float64(min_avg))
                    push!(all_results[dataset][name][rule_idd]["min_std"], Float64(min_std))
                    push!(all_results[dataset][name][rule_idd]["max_avg"], Float64(max_avg))
                    push!(all_results[dataset][name][rule_idd]["avg_avg"], Float64(avg_avg))
                    push!(all_results[dataset][name][rule_idd]["std_avg"], Float64(std_avg))
                    push!(
                        all_results[dataset][name][rule_idd]["decisionset_accuracy"],
                        Float64(decisionset_accuracy),
                    )
                    push!(
                        all_results[dataset][name][rule_idd]["rule_f1_score"],
                        Float64(rule_f1_score),
                    )
                    push!(
                        all_results[dataset][name][rule_idd]["minimization_scheme"],
                        min_scheme,
                    )

                    # Store num_atoms
                    if isa(num_atoms, Number)
                        push!(
                            all_results[dataset][name][rule_idd]["num_atoms"],
                            Float64(num_atoms),
                        )
                    else
                        push!(all_results[dataset][name][rule_idd]["num_atoms"], num_atoms)
                    end
                end
            end
        end
    end
end

# Write results to CSV
open("whyabc.csv", "w") do csv_file
    println(
        csv_file,
        "Dataset,Algorithm,Minimization_Scheme,AVGExecution_Time,Rule_ID,AVGSensitivity,AVGSpecificity,AVGMin_Avg,AVGMin_Std,AVGMaximum,AVGAverage,AVGStd_Dev,AVGNumAtoms,AVGDecisionSetAccuracy,AVGRuleF1Score",
    )

    for dataset in datasets
        if haskey(all_results, dataset)
            for (algorithm_name, algorithm_results) in all_results[dataset]
                for (rule_id, metrics) in algorithm_results
                    # Calculate averages for each metric
                    avg_num_terms = if all(isa(x, Number) for x in metrics["num_terms"])
                        mean(metrics["num_terms"])
                    else
                        if length(metrics["num_terms"]) > 0
                            first_val = metrics["num_terms"][1]
                            if isa(first_val, Number)
                                mean(metrics["num_terms"])
                            else
                                "[$(join(first_val, ","))]"
                            end
                        else
                            0.0
                        end
                    end

                    avg_exec_time = mean(metrics["exec_time"])
                    avg_sensitivity = mean(metrics["sensitivity"])
                    avg_specificity = mean(metrics["specificity"])
                    avg_min_avg = mean(metrics["min_avg"])
                    avg_min_std = mean(metrics["min_std"])
                    avg_max_avg = mean(metrics["max_avg"])
                    avg_avg_avg = mean(metrics["avg_avg"])
                    avg_std_avg = mean(metrics["std_avg"])
                    avg_decisionset_accuracy = mean(metrics["decisionset_accuracy"])
                    avg_rule_f1_score = mean(metrics["rule_f1_score"])

                    # Get minimization scheme (should be the same for all entries)
                    min_scheme = metrics["minimization_scheme"][1]

                    avg_num_atoms = if all(isa(x, Number) for x in metrics["num_atoms"])
                        mean(metrics["num_atoms"])
                    else
                        if length(metrics["num_atoms"]) > 0
                            first_val = metrics["num_atoms"][1]
                            if isa(first_val, Number)
                                mean(metrics["num_atoms"])
                            else
                                "[$(join(first_val, ","))]"
                            end
                        else
                            0.0
                        end
                    end

                    println(
                        csv_file,
                        "$dataset,$algorithm_name,$min_scheme,$avg_exec_time,$rule_id,$avg_sensitivity,$avg_specificity,$avg_min_avg,$avg_min_std,$avg_max_avg,$avg_avg_avg,$avg_std_avg,$avg_num_atoms,$avg_decisionset_accuracy,$avg_rule_f1_score",
                    )
                end
            end
        end
    end
end
