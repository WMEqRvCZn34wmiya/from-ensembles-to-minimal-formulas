function calculate_rule_accuracy(rule, features_test, labels_test)
    # Determina il numero di features dal dataset di test
    num_features = size(features_test, 2)

    # Genera dinamicamente i nomi delle colonne (V1, V2, V3, ...)
    column_names = ["V$i" for i = 1:num_features]

    # Converti i dati di test in formato appropriato
    test_data = SoleData.scalarlogiset(
        DataFrame(features_test, column_names);
        allow_propositional = true,
    )

    # Valuta la regola sui dati di test usando la tua funzione evaluaterule
    evaluation = SoleModels.evaluaterule(rule, test_data, labels_test)

    # Estrai la checkmask (istanze dove l'antecedente è soddisfatto)
    checkmask = evaluation.checkmask

    # Calcola l'accuratezza: per le istanze dove l'antecedente è soddisfatto,
    # verifica se il consequent corrisponde alla label vera
    correct_predictions = 0
    total_predictions = 0

    for i = 1:length(checkmask)
        if checkmask[i]  # Se l'antecedente è soddisfatto
            total_predictions += 1
            # Verifica se la predizione del consequent è corretta
            if outcome(consequent(rule)) == labels_test[i]
                correct_predictions += 1
            end
        end
    end

    # Calcola l'accuratezza (gestisci il caso dove non ci sono predizioni)
    accuracy = total_predictions > 0 ? correct_predictions / total_predictions : 0.0

    return accuracy
end
