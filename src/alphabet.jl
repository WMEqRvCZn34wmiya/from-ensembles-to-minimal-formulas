using Pkg
Pkg.activate(".")
using Revise
using DataFrames
using ComplexityMeasures
using DecisionTree
using CSV
using Statistics  # Per calcolare le medie
# Include all files at the beginning to avoid world age problems
include("utilsForTest.jl")
include("suitfortest.jl")
include("apiIntrees.jl")
include("apiRefne.jl")


datasets = [
    "house-votes",
    "divorce",
    "soybean-small",
    "haberman",
    "tictactoe",
    "mammographic_masses",
    "breast_cancer",
    "statlog",
    "wine",
    "cryotherapy",
    "diabets",
    "ionosphere",
    "bupa",
    "banknote",
    "htru",
    "urinary-d1",
    "penguins",
    "new-thyroid",
    "hayes-roth",
    "veichle_D",
    "hepatitis",
    "iris",
    "monks-3",
    "occupancy",
    "urinary-d2",
    "monks-1",
    "car",
    "mushroom",
    "seeds",
    "zoo",
    "veichle_E",
    "heart",
]
#======================================================================================================================================
                                                SETUP ALBERI X Y ECC...
======================================================================================================================================#
for dataset in datasets
    for ngiro in [2, 4, 8, 16, 32, 64, 100]
        println(
            "\n\n$COLORED_ULTRA_OTT$TITLE\n ADDESTRAMENTO ALBERO $dataset \n$TITLE$RESET",
        )

        f,
        model,
        start_time,
        features_train,
        labels_train,
        features_test,
        labels_test,
        features,
        labels = learn_and_convert(ngiro, dataset, 3)

        accuracy = calculate_forest_accuracy(f, features_test, labels_test)
        println("Model accuracy: $(round(accuracy * 100, digits=2))%")

        println("importance vector:", create_importance_vector(impurity_importance(model)))

        #======================================================================================================================================
                                                                        LUMEN
        ======================================================================================================================================#
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n LUMEN \n$TITLE$RESET")
        timelumen = @elapsed begin # TODO TEMPO COMPILAZIONE...
            dslumen, Lumeninfo = lumen(
                model;
                start_time=start_time,
                vertical=1.0,
                horizontal=1.0,
                ott_mode=false,
                controllo=false,
                solemodel=f,
                silent=false,
                apply_function=apply_forest,
                alphabetcontroll="$(dataset)_$(ngiro)",
                vetImportance=create_importance_vector(impurity_importance(model)),
            )
        end
    end

    # Dopo aver completato tutti i ngiro per questo dataset, calcola le medie delle ultime 3 righe
    csv_file_path = "debug_combinations_stats.csv"
    if isfile(csv_file_path)
        println("\n\n$COLORED_ULTRA_OTT$TITLE\n CALCOLO MEDIA PER $dataset \n$TITLE$RESET")

        try
            # Leggi il CSV con gestione degli errori
            df = CSV.read(
                csv_file_path,
                DataFrame,
                stringtype=String,
                silencewarnings=true,
                ignoreemptyrows=true,
            )

            println("Righe totali nel CSV: $(nrow(df))")

            # Filtra solo le righe valide (che hanno AlphabetControl non missing e non corrotto)
            valid_rows = filter(
                row ->
                    !ismissing(row.AlphabetControl) &&
                        isa(row.AlphabetControl, String) &&
                        !contains(row.AlphabetControl, "UInt8") &&
                        !contains(row.AlphabetControl, "_MEAN"),
                df,
            )

            println("Righe valide: $(nrow(valid_rows))")

            # Prendi le ultime 3 righe valide
            if nrow(valid_rows) >= 3
                last_three_rows = valid_rows[(end-2):end, :]

                println("Ultime 3 righe:")
                for i = 1:3
                    println("  $(last_three_rows[i, :AlphabetControl])")
                end

                # Campi numerici per cui calcolare la media
                numeric_columns = [
                    "NumAtoms",
                    "NumFeatures",
                    "TotalCombinations",
                    "ValidCombinations",
                    "DiscardedCombinations",
                    "ValidityRatio",
                    "AvgThresholds",
                    "MaxThresholds",
                    "MinThresholds",
                    "Vertical",
                ]

                # Prepara la riga media
                mean_row_data = String[]

                # Prendi le colonne nell'ordine del CSV originale
                for col_name in names(df)
                    if col_name == "Identifier"
                        # Usa l'identifier della prima riga aggiungendo _MEAN
                        base_id = string(last_three_rows[1, col_name])
                        push!(mean_row_data, "$(base_id)_MEAN")
                    elseif col_name == "AlphabetControl"
                        push!(mean_row_data, "$(dataset)_MEAN")
                    elseif col_name in numeric_columns
                        # Calcola la media per i campi numerici
                        values = []
                        for i = 1:3
                            val = last_three_rows[i, col_name]
                            if !ismissing(val) && isa(val, Number)
                                push!(values, val)
                            elseif !ismissing(val) && isa(val, String)
                                # Prova a convertire da stringa a numero
                                try
                                    push!(values, parse(Float64, val))
                                catch
                                    println(
                                        "Impossibile convertire $val in numero per colonna $col_name",
                                    )
                                end
                            end
                        end

                        if length(values) > 0
                            push!(mean_row_data, string(mean(values)))
                        else
                            push!(mean_row_data, "0.0")
                        end
                    else
                        # Per altri campi, usa il valore della prima riga
                        push!(mean_row_data, string(last_three_rows[1, col_name]))
                    end
                end

                # Scrivi la riga manualmente nel CSV
                open(csv_file_path, "a") do file
                    write(file, join(mean_row_data, ",") * "\n")
                end

                println("Media aggiunta per $dataset")

            else
                println(
                    "Non ci sono abbastanza righe valide nel CSV per calcolare la media",
                )
            end

        catch e
            println("Errore nella lettura/elaborazione del CSV: $e")

            # Se c'è un errore, prova a pulire il CSV rimuovendo righe corrotte
            println("Tentativo di pulizia del CSV...")

            # Leggi il file riga per riga e mantieni solo quelle valide
            lines = readlines(csv_file_path)
            valid_lines = String[]

            # Mantieni l'header
            if length(lines) > 0
                push!(valid_lines, lines[1])
            end

            # Filtra le righe valide (quelle che non contengono caratteri binari strani)
            for line in lines[2:end]
                if !contains(line, "UInt8") &&
                   !contains(line, "#undef") &&
                   length(split(line, ",")) >= 10
                    push!(valid_lines, line)
                end
            end

            # Riscrivi il CSV pulito
            open(csv_file_path, "w") do file
                for line in valid_lines
                    write(file, line * "\n")
                end
            end

            println("CSV pulito, $(length(valid_lines)-1) righe valide mantenute")
        end
    else
        println("File CSV non trovato: $csv_file_path")
    end
end

println(
    "\n\n$COLORED_ULTRA_OTT$TITLE\n COMPLETATO - MEDIE AGGIUNTE PER TUTTI I DATASET \n$TITLE$RESET",
)
