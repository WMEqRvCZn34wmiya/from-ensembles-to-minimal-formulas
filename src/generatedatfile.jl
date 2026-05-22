using CSV
using DataFrames
using Printf

# Leggi il CSV
df = CSV.read("/Users/perry/.julia/dev/ModalMinimizerRulesSystematicApp/tab2_randomforest_bk.csv", DataFrame)

# Calcola la fidelity per ogni riga (media tra sensitivity e specificity)
df.Fidelity = (df.AVGSensitivity .+ df.AVGSpecificity) ./ 2

# Lista degli algoritmi
algorithms = ["Lumen", "REFNE", "InTrees", "RuleCOSI+", "BATrees", "TREPAN"]

# Range di fidelity da 0.50 a 1.00 con passo 0.025
fidelity_thresholds = 0.50:0.01:1.00

# Numero totale di dataset unici
unique_datasets = unique(df.Dataset)
total_cases = length(unique_datasets)

println("Totale dataset unici: ", total_cases)

# Inizializza la matrice dei risultati
results = zeros(Int, length(fidelity_thresholds), length(algorithms))

# Per ogni soglia di fidelity
for (f_idx, fidelity_threshold) in enumerate(fidelity_thresholds)

    println("\nProcessing fidelity threshold: ", fidelity_threshold)

    # Conta le vittorie per ogni algoritmo
    for algo in algorithms
        wins = 0

        # Per ogni dataset
        for dataset in unique_datasets

            # Filtra per questo dataset con fidelity >= soglia
            subset = filter(
                row -> row.Dataset == dataset && row.Fidelity >= fidelity_threshold,
                df,
            )

            # Se non ci sono dati per questo dataset, salta
            if nrow(subset) == 0
                continue
            end

            # Filtra per l'algoritmo corrente
            algo_rows = filter(row -> row.Algorithm == algo, subset)

            if nrow(algo_rows) == 0
                continue
            end

            # Trova il minimo AVGNumAtoms per questo algoritmo
            algo_min_atoms = minimum(algo_rows.AVGNumAtoms)

            # Controlla se questo algoritmo ha il minimo atoms tra tutti
            is_winner = true

            for other_algo in algorithms
                if other_algo == algo
                    continue
                end

                other_rows = filter(row -> row.Algorithm == other_algo, subset)

                if nrow(other_rows) == 0
                    continue
                end

                # Trova il minimo AVGNumAtoms per l'altro algoritmo
                other_min_atoms = minimum(other_rows.AVGNumAtoms)

                # L'algoritmo perde se un altro ha meno atoms
                if other_min_atoms < algo_min_atoms
                    is_winner = false
                    break
                end
            end

            if is_winner
                wins += 1
            end
        end

        # Calcola la percentuale (parte intera)
        algo_idx = findfirst(x -> x == algo, algorithms)
        results[f_idx, algo_idx] = floor(Int, (wins / total_cases) * 100)

        println("  ", algo, ": ", wins, " wins -> ", results[f_idx, algo_idx], "%")
    end
end

# Scrivi il file data.dat
open("dataF.dat", "w") do io
    # Header
    write(io, "P     ")
    for algo in algorithms
        write(io, @sprintf("%-8s", algo))
    end
    write(io, "\n")

    # Dati
    for (idx, threshold) in enumerate(fidelity_thresholds)
        write(io, @sprintf("%.2f  ", threshold))
        for algo_idx = 1:length(algorithms)
            # Scrivi sempre il valore, anche se è 0
            write(io, @sprintf("%-8d", results[idx, algo_idx]))
        end
        write(io, "\n")
    end
end

println("\nFile data.dat generato con successo!")
println("Totale dataset: ", total_cases)
