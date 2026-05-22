using Pkg
Pkg.activate(".")
using Revise
using DataFrames
using DecisionTree
using Statistics

include("utilsForTest.jl")
include("suitfortest.jl")

# ============================================================
#  DATASETS
# ============================================================
const DATASETS = [
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
    "htru2",                   # slow dataset
    "banknote",
    "seeds",
    "mushroom",
    "diabets",
]

# 10 fixed seeds (shared across all scripts)
const SEEDS = [153, 2025, 2, 987654321, 5555, 789987, 98529, 7, 2806, 1548]

# Forest sizes to test for each model
const RF_SIZES = [2, 4, 8, 16, 32, 64]   # powers of 2
const XGBOOST_SIZES = [2, 4, 8, 16, 32, 64]   # powers of 2
# const RDL_SIZES = collect(2:5)               # -- DL work: RDL temporarily disabled

# ============================================================
#  HELPER FUNCTION: train a model and compute accuracy.
#  Returns NaN if anything goes wrong.
# ============================================================
function safe_accuracy(train_fn, n_trees, dataset, seed)
    try
        f, _, _, _, _, features_test, labels_test, _, _ =
            train_fn(n_trees, dataset, 3, seed)
        return calculate_forest_accuracy(f, features_test, labels_test)
    catch e
        @warn "FAILED: dataset=$dataset n_trees=$n_trees seed=$seed" exception = e
        return NaN
    end
end

# ============================================================
#  RESULT COLLECTION
#  results[model_type][dataset][n_trees] = Vector{Float64}
#  (10 accuracy values, one per seed)
# ============================================================
results = Dict(
    "RF" => Dict{String,Dict{Int,Vector{Float64}}}(),
    "XGBoost" => Dict{String,Dict{Int,Vector{Float64}}}(),
    # "RDL"  => Dict{String,Dict{Int,Vector{Float64}}}(),   # -- DL work: RDL temporarily disabled
)

for dataset in DATASETS
    for (mtype, sizes) in [("RF", RF_SIZES), ("XGBoost", XGBOOST_SIZES)]   # -- DL work: ("RDL", RDL_SIZES) removed
        results[mtype][dataset] = Dict{Int,Vector{Float64}}()
        for n in sizes
            results[mtype][dataset][n] = Float64[]
        end
    end
end

# ============================================================
#  SWEEP: Random Forest
# ============================================================
println("\n========== SWEEP: Random Forest ==========\n")
for dataset in DATASETS
    println("  Dataset: $dataset")
    for n_trees in RF_SIZES
        for seed in SEEDS
            acc = safe_accuracy(learn_and_convert, n_trees, dataset, seed)
            push!(results["RF"][dataset][n_trees], acc)
            println("    RF | n=$n_trees | seed=$seed | acc=$(isnan(acc) ? "NaN" : "$(round(acc*100,digits=2))%")")
        end
    end
end

# ============================================================
#  SWEEP: XGBoost
# ============================================================
println("\n========== SWEEP: XGBoost ==========\n")
for dataset in DATASETS
    println("  Dataset: $dataset")
    for n_trees in XGBOOST_SIZES
        for seed in SEEDS
            acc = safe_accuracy(learn_and_convert_xgboost, n_trees, dataset, seed)
            push!(results["XGBoost"][dataset][n_trees], acc)
            println("    XGBoost | n=$n_trees | seed=$seed | acc=$(isnan(acc) ? "NaN" : "$(round(acc*100,digits=2))%")")
        end
    end
end

# ============================================================
#  SWEEP: Random Decision List  -- DL work: entire block disabled
# ============================================================
# println("\n========== SWEEP: Random Decision List ==========\n")
# for dataset in DATASETS
#     println("  Dataset: $dataset")
#     for n_trees in RDL_SIZES
#         for seed in SEEDS
#             acc = safe_accuracy(learn_and_convert_decisionlist, n_trees, dataset, seed)
#             push!(results["RDL"][dataset][n_trees], acc)
#             println("    RDL | n=$n_trees | seed=$seed | acc=$(isnan(acc) ? "NaN" : "$(round(acc*100,digits=2))%")")
#         end
#     end
# end

# ============================================================
#  WRITE OUTPUT FILE: forest_accuracy_sweep.dat
# ============================================================
open("forest_accuracy_sweep.dat", "w") do io

    println(io, "# forest_accuracy_sweep.dat")
    println(io, "# Accuracy sweep across model sizes (number of trees)")
    println(io, "# Each row = (dataset, n_trees): 10 accuracy values (one per seed) + mean and std")
    println(io, "#")
    println(io, "# Seeds used: $(join(SEEDS, ", "))")
    println(io, "#")

    seed_header = join(["seed_$(s)" for s in SEEDS], "\t")

    for (mtype, sizes) in [("RF", RF_SIZES), ("XGBoost", XGBOOST_SIZES)]   # -- DL work: ("RDL", RDL_SIZES) removed

        println(io, "#")
        println(io, "# ==============================================================")
        println(io, "# MODEL: $mtype")
        if mtype == "RF"
            println(io, "# n_trees: $(join(RF_SIZES, ", "))  (powers of 2)")
        elseif mtype == "XGBoost"
            println(io, "# n_trees: $(join(XGBOOST_SIZES, ", "))  (powers of 2)")
            # else                                                              # -- DL work: RDL block removed
            #     println(io, "# n_trees: $(join(RDL_SIZES, ", "))  (from 2 to 10, step 1)")
        end
        println(io, "# ==============================================================")
        println(io, "#")
        println(io, "# dataset\tn_trees\t$seed_header\tmean_acc\tstd_acc")

        for dataset in DATASETS
            for n_trees in sizes
                accs = results[mtype][dataset][n_trees]

                # pad with NaN if any run is missing
                while length(accs) < length(SEEDS)
                    push!(accs, NaN)
                end

                valid = filter(!isnan, accs)
                mean_acc = isempty(valid) ? NaN : mean(valid)
                std_acc = length(valid) < 2 ? NaN : std(valid)

                acc_str = join([isnan(a) ? "NaN" : string(round(a, digits=6)) for a in accs], "\t")
                mean_str = isnan(mean_acc) ? "NaN" : string(round(mean_acc, digits=6))
                std_str = isnan(std_acc) ? "NaN" : string(round(std_acc, digits=6))

                println(io, "$dataset\t$n_trees\t$acc_str\t$mean_str\t$std_str")
            end
        end

    end
end

println("\nDone! Results written to: forest_accuracy_sweep.dat")