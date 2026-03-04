function mainWithAzureML()
%MAINWITHAZUREML  Pipeline principale avec tracking Azure Machine Learning.
%
%   *** Compatible MATLAB Online ***
%   Utilise les API REST MLflow (webwrite/webread) pour le tracking.
%   Aucune dépendance Python requise.
%
%   MAINWITHAZUREML exécute la même pipeline que main.m, mais ajoute :
%   - Le logging des métriques dans Azure ML via l'API REST MLflow
%   - L'upload des artefacts (graphiques, rapport) via l'API REST
%   - Le tracking de l'expérience pour comparaison entre runs
%
%   Pré-requis
%   ----------
%   - Fichier azure-ml/config.json renseigné (token ou tenant_id)
%   - Workspace Azure ML provisionné
%   - Signal Processing Toolbox
%
%   Usage (dans MATLAB Online)
%   --------------------------
%       >> mainWithAzureML
%
%   Voir aussi MAIN, AZUREMLCONNECT, TRAINANDEXPORTMODEL

    clear; clc; close all;

    %% ---- Configuration --------------------------------------------------
    config.sampleRate   = 1000;
    config.duration     = 2;
    config.noiseLevel   = 0.3;
    config.signalFreq   = [5, 12, 30];
    config.outputDir    = fullfile(pwd, 'results');
    config.dataDir      = fullfile(pwd, 'data');

    fprintf('╔══════════════════════════════════════════════════════╗\n');
    fprintf('║   MATLAB Online + Azure ML — Pipeline avec Tracking ║\n');
    fprintf('╚══════════════════════════════════════════════════════╝\n\n');

    %% ---- Connexion Azure ML (REST) --------------------------------------
    fprintf('[0/5] Connexion à Azure Machine Learning ...\n');
    conn = azureMLConnect();

    %% ---- Créer / récupérer l'expérience MLflow (REST) -------------------
    fprintf('[1/5] Démarrage du tracking MLflow (REST API) ...\n');

    mlflowBase = conn.mlflowUri;
    mlflowOpts = weboptions( ...
        'HeaderFields', { ...
            'Authorization', sprintf('Bearer %s', conn.accessToken); ...
            'Content-Type',  'application/json' ...
        }, ...
        'ContentType', 'json', ...
        'MediaType',   'application/json', ...
        'Timeout',     30);

    % Créer ou obtenir l'expérience
    experimentName = 'matlab-signal-analysis';
    try
        expResp = webwrite( ...
            sprintf('%s/api/2.0/mlflow/experiments/create', mlflowBase), ...
            jsonencode(struct('name', experimentName)), ...
            mlflowOpts);
        experimentId = expResp.experiment_id;
    catch
        % L'expérience existe déjà → la récupérer
        expResp = webread( ...
            sprintf('%s/api/2.0/mlflow/experiments/get-by-name?experiment_name=%s', ...
                mlflowBase, experimentName), ...
            mlflowOpts);
        experimentId = expResp.experiment.experiment_id;
    end
    fprintf('      Expérience : %s (ID: %s)\n', experimentName, experimentId);

    % Créer un run
    runName = sprintf('matlab-online-%s', datestr(now, 'yyyymmdd-HHMMSS'));
    runResp = webwrite( ...
        sprintf('%s/api/2.0/mlflow/runs/create', mlflowBase), ...
        jsonencode(struct( ...
            'experiment_id', experimentId, ...
            'run_name',      runName, ...
            'tags',          {{ ...
                struct('key', 'mlflow.source.name', 'value', 'MATLAB Online'), ...
                struct('key', 'mlflow.source.type', 'value', 'LOCAL'), ...
                struct('key', 'matlab_version', 'value', version) ...
            }} ...
        )), ...
        mlflowOpts);
    runId = runResp.run.info.run_id;
    fprintf('      Run créé : %s (ID: %s)\n', runName, runId);

    trackingEnabled = true;

    try
        % Logger les paramètres
        if trackingEnabled
            try
                logParams(mlflowBase, runId, mlflowOpts, { ...
                    'sample_rate',        num2str(config.sampleRate); ...
                    'duration',           num2str(config.duration); ...
                    'noise_level',        num2str(config.noiseLevel); ...
                    'signal_frequencies', mat2str(config.signalFreq) ...
                });
            catch trackingError
                trackingEnabled = handleTrackingError(trackingError);
            end
        end

        %% ---- Step 1 : Générer les données --------------------------------
        fprintf('[2/5] Génération du signal synthétique ...\n');
        [t, cleanSignal, noisySignal] = generateSignal( ...
            config.sampleRate, config.duration, ...
            config.signalFreq, config.noiseLevel);

        if ~exist(config.dataDir, 'dir'), mkdir(config.dataDir); end
        if ~exist(config.outputDir, 'dir'), mkdir(config.outputDir); end

        save(fullfile(config.dataDir, 'raw_signal.mat'), ...
            't', 'cleanSignal', 'noisySignal', 'config');

        %% ---- Step 2 : Analyse -------------------------------------------
        fprintf('[3/5] Analyse spectrale ...\n');
        analysisResults = analyseSignal(t, noisySignal, config.sampleRate);

        % Logger les métriques dans Azure ML via MLflow REST
        if trackingEnabled
            try
                logMetrics(mlflowBase, runId, mlflowOpts, { ...
                    'snr_db',     analysisResults.snrEstimate; ...
                    'rms',        analysisResults.rmsVal; ...
                    'std_dev',    analysisResults.stdVal; ...
                    'mean',       analysisResults.meanVal; ...
                    'num_peaks',  numel(analysisResults.peakFreqs) ...
                });
            catch trackingError
                trackingEnabled = handleTrackingError(trackingError);
            end
        end

        for k = 1:numel(analysisResults.peakFreqs)
            if trackingEnabled
                try
                    logMetrics(mlflowBase, runId, mlflowOpts, { ...
                        sprintf('peak_%d_freq_hz', k), analysisResults.peakFreqs(k); ...
                        sprintf('peak_%d_power', k),   analysisResults.peakPowers(k) ...
                    });
                catch trackingError
                    trackingEnabled = handleTrackingError(trackingError);
                end
            end
        end

        if trackingEnabled
            fprintf('      Métriques loggées dans Azure ML ✓\n');
        else
            fprintf('      [Info] Tracking MLflow désactivé (droits storage insuffisants).\n');
        end

        %% ---- Step 3 : Visualisation -------------------------------------
        fprintf('[4/5] Génération des graphiques ...\n');
        figHandles = visualiseResults(t, cleanSignal, noisySignal, ...
            analysisResults, config);

        for k = 1:numel(figHandles)
            figName = get(figHandles(k), 'Name');
            safeName = matlab.lang.makeValidName(figName);
            figPath = fullfile(config.outputDir, [safeName '.png']);
            exportgraphics(figHandles(k), figPath, 'Resolution', 150);
            fprintf('      Exporté : %s.png\n', safeName);
        end

        %% ---- Step 4 : Rapport et résultats -----------------------------
        fprintf('[5/5] Sauvegarde des résultats ...\n');

        save(fullfile(config.outputDir, 'analysis_results.mat'), ...
            'analysisResults');

        reportPath = fullfile(config.outputDir, 'summary_report.txt');
        generateReport(analysisResults, config, reportPath);
        fprintf('      Rapport généré : summary_report.txt\n');

        % Marquer le run comme terminé (SUCCESS)
        if trackingEnabled
            finishRun(mlflowBase, runId, mlflowOpts, 'FINISHED');
            logTag(mlflowBase, runId, mlflowOpts, 'status', 'success');
        end

    catch ME
        % En cas d'erreur, terminer le run avec statut FAILED
        if trackingEnabled
            try
                logTag(mlflowBase, runId, mlflowOpts, 'status', 'failed');
                logTag(mlflowBase, runId, mlflowOpts, 'error', ME.message);
                finishRun(mlflowBase, runId, mlflowOpts, 'FAILED');
            catch
            end
        end
        rethrow(ME);
    end

    fprintf('\n╔══════════════════════════════════════════════════════╗\n');
    fprintf('║   Pipeline terminée — résultats dans Azure ML Studio ║\n');
    fprintf('╚══════════════════════════════════════════════════════╝\n');
    fprintf('\nOuvrez Azure ML Studio pour visualiser les métriques :\n');
    fprintf('  https://ml.azure.com\n');
    fprintf('  Expérience : %s\n', experimentName);
    fprintf('  Run        : %s\n\n', runName);

end


%% ========================================================================
%  FONCTIONS LOCALES — Helpers API REST MLflow
%  ========================================================================

function logParams(baseUri, runId, opts, paramPairs)
%LOGPARAMS  Logger des paramètres via l'API REST MLflow.
%   paramPairs : cellule Nx2 {'key1','val1'; 'key2','val2'; ...}
    for k = 1:size(paramPairs, 1)
        body = struct('run_id', runId, ...
            'key', paramPairs{k,1}, 'value', paramPairs{k,2});
        webwrite(sprintf('%s/api/2.0/mlflow/runs/log-parameter', baseUri), ...
            jsonencode(body), opts);
    end
end

function logMetrics(baseUri, runId, opts, metricPairs)
%LOGMETRICS  Logger des métriques via l'API REST MLflow.
%   metricPairs : cellule Nx2 {'key1', numVal1; 'key2', numVal2; ...}
    for k = 1:size(metricPairs, 1)
        body = struct('run_id', runId, ...
            'key', metricPairs{k,1}, 'value', metricPairs{k,2}, ...
            'timestamp', round(posixtime(datetime('now'))*1000));
        webwrite(sprintf('%s/api/2.0/mlflow/runs/log-metric', baseUri), ...
            jsonencode(body), opts);
    end
end

function logTag(baseUri, runId, opts, key, value)
%LOGTAG  Logger un tag via l'API REST MLflow.
    body = struct('run_id', runId, 'key', key, 'value', value);
    webwrite(sprintf('%s/api/2.0/mlflow/runs/set-tag', baseUri), ...
        jsonencode(body), opts);
end

function finishRun(baseUri, runId, opts, status)
%FINISHRUN  Terminer un run MLflow (FINISHED ou FAILED).
    body = struct('run_id', runId, 'status', status, ...
        'end_time', round(posixtime(datetime('now'))*1000));
    webwrite(sprintf('%s/api/2.0/mlflow/runs/update', baseUri), ...
        jsonencode(body), opts);
end

function isEnabled = handleTrackingError(ME)
%HANDLETRACKINGERROR  Gère les erreurs MLflow non bloquantes.
    if contains(ME.message, 'Authentication to workspace storage account failed')
        fprintf(['      [Warning] Azure ML a refusé l''écriture MLflow: ' ...
                 'droits sur le storage du workspace manquants.\n']);
        isEnabled = false;
        return;
    end

    rethrow(ME);
end
