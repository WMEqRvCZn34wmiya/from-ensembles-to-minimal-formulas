"""
    utils

Utility module for loading datasets, splitting data, and training Random Forest models.

Designed to work with `DecisionTree.jl` for model training and `SoleModels.jl`
for model representation.

See `parts.jl` for the bitvector-driven forest compression pipeline.

# Exports
- `load_data_hardcoded`  – Load and preprocess a named dataset from disk
- `split_data`           – Split data into train/validation/test sets
- `learn_and_convert`    – Train a Random Forest and convert it to a Sole model
"""
module utils

import DecisionTree as DT
using DelimitedFiles
using Random
using SoleData
using SoleModels

export load_data_hardcoded, split_data, learn_and_convert

const DATASETS_DIR = "src/datasets"


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

"""
    _dataset_path(name) -> String

Return the canonical path for a named dataset file.
"""
_dataset_path(name::String) = joinpath(DATASETS_DIR, "$name.data")


"""
    _simple_load(path, feature_cols, label_col) -> (Matrix{Float64}, Vector{String})

Load a CSV with no preprocessing: extract feature columns and label column directly.
`feature_cols` is a `UnitRange` or `Vector{Int}`.
"""
function _simple_load(path::String, feature_cols, label_col::Int)
    data     = DelimitedFiles.readdlm(path, ',')
    features = float.(data[:, feature_cols])
    labels   = string.(data[:, label_col])
    return features, labels
end


"""
    _filter_missing(data, sentinel="?") -> Matrix

Return a copy of `data` with all rows that contain `sentinel` removed.
"""
function _filter_missing(data, sentinel="?")
    valid = [!any(row .== sentinel) for row in eachrow(data)]
    return data[valid, :]
end


"""
    _encode_column(col_values) -> Vector{Float64}

Assign a unique Float64 index (0-based) to each distinct string value found in
`col_values`, in order of first appearance.
"""
function _encode_column(col_values)
    mapping = Dict{Any,Float64}()
    result  = Vector{Float64}(undef, length(col_values))
    counter = 0.0
    for (i, v) in enumerate(col_values)
        if !haskey(mapping, v)
            mapping[v] = counter
            counter += 1.0
        end
        result[i] = mapping[v]
    end
    return result
end


# ─────────────────────────────────────────────────────────────────────────────
# DATA LOADING  –  dispatch on dataset name
# ─────────────────────────────────────────────────────────────────────────────

"""
    load_data_hardcoded(dataset_name) -> (features, labels)

Load and preprocess a dataset identified by `dataset_name`.
Each dataset has its own preprocessing block; for "plain" datasets a simple
column-slice is performed, while others apply categorical encoding or missing-
value filtering.

# Returns
- `features::Matrix{Float64}`
- `labels::Vector{String}`
"""
function load_data_hardcoded(dataset_name::String)

    Random.seed!(42)
    path = _dataset_path(dataset_name)

    # ── plain datasets ────────────────────────────────────────────────────────
    # These only need column slicing; no encoding or filtering required.
    _plain = Dict(
        "zoo"                            => (2:17,   18),
        "eletronics"                     => (1:13,   14),
        "Occupancy_Estimation"           => (3:18,   19),
        "lung-cancer"                    => (2:56,    1),
        "fertility"                      => (1:9,    10),
        "ces-small1"                     => (1:5,     6),
        "ces-small2"                     => (1:5,     6),
        "immunotherapy"                  => (1:7,     8),
        "breast-cancer-coimbra"          => (1:9,    10),
        "cervical-cancer-behavior-risk"  => (1:19,   20),
        "iranian-churn"                  => (1:13,   14),
        "taiwanese-bankruptcy"           => (2:96,    1),
        "beed-bangalore-eeg-epilepsy"    => (1:16,   17),
        "breast-tissue"                  => (2:10,    1),
        "absenteeism-at-work"            => (1:20,   21),
        "ionosphere"                     => (1:34,   35),
        "dry-bean"                       => (1:16,   17),
        "statlog"                        => (1:13,   14),
        "Heart_disease_cleveland_new"    => (1:13,   14),
        "bupa"                           => (1:6,     7),
        "banknote"                       => (1:4,     5),
        "BankNote_Authentication_UCI"    => (1:4,     5),
        "htru"                           => (1:8,     9),
        "seeds"                          => (1:7,     8),
        "biodeg"                         => (1:40,   41),
        "cryotherapy"                    => (1:6,     7),
        "divorce"                        => (1:54,   55),
        "ecoli"                          => (1:7,     8),
        "mammographic_masses"            => (1:5,     6),
        "occupancy"                      => (3:7,     8),
        "bean"                           => (3:15,    2),
        "new-thyroid"                    => (2:6,     1),
        "haberman"                       => (1:3,     4),
        "lenses"                         => (2:5,     1),
        "lymphography"                   => (2:19,    1),
        "glass"                          => (2:10,   11),
        "hayes-roth"                     => (2:5,     6),
        "soybean-small"                  => (1:35,   36),
        "balance-scale"                  => (2:5,     1),
        "tae"                            => (1:5,     6),   # post-processed below
        "wine"                           => (2:14,    1),
        "heart"                          => (1:13,   14),
        "iris"                           => (1:4,     5),
    )

    if haskey(_plain, dataset_name)
        fcols, lcol = _plain[dataset_name]

        features, labels = _simple_load(path, fcols, lcol)

        # tae: discretise the 5th feature into three bins
        if dataset_name == "tae"
            for i in axes(features, 1)
                v = features[i, 5]
                features[i, 5] = v <= 20 ? 0.0 : v <= 40 ? 1.0 : 2.0
            end
        end

        return features, labels
    end

    # ── datasets requiring missing-value filtering ────────────────────────────
    if dataset_name == "labor"
        data = DelimitedFiles.readdlm(path, ',')
        # TODO: decide how to handle '?' values in labor dataset
        return float.(data[:, 1:16]), string.(data[:, 17])
    end

    if dataset_name in ("breast-cancer-wisconsin", "dermatology")
        data  = DelimitedFiles.readdlm(path, ',')
        clean = _filter_missing(data)
        col_ranges = dataset_name == "breast-cancer-wisconsin" ? (3:35, 2) : (1:34, 35)
        return float.(clean[:, col_ranges[1]]), string.(clean[:, col_ranges[2]])
    end

    if dataset_name == "hepatitis"
        data  = DelimitedFiles.readdlm(path, ',')
        clean = _filter_missing(data)
        return Float64.(clean[:, 2:20]), string.(clean[:, 1])
    end

    # ── balloons family ───────────────────────────────────────────────────────
    if startswith(dataset_name, "balloons")
        data  = DelimitedFiles.readdlm(path, ',')
        n     = size(data, 1)
        color_map = Dict("YELLOW" => 0.0, "PURPLE" => 1.0)
        size_map  = Dict("SMALL"  => 0.0, "LARGE"  => 1.0)
        act_map   = Dict("STRETCH"=> 0.0, "DIP"    => 1.0)
        age_map   = Dict("ADULT"  => 0.0, "CHILD"  => 1.0)
        features  = zeros(Float64, n, 4)
        for i in 1:n
            features[i, 1] = color_map[string(data[i, 1])]
            features[i, 2] = size_map[string(data[i, 2])]
            features[i, 3] = act_map[string(data[i, 3])]
            features[i, 4] = age_map[string(data[i, 4])]
        end
        return features, string.(data[:, 5])
    end

    # ── diabets ───────────────────────────────────────────────────────────────
    if dataset_name == "diabets"
        return _simple_load(path, 1:8, 9)
    end

    # ── mushroom ─────────────────────────────────────────────────────────────
    if dataset_name == "mushroom"
        data = DelimitedFiles.readdlm(path, ',')
        n, m = size(data)
        features = zeros(Float64, n, m - 1)
        for col in 2:m
            features[:, col-1] = _encode_column(data[:, col])
        end
        labels = map(l -> l == "e" ? "edible" : "poisonous", data[:, 1])
        return features, labels
    end

    # ── post-operative ────────────────────────────────────────────────────────
    if dataset_name == "post-operative"
        data     = DelimitedFiles.readdlm(path, ',')
        clean    = _filter_missing(data)
        n        = size(clean, 1)
        features = zeros(Float64, n, 8)

        trimap = Dict("high" => 2.0, "mid" => 1.0, "low" => 0.0)
        for col in 1:4
            for i in 1:n; features[i, col] = trimap[string(clean[i, col])]; end
        end

        stab_map = Dict("stable" => 2.0, "mod-stable" => 1.0, "unstable" => 0.0)
        for col in 5:7
            for i in 1:n; features[i, col] = stab_map[string(clean[i, col])]; end
        end

        o2_map = Dict("excellent" => 3.0, "good" => 2.0, "fair" => 1.0, "poor" => 0.0)
        for i in 1:n; features[i, 3] = o2_map[string(clean[i, 3])]; end   # overwrite col 3

        for i in 1:n
            v = clean[i, 8]
            features[i, 8] = isa(v, Number) ? Float64(v) : parse(Float64, v)
        end

        return features, string.(clean[:, 9])
    end

    # ── urinary (diagnosis.data shared file) ──────────────────────────────────
    if dataset_name in ("urinary-d1", "urinary-d2")
        diag_path  = joinpath(DATASETS_DIR, "diagnosis.data")
        raw        = String(read(diag_path))
        lines      = filter(!isempty ∘ strip, split(raw, '\n'))
        label_col  = dataset_name == "urinary-d1" ? 7 : 8
        n          = length(lines)
        features   = zeros(Float64, n, 6)
        labels     = String[]

        for (i, line) in enumerate(lines)
            parts = split(line, ',')
            length(parts) < 8 && continue
            features[i, 1] = parse(Float64, replace(parts[1], ',' => '.'))
            for j in 2:6
                features[i, j] = lowercase(strip(parts[j])) == "yes" ? 1.0 : 0.0
            end
            push!(labels, lowercase(strip(parts[label_col])) == "yes" ? "yes" : "no")
        end

        return features, labels
    end

    # ── yeast ─────────────────────────────────────────────────────────────────
    if dataset_name == "yeast"
        data      = DelimitedFiles.readdlm(path, ',')
        valid_idx = [i for i in 1:size(data,1)
                     if all(j -> !ismissing(data[i,j]) && data[i,j] != "",  2:9)]
        vd        = data[valid_idx, :]
        return parse.(Float64, string.(vd[:, 2:9])), string.(vd[:, 10])
    end

    # ── breast_cancer (categorical encoding) ──────────────────────────────────
    if dataset_name == "breast_cancer"
        data = DelimitedFiles.readdlm(path, ',', String)
        n    = size(data, 1)

        age_ranges   = ["10-19","20-29","30-39","40-49","50-59","60-69","70-79","80-89","90-99"]
        meno_map     = Dict("lt40"=>1.0,"ge40"=>2.0,"premeno"=>3.0)
        tsize_ranges = ["0-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59"]
        nodes_ranges = ["0-2","3-5","6-8","9-11","12-14","15-17","18-20","21-23","24-26","27-29","30-32","33-35","36-39"]
        quad_map     = Dict("left-up"=>1.0,"left-low"=>2.0,"right-up"=>3.0,"right-low"=>4.0,"central"=>5.0)

        features = zeros(Float64, n, 9)
        for i in 1:n
            features[i,1] = Float64(findfirst(==(data[i,2]), age_ranges))
            features[i,2] = get(meno_map,   data[i,3], 0.0)
            features[i,3] = Float64(findfirst(==(data[i,4]), tsize_ranges))
            features[i,4] = Float64(findfirst(==(data[i,5]), nodes_ranges))
            features[i,5] = data[i,6] == "?" ? 0.0 : (data[i,6] == "yes" ? 1.0 : 0.0)
            features[i,6] = parse(Float64, data[i,7])
            features[i,7] = data[i,8] == "left" ? 0.0 : 1.0
            features[i,8] = data[i,9] == "?" ? 0.0 : get(quad_map, data[i,9], 0.0)
            features[i,9] = data[i,10] == "yes" ? 1.0 : 0.0
        end

        return features, string.(data[:, 1])
    end

    # ── penguins ──────────────────────────────────────────────────────────────
    if dataset_name == "penguins"
        data    = DelimitedFiles.readdlm(path, ',')
        numeric = float.(data[:, 3:6])
        sex_col = map(s -> s == "FEMALE" ? 1.0 : 0.0, data[:, 7])
        return hcat(numeric, sex_col), string.(data[:, 1])
    end

    # ── car ───────────────────────────────────────────────────────────────────
    if dataset_name == "car"
        data     = DelimitedFiles.readdlm(path, ',')
        n        = size(data, 1)
        features = zeros(Float64, n, 6)

        price_map   = Dict("vhigh"=>4.0,"high"=>3.0,"med"=>2.0,"low"=>1.0)
        doors_map   = Dict("2"=>2.0,"3"=>3.0,"4"=>4.0,"5more"=>5.0)
        persons_map = Dict("2"=>2.0,"4"=>4.0,"more"=>6.0)
        boot_map    = Dict("small"=>1.0,"med"=>2.0,"big"=>3.0)
        safety_map  = Dict("low"=>1.0,"med"=>2.0,"high"=>3.0)

        for i in 1:n
            features[i,1] = price_map[string(data[i,1])]
            features[i,2] = price_map[string(data[i,2])]
            features[i,3] = doors_map[string(data[i,3])]
            features[i,4] = persons_map[string(data[i,4])]
            features[i,5] = boot_map[string(data[i,5])]
            features[i,6] = safety_map[string(data[i,6])]
        end

        return features, string.(data[:, 7])
    end

    # ── tictactoe ─────────────────────────────────────────────────────────────
    if dataset_name == "tictactoe"
        data     = DelimitedFiles.readdlm(path, ',')
        n        = size(data, 1)
        features = zeros(Float64, n, 9)
        for i in 1:n, j in 1:9
            features[i,j] = data[i,j] == "x" ? 1.0 : data[i,j] == "o" ? 0.0 : -1.0
        end
        return features, string.(data[:, 10])
    end

    # ── house-votes ───────────────────────────────────────────────────────────
    if dataset_name == "house-votes"
        data     = DelimitedFiles.readdlm(path, ',')
        n        = size(data, 1)
        features = zeros(Float64, n, 16)
        for i in 1:n, j in 2:17
            features[i,j-1] = data[i,j] == "y" ? 1.0 : data[i,j] == "n" ? 0.0 : 2.0
        end
        return features, string.(data[:, 1])
    end

    # ── primary-tumor ─────────────────────────────────────────────────────────
    if dataset_name == "primary-tumor"
        data     = DelimitedFiles.readdlm(path, ',')
        n        = size(data, 1)
        features = zeros(Float64, n, 17)
        for i in 1:n, j in 2:18
            features[i,j-1] = data[i,j] == "?" ? -1.0 : Float64(data[i,j])
        end
        return features, string.(data[:, 1])
    end

    # ── monks ─────────────────────────────────────────────────────────────────
    if dataset_name in ("monks-1", "monks-2", "monks-3")
        monks_path = joinpath("src/monks", "$dataset_name.data")
        data       = DelimitedFiles.readdlm(monks_path, ' ', skipblanks=true)
        return float.(data[:, 2:7]), string.(data[:, 1])
    end

    # ── cmc ───────────────────────────────────────────────────────────────────
    if dataset_name == "cmc"
        data     = DelimitedFiles.readdlm(path, ',')
        features = float.(data[:, 1:9])
        for i in axes(features, 1)
            a = features[i, 1]
            features[i, 1] = a <= 18 ? 0.0 : a <= 30 ? 1.0 : a <= 35 ? 2.0 : 3.0
        end
        return features, string.(data[:, 10])
    end

    # ── veichle family (separate data directory) ──────────────────────────────
    veichle_variants = ["veichle_$x" for x in 'A':'I']
    if dataset_name in veichle_variants
        veichle_path = joinpath("src/veichle", "$dataset_name.data")
        data         = DelimitedFiles.readdlm(veichle_path, ',')
        return float.(data[:, 1:18]), string.(data[:, 19])
    end

    error("Unknown dataset: \"$dataset_name\". Add a preprocessing block in load_data_hardcoded.")
end


# ─────────────────────────────────────────────────────────────────────────────
# DATA SPLITTING
# ─────────────────────────────────────────────────────────────────────────────

"""
    split_data(features, labels, training_ratio, validation_ratio, seed=42)

Randomly split features and labels into training, validation, and test sets.
The test ratio is implicitly `1 - training_ratio - validation_ratio`.

# Returns
`(f_train, f_val, f_test, l_train, l_val, l_test)`
"""
function split_data(features, labels, training_ratio, validation_ratio, seed=42)

    # Fix the random seed so results are reproducible across runs
    Random.seed!(seed)

    samples   = size(features, 1)
    idx       = shuffle(1:samples)

    # Compute split boundary indices
    train_end = floor(Int, training_ratio * samples)
    val_end   = floor(Int, (training_ratio + validation_ratio) * samples)

    # Slice the shuffled indices into three non-overlapping groups
    train_idx = idx[1:train_end]
    val_idx   = idx[train_end+1:val_end]
    test_idx  = idx[val_end+1:end]

    return (
        features[train_idx, :], features[val_idx, :], features[test_idx, :],
        labels[train_idx],      labels[val_idx],      labels[test_idx],
    )
end


# ─────────────────────────────────────────────────────────────────────────────
# MODEL TRAINING
# ─────────────────────────────────────────────────────────────────────────────

"""
    learn_and_convert(n_trees, dataset_name)

Load a dataset by name, split it, train a Random Forest, and convert it to a
SoleModel.

# Returns
`(Sole_model, model, f_train, l_train, f_test, l_test, f_val, l_val, features, labels)`
"""
function learn_and_convert(n_trees::Int, dataset_name::String)
    max_depth = -1
    rf_seed   = 42

    features, labels = load_data_hardcoded(dataset_name)
    f_train, f_val, f_test, l_train, l_val, l_test =
        split_data(features, labels, 0.75, 0.15)

    model = DT.build_forest(
        l_train, f_train,
        -1, n_trees, 0.7, max_depth, 5, 2, 0.0;
        rng=rf_seed,
    )

    # Convert the DecisionTree forest into a SoleModels DecisionEnsemble
    Sole_model = solemodel(model)

    return Sole_model, model,
           f_train, l_train,
           f_test,  l_test,
           f_val,   l_val,
           features, labels
end

end  # module utils