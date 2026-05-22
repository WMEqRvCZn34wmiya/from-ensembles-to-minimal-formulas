function nterm(rule)
    # Prende la parte antecedent della regola
    antecedent = rule.antecedent

    # Definisce una funzione ricorsiva per contare gli operatori OR
    function count_or_recursive(node)
        # Se non è una SyntaxBranch, ritorna 0
        if !(typeof(node) <: SyntaxBranch)
            return 0
        end

        # Conta se il nodo corrente è un operatore OR
        is_or = (typeof(node.token) <: NamedConnective{:∨}) ? 1 : 0

        # Conta ricorsivamente gli operatori OR nei figli
        count_in_children = 0
        if isdefined(node, :children)
            for child in node.children
                count_in_children += count_or_recursive(child)
            end
        end

        # Restituisce la somma
        return is_or + count_in_children
    end

    # Esegue la funzione ricorsiva sull'antecedente
    return count_or_recursive(antecedent) + 1
end

function nterm(rules::Vector)
    # Usa map per applicare nterm a ogni regola nel dataset
    return map(nterm, rules)
end

function calcola_percentuali(vettore::Vector{String})
    """
    Calcola la percentuale di occorrenza di ciascuna stringa unica nel vettore.

    Args:
        vettore: Un vettore di stringhe
        
    Returns:
        Un dizionario con le stringhe come chiavi e le loro percentuali come valori
    """
    # Calcola il numero totale di elementi
    totale = length(vettore)

    # Inizializza un dizionario per contare le occorrenze
    conteggio = Dict{String,Int}()

    # Conta le occorrenze di ciascuna stringa
    for stringa in vettore
        conteggio[stringa] = get(conteggio, stringa, 0) + 1
    end

    # Calcola le percentuali
    percentuali = Dict{String,Float64}()
    for (stringa, count) in conteggio
        percentuali[stringa] = (count / totale) * 100
    end

    return percentuali
end

# Funzione per analizzare il bilanciamento del dataset e scrivere su file
function analizza_bilanciamento_su_file(
    labels_train::Vector{String},
    labels_test::Vector{String},
    nome_file::String = "bilanciamento_dataset.txt",
)
    # Apri il file in modalità scrittura
    open(nome_file, "w") do file
        # Analisi del dataset di train
        train_totale = length(labels_train)
        train_percentuali = calcola_percentuali(labels_train)
        train_conteggio = Dict{String,Int}()

        for stringa in labels_train
            train_conteggio[stringa] = get(train_conteggio, stringa, 0) + 1
        end

        write(file, "ANALISI BILANCIAMENTO DATASET\n")
        write(file, "==========================\n\n")
        write(file, "Dataset train:\n")
        write(file, "Totale elementi: $train_totale\n")
        write(file, "Percentuali: $train_percentuali\n\n")
        write(file, "Dettaglio conteggio train:\n")

        for (stringa, count) in train_conteggio
            percentuale = (count / train_totale) * 100
            write(
                file,
                "'$stringa': $count occorrenze ($(round(percentuale, digits=2))%)\n",
            )
        end

        # Analisi del dataset di test
        test_totale = length(labels_test)
        test_percentuali = calcola_percentuali(labels_test)
        test_conteggio = Dict{String,Int}()

        for stringa in labels_test
            test_conteggio[stringa] = get(test_conteggio, stringa, 0) + 1
        end

        write(file, "\nDataset test:\n")
        write(file, "Totale elementi: $test_totale\n")
        write(file, "Percentuali: $test_percentuali\n\n")
        write(file, "Dettaglio conteggio test:\n")

        for (stringa, count) in test_conteggio
            percentuale = (count / test_totale) * 100
            write(
                file,
                "'$stringa': $count occorrenze ($(round(percentuale, digits=2))%)\n",
            )
        end

        # Confronto tra train e test
        write(file, "\nCONFRONTO TRAIN/TEST:\n")
        write(file, "====================\n")
        classi_uniche =
            unique(vcat(collect(keys(train_conteggio)), collect(keys(test_conteggio))))

        write(file, "Classe\tTrain%\tTest%\tDiff\n")
        for classe in classi_uniche
            train_perc = get(train_percentuali, classe, 0.0)
            test_perc = get(test_percentuali, classe, 0.0)
            differenza = abs(train_perc - test_perc)
            write(
                file,
                "$classe\t$(round(train_perc, digits=2))%\t$(round(test_perc, digits=2))%\t$(round(differenza, digits=2))%\n",
            )
        end
    end

    println("Analisi del bilanciamento salvata nel file '$nome_file'")
end


function calcola_percentuali2(vettore::Vector{String})
    """
    Calcola la percentuale di occorrenza di ciascuna stringa unica nel vettore.

    Args:
        vettore: Un vettore di stringhe
        
    Returns:
        Un dizionario con le stringhe come chiavi e le loro percentuali come valori
    """
    # Calcola il numero totale di elementi
    totale = length(vettore)

    # Inizializza un dizionario per contare le occorrenze
    conteggio = Dict{String,Int}()

    # Conta le occorrenze di ciascuna stringa
    for stringa in vettore
        conteggio[stringa] = get(conteggio, stringa, 0) + 1
    end

    # Calcola le percentuali
    percentuali = Dict{String,Float64}()
    for (stringa, count) in conteggio
        percentuali[stringa] = (count / totale) * 100
    end

    return percentuali
end

# Funzione per analizzare il bilanciamento del dataset
function analizza_bilanciamento2(vettore::Vector{String})
    totale = length(vettore)
    conteggio = Dict{String,Int}()

    for stringa in vettore
        conteggio[stringa] = get(conteggio, stringa, 0) + 1
    end

    println("Totale elementi: $totale")
    println("\nConteggio per classe:")
    for (stringa, count) in conteggio
        percentuale = (count / totale) * 100
        println("'$stringa': $count occorrenze ($(round(percentuale, digits=2))%)")
    end

    # Analizza il bilanciamento
    if length(conteggio) == 1
        println("\nIl dataset non è bilanciato: contiene solo una classe.")
    elseif length(conteggio) > 1
        min_perc = minimum(values(conteggio)) / totale * 100
        max_perc = maximum(values(conteggio)) / totale * 100

        if max_perc / min_perc > 3
            println("\nIl dataset è fortemente sbilanciato (rapporto > 3:1).")
        elseif max_perc / min_perc > 1.5
            println("\nIl dataset è moderatamente sbilanciato.")
        else
            println("\nIl dataset è relativamente bilanciato.")
        end
    end
end
# Esempio di utilizzo:
# labels_train = ["no", "no", "yes", ...]
# labels_test = ["no", "yes", "yes", ...]
# analizza_bilanciamento_su_file(labels_train, labels_test)
# Oppure con un nome file personalizzato:
# analizza_bilanciamento_su_file(labels_train, labels_test, "mio_report_bilanciamento.txt")


function create_importance_vector(importances)
    # Crea coppie (indice, valore)
    indexed_importances = [(i, imp) for (i, imp) in enumerate(importances)]

    # Ordina per importanza decrescente
    sort!(indexed_importances, by = x -> x[2], rev = true)

    # Estrai solo gli indici
    return [idx for (idx, _) in indexed_importances]
end

# Applicando la funzione
