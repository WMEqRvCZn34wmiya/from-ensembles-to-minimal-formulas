using CSV
using DataFrames
using Printf

# Leggi il CSV
df = CSV.read(
    "/Users/perry/.julia/dev/ModalMinimizerRulesSystematicApp/tab2_randomforest_bk.csv",
    DataFrame,
)

# Lista degli algoritmi
algorithms = ["Lumen", "REFNE", "InTrees", "RuleCOSI+", "BATrees", "TREPAN"]

# Range di sensitivity e specificity da 0.0 a 1.0 con passo 0.1
thresholds = 0.00:0.05:1.00  # 101 righe

# Numero totale di dataset unici
unique_datasets = unique(df.Dataset)
total_cases = length(unique_datasets)

println("Totale dataset unici: ", total_cases)

# Inizializza la matrice dei risultati (sensitivity x specificity x algorithms)
results = zeros(Int, length(thresholds), length(thresholds), length(algorithms))

# Per ogni soglia di sensitivity
for (sens_idx, sens_threshold) in enumerate(thresholds)
    println("\nProcessing sensitivity threshold: ", sens_threshold)

    # Per ogni soglia di specificity
    for (spec_idx, spec_threshold) in enumerate(thresholds)
        if sens_idx % 10 == 1 && spec_idx % 10 == 1  # Stampa meno output per non appesantire
            println("  Processing specificity threshold: ", spec_threshold)
        end

        # Conta le vittorie per ogni algoritmo
        for algo in algorithms
            wins = 0

            # Per ogni dataset
            for dataset in unique_datasets
                # Filtra per questo dataset con sensitivity e specificity >= soglie
                subset = filter(
                    row ->
                        row.Dataset == dataset &&
                            row.AVGSensitivity >= sens_threshold &&
                            row.AVGSpecificity >= spec_threshold,
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
            results[sens_idx, spec_idx, algo_idx] = floor(Int, (wins / total_cases) * 100)
        end
    end
end

# Scrivi il file data.dat
open("datasensandspec.dat", "w") do io
    # Header per ogni combinazione sens/spec
    write(io, "Sens    Spec    ")
    for algo in algorithms
        write(io, @sprintf("%-8s", algo))
    end
    write(io, "\n")

    # Dati per ogni combinazione
    for (sens_idx, sens_threshold) in enumerate(thresholds)
        for (spec_idx, spec_threshold) in enumerate(thresholds)
            # CORREZIONE: usa %.2f invece di %.1f per mostrare 2 decimali
            write(io, @sprintf("%.2f   %.2f   ", sens_threshold, spec_threshold))
            for algo_idx = 1:length(algorithms)
                # Scrivi sempre il valore, anche se è 0
                write(io, @sprintf("%-8d", results[sens_idx, spec_idx, algo_idx]))
            end
            write(io, "\n")
        end
    end
end

println("\nFile data.dat generato con successo!")
println("Totale dataset: ", total_cases)
println("Combinazioni testate: ", length(thresholds) * length(thresholds))
