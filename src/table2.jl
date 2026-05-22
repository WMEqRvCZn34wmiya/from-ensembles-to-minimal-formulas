using Pkg
Pkg.activate(".")
using Revise
using DataFrames
using ComplexityMeasures
using DecisionTree
using Statistics
using SolePostHoc: InTreesRuleExtractor

# Include all files at the beginning to avoid world age problems
include("utilsForTest.jl")
include("suitfortest.jl")
include("apiIntrees.jl")
include("apiRefne.jl")


datasets = [
    "car",                 #
    "hayes-roth",          #
    "tictactoe",           #
    "monks-3",             #
    "breast_cancer",       #
    "urinary-d1",          #
    "iris",                #
    "urinary-d2",          #
    "monks-1",             #
    "divorce",             #
    "soybean-small",       #
    "haberman",            #
    "mammographic_masses", #
    "cryotherapy",         #
    "penguins",            #
    "occupancy",           # 
    "house-votes",         # 
    "htru2",               # 
    "banknote",            #
    "seeds",               #
    "mushroom",            #
    "diabets",             #
]

# Dataset-specific REFNE configurations: (L, max_depth, ott_mode)
const REFNE_CONFIGS = Dict(
    "divorce" => (L=2, max_depth=3, ott_mode=true),
    "house-votes" => (L=2, max_depth=3, ott_mode=true),
    "mushroom" => (L=2, max_depth=3, ott_mode=true),
    "soybean-small" => (L=2, max_depth=3, ott_mode=true),
    "breast_cancer" => (L=3, max_depth=5, ott_mode=true),
    "urinary-d1" => (L=2, max_depth=10000, ott_mode=true),
    "tictactoe" => (L=2, max_depth=10000, ott_mode=true),
    "htru2" => (L=2, max_depth=10000, ott_mode=true),
    "monks-1" => (L=2, max_depth=10000, ott_mode=true),
    "seeds" => (L=2, max_depth=10000, ott_mode=true),
    "statlog" => (L=2, max_depth=10000, ott_mode=true),
    "veichle_E" => (L=2, max_depth=10000, ott_mode=true),
    "heart" => (L=2, max_depth=10000, ott_mode=true),
    "monks-2" => (L=4, max_depth=10000, ott_mode=false),
)
const DEFAULT_REFNE_CONFIG = (L=3, max_depth=10000, ott_mode=false)

# Dataset-specific TREPAN max_depth (default: 6)
const TREPAN_MAX_DEPTH = Dict("tictactoe" => 4, "mammographic_masses" => 4)

# Dictionary to store all results for averaging
all_results = Dict()

# Initialize the results dictionary
for dataset in datasets
    all_results[dataset] = Dict()
end

for dataset in datasets

    # We hardcoded randomseed (rng) for more reproducibility, if we use only one
    # seed we can't try a single dataset, and in Julia we guarantee only the first generation
    # number for seed, we choose it for dates, or randomly, maybe one or more of those
    # helps enemy and not me ! lol
    for randomseed in [153, 2025, 2, 987654321, 5555, 789987, 98529, 7, 2806, 1548]
        println(
            "\n\n\n ADDESTRAMENTO ALBERO $dataset (seed: $randomseed) \n",
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
        elseif (dataset in ["breast_cancer", "urinary-d1", "iris", "urinary-d2", "monks-1"])
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
        elseif (dataset in ["diabets", "mushroom", "htru2", "house-votes"])
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

        println("importance vector:", create_importance_vector(impurity_importance(model)))

        #======================================================================================================================================
                                                                LUMEN
        ======================================================================================================================================#
        println("\n\n\n LUMEN con seed: $randomseed\n")

        timelumen = @elapsed begin
            dslumen = Lumen.lumen(
                f;
                #vertical=1.0,
                #horizontal=1.0,
                #ott_mode=true,
                #controllo=false,
                #silent=true,
                #apply_function=apply_forest,
                #vetImportance=create_importance_vector(impurity_importance(model)),
                #aggiungi altre keyword SOLO se sono campi di LumenConfig!
            )
        end

        println(dslumen)
        println("Running time: $timelumen seconds")


        #======================================================================================================================================
                                                                      BATREES
        ======================================================================================================================================#
        println("\n\n\n BATREES \n")

        timebatrees = @elapsed begin
            dsbatrees = BATrees.batrees(f)
        end

        println(dsbatrees)
        println("Running time: $timebatrees seconds")

        #======================================================================================================================================
                                                                INTREES
        ======================================================================================================================================#
        println("\n\n\n INTREES \n")

        x = features_train
        y = labels_train

        # Use "V1"..."Vn" column names to match feature names in the model
        X = SoleData.scalarlogiset(
            DataFrame(x, ["V$(i)" for i in 1:size(x, 2)]);
            allow_propositional=true
        )

        timeintrees = @elapsed begin
            # Determina max_rules in base al dataset e seed
            max_rules = if dataset == "heart"
                10
            elseif dataset in ["monks-2", "monks-3", "diabets"]
                20
            elseif dataset == "mammographic_masses"
                randomseed in [2, 987654321, 5555] ? 10 : 23
            elseif dataset == "tictactoe"
                randomseed in [2, 987654321, 153, 5555, 789987, 2806] ? 10 : 30
            elseif dataset == "breast_cancer"
                randomseed in [2, 987654321, 153, 5555, 7] ? 10 : 34
            elseif dataset == "haberman"
                50
            elseif dataset == "statlog"
                15
            elseif (dataset == "htru2" && randomseed == 2) ||
                   (dataset == "occupancy" && randomseed == 987654321) ||
                   (dataset == "veichle_E" && randomseed == 153)
                10
            else
                nothing  # usa default
            end
            dl = max_rules === nothing ? intrees(model, X, y) : intrees(model, X, y, max_rules=max_rules)
        end
        ll = listrules(dl, use_shortforms=false)
        rules_obj = convert_classification_rules(ll)
        println(dl)
        dsintrees = DecisionSet(rules_obj)
        println(dsintrees)
        println("Running time: $timeintrees seconds")


        #======================================================================================================================================
                                                                REFNE
        ======================================================================================================================================#
        println("\n\n\n REFNE \n")

        X = features_train
        y = labels_train

        rangeXmin = [minimum(X[:, i]) for i in 1:size(X, 2)]
        rangeXmax = [maximum(X[:, i]) for i in 1:size(X, 2)]

        # Override for specific seed/dataset combination, otherwise use lookup table
        cfg = if dataset == "breast_cancer" && randomseed == 98529
            (L=3, max_depth=5, ott_mode=true)
        else
            get(REFNE_CONFIGS, dataset, DEFAULT_REFNE_CONFIG)
        end

        timerefne = @elapsed begin
            nf = REFNE.refne(f, rangeXmin, rangeXmax; L=cfg.L, max_depth=cfg.max_depth, ott_mode=cfg.ott_mode)
        end

        dsrefne = convertApi(nf)
        println(dsrefne)
        println("Running time: $timerefne seconds")

        #======================================================================================================================================
                                                                TREPAN
        ======================================================================================================================================#
        println("\n\n\n TREPAN \n")

        X = features_train

        n_random = round(Int, size(X, 1) * 0.16)
        X_combined = vcat(X, rand(n_random, size(X, 2)))

        trepan_kwargs = (
            max_depth=get(TREPAN_MAX_DEPTH, dataset, 6),
            n_subfeatures=1.0,
            partial_sampling=1.0,
            min_samples_leaf=1,
            min_samples_split=2,
            min_purity_increase=5.0e-324,
            seed=100,
        )

        timetrepan = @elapsed begin
            nf = TREPAN.trepan(f, X_combined; trepan_kwargs...)
        end

        dstrepan = convertApi(nf)
        println(dstrepan)
        println("Running time: $timetrepan seconds")

        #======================================================================================================================================
                                                                RULECOSIPLUS
        ======================================================================================================================================#
        println("\n\n\n RULE COSI+ \n")

        x = features_train
        y = labels_train

        timerulecosiplus = @elapsed begin
            dl = RULECOSIPLUS.rulecosiplus(f, x, y)
        end

        ll = listrules(dl, use_shortforms=false)
        rules_obj = convert_classification_rules(ll)
        dsrulecosiplus = DecisionSet(rules_obj)
        println(dsrulecosiplus)
        println("Running time: $timerulecosiplus seconds")


        #======================================================================================================================================
                                                                Evaluate all DS
        ======================================================================================================================================#
        algorithms = [
            ("Lumen", dslumen, timelumen),
            ("BATrees", dsbatrees, timebatrees),
            ("InTrees", dsintrees, timeintrees),
            ("REFNE", dsrefne, timerefne),
            ("TREPAN", dstrepan, timetrepan),
            ("RuleCOSI+", dsrulecosiplus, timerulecosiplus),
        ]

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
        for (name, algorithm, exec_time) in algorithms
            decisionset_accuracy =
                calculate_decisionset_accuracy(algorithm, features_test, labels_test)

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

            if !haskey(all_results[dataset], name)
                all_results[dataset][name] = Dict()
            end

            for (rule_id, eval) in enumerate(rule_evaluations)
                rule = SoleModels.rules(algorithm)[rule_id]
                rule_idd = strip(
                    replace(
                        string(consequent(SoleModels.rules(algorithm)[rule_id])),
                        r"\x1B\[[0-9;]*[a-zA-Z]|▣|\n" => "",
                    ),
                )

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
                    )
                end

                sensitivity = eval.sensitivity
                specificity = eval.specificity
                rule_f1_score = calculate_rule_f1_score(eval, rule, labels_test)

                min_avg = 0.0
                min_std = 0.0
                max_avg = 0.0
                avg_avg = 0.0
                std_avg = 0.0

                natoms_expl = map(
                    expls -> let
                        x = Float64[SoleModels.natoms(e) for e in expls]
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

                num_atoms = SoleModels.natoms(antecedent(rule))

                push!(all_results[dataset][name][rule_idd]["num_terms"],
                    isa(num_terms, Number) ? Float64(num_terms) : num_terms)
                push!(all_results[dataset][name][rule_idd]["exec_time"], Float64(exec_time))
                push!(all_results[dataset][name][rule_idd]["sensitivity"], Float64(sensitivity))
                push!(all_results[dataset][name][rule_idd]["specificity"], Float64(specificity))
                push!(all_results[dataset][name][rule_idd]["min_avg"], Float64(min_avg))
                push!(all_results[dataset][name][rule_idd]["min_std"], Float64(min_std))
                push!(all_results[dataset][name][rule_idd]["max_avg"], Float64(max_avg))
                push!(all_results[dataset][name][rule_idd]["avg_avg"], Float64(avg_avg))
                push!(all_results[dataset][name][rule_idd]["std_avg"], Float64(std_avg))
                push!(all_results[dataset][name][rule_idd]["decisionset_accuracy"], Float64(decisionset_accuracy))
                push!(all_results[dataset][name][rule_idd]["rule_f1_score"], Float64(rule_f1_score))
                push!(all_results[dataset][name][rule_idd]["num_atoms"],
                    isa(num_atoms, Number) ? Float64(num_atoms) : num_atoms)
            end
        end
    end
end


open("tab2_randomforest.csv", "w") do csv_file
    println(
        csv_file,
        "Dataset,Algorithm,AVGExecution_Time,Rule_ID,AVGSensitivity,AVGSpecificity,AVGMin_Avg,AVGMin_Std,AVGMaximum,AVGAverage,AVGStd_Dev,AVGNumAtoms,AVGDecisionSetAccuracy,AVGRuleF1Score",
    )

    for dataset in datasets
        haskey(all_results, dataset) || continue
        for (algorithm_name, algorithm_results) in all_results[dataset]
            for (rule_id, metrics) in algorithm_results
                avg_num_terms = if all(isa(x, Number) for x in metrics["num_terms"])
                    mean(metrics["num_terms"])
                else
                    if length(metrics["num_terms"]) > 0
                        first_val = metrics["num_terms"][1]
                        isa(first_val, Number) ? mean(metrics["num_terms"]) :
                        "[$(join(first_val, ","))]"
                    else
                        0.0
                    end
                end

                avg_num_atoms = if all(isa(x, Number) for x in metrics["num_atoms"])
                    mean(metrics["num_atoms"])
                else
                    if length(metrics["num_atoms"]) > 0
                        first_val = metrics["num_atoms"][1]
                        isa(first_val, Number) ? mean(metrics["num_atoms"]) :
                        "[$(join(first_val, ","))]"
                    else
                        0.0
                    end
                end

                println(
                    csv_file,
                    "$dataset,$algorithm_name,$(mean(metrics["exec_time"])),$rule_id," *
                    "$(mean(metrics["sensitivity"])),$(mean(metrics["specificity"]))," *
                    "$(mean(metrics["min_avg"])),$(mean(metrics["min_std"]))," *
                    "$(mean(metrics["max_avg"])),$(mean(metrics["avg_avg"]))," *
                    "$(mean(metrics["std_avg"])),$avg_num_atoms," *
                    "$(mean(metrics["decisionset_accuracy"])),$(mean(metrics["rule_f1_score"]))",
                )
            end
        end
    end
end

println("evaluation_results_experiment_for_table_2.csv")