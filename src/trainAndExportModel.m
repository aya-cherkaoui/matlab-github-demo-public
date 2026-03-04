function modelPath = trainAndExportModel(exportFormat)
%TRAINANDEXPORTMODEL  Entraîner un classificateur de signaux et exporter.
%
%   *** Compatible MATLAB Online ***
%   L'entraînement utilise le Deep Learning Toolbox natif MATLAB.
%   Le tracking Azure ML utilise l'API REST MLflow (webwrite).
%   Aucune dépendance Python requise.
%
%   modelPath = TRAINANDEXPORTMODEL()        — export ONNX par défaut
%   modelPath = TRAINANDEXPORTMODEL('onnx')  — export ONNX
%   modelPath = TRAINANDEXPORTMODEL('mat')   — export .mat MATLAB natif
%
%   Cette fonction :
%   1. Génère un dataset synthétique de signaux (3 classes)
%   2. Définit une architecture LSTM pour la classification
%   3. Entraîne le réseau dans MATLAB Online
%   4. Exporte le modèle au format ONNX (ou .mat)
%   5. Logge les métriques dans Azure ML via REST (optionnel)
%
%   Classes de signaux
%   ------------------
%   Classe 1 : Basses fréquences (1-10 Hz)   → "low_freq"
%   Classe 2 : Moyennes fréquences (10-50 Hz) → "mid_freq"
%   Classe 3 : Hautes fréquences (50-200 Hz)  → "high_freq"
%
%   Pré-requis
%   ----------
%   - Deep Learning Toolbox
%   - Signal Processing Toolbox
%   - azure-ml/config.json renseigné (pour tracking — optionnel)
%
%   Voir aussi AZUREMLCONNECT, MAINWITHAZUREML, GENERATESIGNAL

    arguments
        exportFormat (1,1) string {mustBeMember(exportFormat, ...
            ["onnx", "mat"])} = "onnx"
    end

    fprintf('╔══════════════════════════════════════════════════════╗\n');
    fprintf('║   Entraînement — Classificateur de Signaux          ║\n');
    fprintf('║   (MATLAB Online — Deep Learning Toolbox)           ║\n');
    fprintf('╚══════════════════════════════════════════════════════╝\n\n');

    modelsDir = fullfile(pwd, 'models');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end

    %% ---- 1. Génération du dataset synthétique ---------------------------
    fprintf('[1/5] Génération du dataset d''entraînement ...\n');

    fs = 1000;           % Hz
    duration = 1;        % seconde
    nSamplesPerClass = 200;
    noiseLevel = 0.3;

    classNames = categorical(["low_freq", "mid_freq", "high_freq"]);
    freqRanges = {[1, 10], [10, 50], [50, 200]};

    XTrain = {};
    YTrain = categorical.empty(0, 1);

    rng(42, 'twister');  % reproductibilité

    for c = 1:3
        fRange = freqRanges{c};
        for i = 1:nSamplesPerClass
            nFreqs = randi([1, 3]);
            freqs = fRange(1) + (fRange(2) - fRange(1)) * rand(1, nFreqs);

            [~, ~, sig] = generateSignal(fs, duration, freqs, noiseLevel);
            XTrain{end+1} = sig(:)'; %#ok<AGROW>
            YTrain(end+1) = classNames(c);  %#ok<AGROW>
        end
    end

    YTrain = YTrain(:);
    fprintf('      Dataset : %d échantillons, %d classes\n', ...
        numel(XTrain), numel(categories(classNames)));

    % Split train/validation (80/20)
    nTotal = numel(XTrain);
    idx = randperm(nTotal);
    nTrain = round(0.8 * nTotal);

    XTrainSet = XTrain(idx(1:nTrain));
    YTrainSet = YTrain(idx(1:nTrain));
    XValSet   = XTrain(idx(nTrain+1:end));
    YValSet   = YTrain(idx(nTrain+1:end));

    % Garantir le type categorical attendu par trainNetwork
    YTrainSet = categorical(YTrainSet);
    YValSet   = categorical(YValSet);

    fprintf('      Train : %d | Validation : %d\n', nTrain, nTotal - nTrain);

    %% ---- 2. Définition de l'architecture LSTM ---------------------------
    fprintf('[2/5] Définition de l''architecture LSTM ...\n');

    inputSize = 1;
    numClasses = 3;
    numHiddenUnits = 100;

    layers = [ ...
        sequenceInputLayer(inputSize, 'Name', 'input')
        lstmLayer(numHiddenUnits, 'OutputMode', 'last', 'Name', 'lstm1')
        dropoutLayer(0.3, 'Name', 'dropout')
        fullyConnectedLayer(numClasses, 'Name', 'fc')
        softmaxLayer('Name', 'softmax')
        classificationLayer('Name', 'output')
    ];

    fprintf('      Architecture : Input → LSTM(%d) → Dropout → FC → Softmax\n', ...
        numHiddenUnits);

    %% ---- 3. Options d'entraînement --------------------------------------
    fprintf('[3/5] Configuration de l''entraînement ...\n');

    options = trainingOptions('adam', ...
        'MaxEpochs',          30, ...
        'MiniBatchSize',      32, ...
        'InitialLearnRate',   0.001, ...
        'ValidationData',     {XValSet, YValSet}, ...
        'ValidationFrequency', 10, ...
        'Shuffle',            'every-epoch', ...
        'Verbose',            true, ...
        'Plots',              'training-progress');

    %% ---- 4. Entraînement ------------------------------------------------
    fprintf('[4/5] Entraînement du modèle ...\n');
    [net, trainInfo] = trainNetwork(XTrainSet, YTrainSet, layers, options);

    % Évaluer sur le set de validation
    YPred = classify(net, XValSet);
    accuracy = sum(YPred == YValSet) / numel(YValSet) * 100;
    fprintf('      Accuracy (validation) : %.1f%%\n', accuracy);

    %% ---- 5. Export et enregistrement ------------------------------------
    fprintf('[5/5] Export du modèle ...\n');

    if exportFormat == "onnx"
        modelPath = fullfile(modelsDir, 'signal_classifier.onnx');
        exportONNXNetwork(net, modelPath);
        fprintf('      Exporté en ONNX → %s\n', modelPath);
    else
        modelPath = fullfile(modelsDir, 'signal_classifier.mat');
        save(modelPath, 'net', 'trainInfo', 'accuracy', 'classNames');
        fprintf('      Exporté en MAT → %s\n', modelPath);
    end

    %% ---- Tracking Azure ML (optionnel — via API REST) -------------------
    try
        conn = azureMLConnect();
        mlflowBase = conn.mlflowUri;
        mlflowOpts = weboptions( ...
            'HeaderFields', { ...
                'Authorization', sprintf('Bearer %s', conn.accessToken); ...
                'Content-Type',  'application/json' ...
            }, ...
            'ContentType', 'json', ...
            'MediaType',   'application/json', ...
            'Timeout',     30);

        % Créer ou récupérer l'expérience
        expName = 'matlab-signal-classification';
        try
            expResp = webwrite( ...
                sprintf('%s/api/2.0/mlflow/experiments/create', mlflowBase), ...
                jsonencode(struct('name', expName)), mlflowOpts);
            experimentId = expResp.experiment_id;
        catch
            expResp = webread( ...
                sprintf('%s/api/2.0/mlflow/experiments/get-by-name?experiment_name=%s', ...
                    mlflowBase, expName), mlflowOpts);
            experimentId = expResp.experiment.experiment_id;
        end

        % Créer un run
        runName = sprintf('train-%s', datestr(now, 'yyyymmdd-HHMMSS'));
        runResp = webwrite( ...
            sprintf('%s/api/2.0/mlflow/runs/create', mlflowBase), ...
            jsonencode(struct('experiment_id', experimentId, 'run_name', runName)), ...
            mlflowOpts);
        runId = runResp.run.info.run_id;

        % Logger les paramètres
        params = { ...
            'architecture',   'LSTM'; ...
            'hidden_units',   num2str(numHiddenUnits); ...
            'epochs',         '30'; ...
            'learning_rate',  '0.001'; ...
            'batch_size',     '32'; ...
            'export_format',  char(exportFormat); ...
            'num_classes',    num2str(numClasses); ...
            'train_samples',  num2str(nTrain); ...
            'val_samples',    num2str(nTotal - nTrain) ...
        };
        for k = 1:size(params, 1)
            body = struct('run_id', runId, 'key', params{k,1}, 'value', params{k,2});
            webwrite(sprintf('%s/api/2.0/mlflow/runs/log-parameter', mlflowBase), ...
                jsonencode(body), mlflowOpts);
        end

        % Logger les métriques
        ts = round(posixtime(datetime('now'))*1000);
        metrics = {'validation_accuracy', accuracy; 'final_loss', trainInfo.TrainingLoss(end)};
        for k = 1:size(metrics, 1)
            body = struct('run_id', runId, 'key', metrics{k,1}, ...
                'value', metrics{k,2}, 'timestamp', ts);
            webwrite(sprintf('%s/api/2.0/mlflow/runs/log-metric', mlflowBase), ...
                jsonencode(body), mlflowOpts);
        end

        % Terminer le run
        body = struct('run_id', runId, 'status', 'FINISHED', 'end_time', ts);
        webwrite(sprintf('%s/api/2.0/mlflow/runs/update', mlflowBase), ...
            jsonencode(body), mlflowOpts);

        fprintf('      Métriques loggées dans Azure ML ✓\n');
        fprintf('      Expérience : %s | Run : %s\n', expName, runName);

    catch ME
        if contains(ME.message, 'Authentication to workspace storage account failed')
            fprintf(['      [Warning] Azure ML tracking indisponible: ' ...
                     'droits manquants sur le storage du workspace.\n']);
            fprintf(['      Action: attribuez le rôle "Storage Blob Data Contributor" ' ...
                     'sur le storage account lié au workspace.\n']);
            fprintf('      Le modèle a bien été sauvé localement.\n');
        else
            fprintf('      [Info] Tracking Azure ML non disponible : %s\n', ME.message);
            fprintf('      Le modèle a été sauvé localement.\n');
        end
    end

    fprintf('\n✓ Entraînement terminé — Modèle : %s\n', modelPath);

end
