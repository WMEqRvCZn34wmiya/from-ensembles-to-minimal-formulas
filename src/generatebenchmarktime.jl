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

# Dictionary to store execution times only
execution_times = Dict(
    "Lumen" => Float64[],
    "BATrees" => Float64[],
    "InTrees" => Float64[],
    "REFNE" => Float64[],
    "TREPAN" => Float64[],
    "RuleCOSI+" => Float64[],
)

for dataset in datasets
    for randomseed in [153, 2025, 2, 987654321, 5555, 789987, 98529, 7, 2806, 1548]
        println(
            "\n\n$COLORED_ULTRA_OTT$TITLE\n ADDESTRAMENTO ALBERO $dataset (seed: $randomseed) \n$TITLE$RESET",
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

        println("importance vector:", create_importance_vector(impurity_importance(model)))

        #======================================================================================================================================
                                                                LUMEN
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n LUMEN \n$TITLE$RESET")

        timelumen = @elapsed begin
            result = lumen(
                model;
                vertical=1.0,
                horizontal=1.0,
                ott_mode=true,
                controllo=false,
                silent=true,
                apply_function=apply_forest,
                vetImportance=create_importance_vector(impurity_importance(model)),
            )
            dslumen = result.decision_set
            Lumeninfo = result.info
        end

        println("Running time: $timelumen seconds")
        push!(execution_times["Lumen"], timelumen)

        #======================================================================================================================================
                                                                      BATREES
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n BATREES \n$TITLE$RESET")

        timebatrees = @elapsed begin
            dsbatrees = BATrees.batrees(f)
        end

        println("Running time: $timebatrees seconds")
        push!(execution_times["BATrees"], timebatrees)

        #======================================================================================================================================
                                                                INTREES
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n INTREES \n$TITLE$RESET")

        x = features_train
        y = labels_train

        X = SoleData.scalarlogiset(DataFrame(x, :auto))

        timeintrees = @elapsed begin
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
            elseif (dataset == "htru" && randomseed == 2) ||
                   (dataset == "occupancy" && randomseed == 987654321) ||
                   (dataset == "veichle_E" && randomseed == 153)
                10
            else
                nothing
            end

            dl =
                max_rules === nothing ? intrees(model, X, y) :
                intrees(model, X, y, max_rules=max_rules)
        end

        ll = listrules(dl, use_shortforms=false)
        rules_obj = convert_classification_rules(ll)
        dsintrees = DecisionSet(rules_obj)

        println("Running time: $timeintrees seconds")
        push!(execution_times["InTrees"], timeintrees)

        #======================================================================================================================================
                                                                REFNE
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n REFNE \n$TITLE$RESET")

        X = features_train
        y = labels_train

        rangeXmin = []
        rangeXmax = []
        for i = 1:size(X, 2)
            append!(rangeXmax, maximum(X[:, i]))
            append!(rangeXmin, minimum(X[:, i]))
        end

        timerefne = @elapsed begin
            if dataset in [
                "divorce",
                "breast_cancer",
                "house-votes",
                "soybean-small",
                "mushroom",
                "veichle_E",
                "heart",
                "statlog",
            ]
                if dataset == "breast_cancer" && randomseed == 98529
                    nf = REFNE.refne(
                        f,
                        rangeXmin,
                        rangeXmax,
                        L=3,
                        max_depth=10000,
                        ott_mode=true,
                    )
                else
                    nf = REFNE.refne(
                        f,
                        rangeXmin,
                        rangeXmax,
                        L=2,
                        max_depth=10000,
                        ott_mode=true,
                    )
                end
            elseif dataset == "monks-2"
                nf = REFNE.refne(
                    f,
                    rangeXmin,
                    rangeXmax,
                    L=4,
                    max_depth=10000,
                    ott_mode=false,
                )
            else
                nf = REFNE.refne(
                    f,
                    rangeXmin,
                    rangeXmax,
                    L=3,
                    max_depth=10000,
                    ott_mode=false,
                )
            end
        end

        dsrefne = convertApi(nf)
        println("Running time: $timerefne seconds")
        push!(execution_times["REFNE"], timerefne)

        #======================================================================================================================================
                                                                TREPAN
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n TREPAN \n$TITLE$RESET")

        X = features_train

        n_samples_original = size(X, 1)
        n_random = round(Int, n_samples_original * 0.16)

        random_features = rand(n_random, size(X, 2))
        X_combined = vcat(X, random_features)

        timetrepan = @elapsed begin
            nf = TREPAN.trepan(
                f,
                X_combined,
                max_depth=-1,
                n_subfeatures=1.0,
                partial_sampling=1.0,
                min_samples_leaf=1,
                min_samples_split=2,
                min_purity_increase=5.0e-324,
                seed=100,
            )
        end

        dstrepan = convertApi(nf)

        println("Running time: $timetrepan seconds")
        push!(execution_times["TREPAN"], timetrepan)

        #======================================================================================================================================
                                                                RULECOSIPLUS
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n RULE COSI+ \n$TITLE$RESET")

        x = features_train
        y = labels_train

        timerulecosiplus = @elapsed begin
            dl = RULECOSIPLUS.rulecosiplus(f, x, y)
        end

        ll = listrules(dl, use_shortforms=false)
        rules_obj = convert_classification_rules(ll)
        dsrulecosiplus = DecisionSet(rules_obj)

        println("Running time: $timerulecosiplus seconds")
        push!(execution_times["RuleCOSI+"], timerulecosiplus)
    end
end

# Print average execution times
println("\n" * "="^60)
println("AVERAGE EXECUTION TIMES")
println("="^60)
for (algorithm, times) in sort(collect(execution_times), by=x -> x[1])
    avg_time = mean(times)
    println("$algorithm: $(round(avg_time, digits=4)) seconds")
end
println("="^60)

#=
============================================================
AVERAGE EXECUTION TIMES
============================================================
BATrees: 1.2523 seconds
InTrees: 1.4306 seconds
Lumen: 1.872 seconds
REFNE: 0.1536 seconds
RuleCOSI+: 0.0199 seconds
TREPAN: 0.025 seconds
============================================================
=#
