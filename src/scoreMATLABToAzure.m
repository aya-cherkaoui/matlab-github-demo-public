function result = scoreMATLABToAzure(features, scoringUri, apiKey)
%SCOREMATLABTOAZURE  Appeler un endpoint Azure ML depuis MATLAB Online.
%
%   *** Compatible MATLAB Online ***
%   Utilise uniquement webwrite (API REST). Aucune dépendance Python.
%
%   result = SCOREMATLABTOAZURE(features, scoringUri, apiKey)
%
%   Envoie des features de signal à un endpoint managé Azure ML
%   et retourne la prédiction (classe + score de confiance).
%
%   Inputs
%   ------
%   features   — Vecteur de features (1×N double) ou matrice (M×N)
%   scoringUri — URL de scoring de l'endpoint Azure ML
%                (trouvable dans Azure ML Studio → Endpoints → Consume)
%   apiKey     — Clé API de l'endpoint (Primary ou Secondary key)
%                (trouvable dans Azure ML Studio → Endpoints → Consume)
%
%   Output
%   ------
%   result — struct avec :
%       .predictedClass — Classe prédite (string)
%       .confidence     — Score de confiance (0-1)
%       .allScores      — Scores pour toutes les classes
%       .responseTime   — Temps de réponse (ms)
%       .rawResponse    — Réponse brute du serveur
%
%   Exemple
%   -------
%       % 1. Générer un signal et extraire des features
%       [t, ~, sig] = generateSignal(1000, 1, [5 8], 0.2);
%       res = analyseSignal(t, sig, 1000);
%       features = [res.rmsVal, res.stdVal, res.snrEstimate, res.peakFreqs];
%
%       % 2. Renseigner l'URL et la clé (depuis Azure ML Studio)
%       uri = 'https://matlab-signal-classifier.francecentral.inference.ml.azure.com/score';
%       key = 'votre-clé-api';
%
%       % 3. Scorer
%       prediction = scoreMATLABToAzure(features, uri, key);
%       fprintf('Classe: %s (confiance: %.1f%%)\n', ...
%           prediction.predictedClass, prediction.confidence * 100);
%
%   Voir aussi AZUREMLCONNECT, TRAINANDEXPORTMODEL

    arguments
        features   (:,:) double
        scoringUri (1,1) string
        apiKey     (1,1) string
    end

    %% ---- Préparer la requête --------------------------------------------
    fprintf('[Score] Préparation de la requête ...\n');

    if isvector(features)
        dataPayload = features(:)';
    else
        dataPayload = features;
    end

    % Construire le JSON au format attendu par Azure ML
    requestBody = struct();
    requestBody.input_data = struct();
    requestBody.input_data.columns = arrayfun(@(i) sprintf('feature_%d', i), ...
        1:size(dataPayload, 2), 'UniformOutput', false);

    % Convertir la matrice en cell array pour jsonencode
    if size(dataPayload, 1) == 1
        requestBody.input_data.data = {num2cell(dataPayload)};
    else
        dataCell = cell(size(dataPayload, 1), 1);
        for r = 1:size(dataPayload, 1)
            dataCell{r} = num2cell(dataPayload(r, :));
        end
        requestBody.input_data.data = dataCell;
    end

    jsonPayload = jsonencode(requestBody);

    %% ---- Appel REST à l'endpoint ----------------------------------------
    fprintf('[Score] Appel endpoint (%d features) ...\n', size(dataPayload, 2));
    fprintf('[Score] URI : %s\n', scoringUri);

    opts = weboptions( ...
        'MediaType',    'application/json', ...
        'ContentType',  'json', ...
        'HeaderFields', { ...
            'Authorization', sprintf('Bearer %s', apiKey); ...
            'Content-Type', 'application/json' ...
        }, ...
        'Timeout',      30 ...
    );

    tic;
    try
        response = webwrite(scoringUri, jsonPayload, opts);
        responseTime = toc * 1000;  % ms
    catch ME
        error('scoreMATLABToAzure:requestFailed', ...
            ['Erreur lors de l''appel endpoint.\n' ...
             'Vérifiez scoringUri et apiKey.\n' ...
             'Erreur : %s'], ME.message);
    end

    %% ---- Parser la réponse ----------------------------------------------
    result = struct();
    result.rawResponse = response;

    if isstruct(response)
        if isfield(response, 'predictions')
            preds = response.predictions;
            if iscell(preds)
                result.predictedClass = string(preds{1});
            else
                result.predictedClass = string(preds(1));
            end
        elseif isfield(response, 'result')
            result.predictedClass = string(response.result);
        end

        if isfield(response, 'scores')
            result.allScores = response.scores;
            if isstruct(response.scores)
                vals = struct2array(response.scores);
                result.confidence = max(vals);
            elseif isnumeric(response.scores)
                result.confidence = max(response.scores);
            else
                result.confidence = NaN;
            end
        else
            result.confidence = NaN;
            result.allScores = [];
        end
    elseif ischar(response) || isstring(response)
        result.predictedClass = string(response);
        result.confidence = NaN;
        result.allScores = [];
    else
        result.predictedClass = "unknown";
        result.confidence = NaN;
        result.allScores = [];
    end

    result.responseTime = responseTime;

    fprintf('[Score] ✓ Prédiction : %s (confiance: %.1f%%, temps: %.0f ms)\n', ...
        result.predictedClass, result.confidence * 100, result.responseTime);

end
