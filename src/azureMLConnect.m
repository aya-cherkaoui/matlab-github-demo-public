function connection = azureMLConnect(configPath)
%AZUREMLCONNECT  Établir une connexion au workspace Azure Machine Learning.
%
%   connection = AZUREMLCONNECT()           — utilise azure-ml/config.json
%   connection = AZUREMLCONNECT(configPath) — chemin custom vers le config
%
%   *** Compatible MATLAB Online ***
%   Utilise uniquement les API REST Azure (webwrite/webread).
%   Aucune dépendance Python requise.
%
%   Authentification
%   ----------------
%   Deux modes supportés (dans cet ordre de priorité) :
%
%   1. Token pré-configuré : renseignez "access_token" dans config.json
%      Obtenu via : az account get-access-token --resource
%                   https://management.azure.com --query accessToken -o tsv
%
%   2. Device Code Flow : le script affiche un code et une URL.
%      Ouvrez l'URL dans votre navigateur et entrez le code pour
%      vous authentifier. Nécessite "tenant_id" dans config.json.
%
%   Sortie
%   ------
%   connection — struct avec les champs :
%       .subscriptionId  — ID de la subscription Azure
%       .resourceGroup   — Nom du resource group
%       .workspaceName   — Nom du workspace Azure ML
%       .accessToken     — Bearer token pour les appels REST
%       .baseUrl         — URL de base de l'API Azure ML
%       .mlflowUri       — URI du tracking MLflow
%       .location        — Région Azure du workspace
%
%   Exemple
%   -------
%       conn = azureMLConnect();
%       fprintf('Connecté à : %s (%s)\n', conn.workspaceName, conn.location);
%
%   Voir aussi MAINWITHAZUREML, TRAINANDEXPORTMODEL, SCOREMATLABTOAZURE

    arguments
        configPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), ...
            '..', 'azure-ml', 'config.json')
    end

    %% ---- Lire le fichier de configuration --------------------------------
    fprintf('[Azure ML] Lecture de la configuration ...\n');

    jsonText = fileread(configPath);
    config = jsondecode(jsonText);

    connection.subscriptionId = config.subscription_id;
    connection.resourceGroup  = config.resource_group;
    connection.workspaceName  = config.workspace_name;

    fprintf('[Azure ML] Workspace    : %s\n', connection.workspaceName);
    fprintf('[Azure ML] Resource Grp : %s\n', connection.resourceGroup);

    %% ---- URL de base de l'API Azure Resource Manager --------------------
    connection.baseUrl = sprintf( ...
        'https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.MachineLearningServices/workspaces/%s', ...
        connection.subscriptionId, connection.resourceGroup, connection.workspaceName);

    %% ---- Authentification -----------------------------------------------
    % Mode 1 : Token pré-configuré dans config.json
    if isfield(config, 'access_token') && ~isempty(config.access_token) ...
            && ~startsWith(config.access_token, '<')
        fprintf('[Azure ML] Utilisation du token pré-configuré.\n');
        connection.accessToken = config.access_token;

    % Mode 2 : Device Code Flow (interactif — fonctionne dans MATLAB Online)
    elseif isfield(config, 'tenant_id') && ~isempty(config.tenant_id) ...
            && ~startsWith(config.tenant_id, '<')
        fprintf('[Azure ML] Authentification par Device Code Flow ...\n');
        connection.accessToken = deviceCodeAuth(config.tenant_id);

    else
        error('azureMLConnect:noAuth', ...
            ['Authentification impossible.\n' ...
             'Option A – Ajoutez "access_token" dans azure-ml/config.json :\n' ...
             '  az account get-access-token --resource https://management.azure.com --query accessToken -o tsv\n\n' ...
             'Option B – Ajoutez "tenant_id" dans config.json pour le Device Code Flow.\n' ...
             '  az account show --query tenantId -o tsv']);
    end

    %% ---- Valider la connexion en récupérant les infos du workspace ------
    fprintf('[Azure ML] Vérification de la connexion ...\n');

    wsUrl = sprintf('%s?api-version=2023-10-01', connection.baseUrl);
    opts  = weboptions( ...
        'HeaderFields',  {'Authorization', sprintf('Bearer %s', connection.accessToken)}, ...
        'ContentType',   'json', ...
        'Timeout',       30);

    try
        wsInfo = webread(wsUrl, opts);
        connection.location   = wsInfo.location;
        connection.mlflowUriRaw = wsInfo.properties.mlFlowTrackingUri;
        connection.mlflowUri    = normalizeMlflowUri(connection.mlflowUriRaw);

        fprintf('[Azure ML] ✓ Connecté au workspace "%s" (%s)\n', ...
            connection.workspaceName, connection.location);
        fprintf('[Azure ML]   MLflow URI : %s\n', connection.mlflowUri);

    catch ME
        error('azureMLConnect:connectionFailed', ...
            ['Impossible de se connecter au workspace Azure ML.\n' ...
             'Vérifiez config.json et votre token d''accès.\n' ...
             'Erreur : %s'], ME.message);
    end

end


%% ========================================================================
%  FONCTIONS LOCALES
%  ========================================================================

function token = deviceCodeAuth(tenantId)
%DEVICECODEAUTH  Authentification Azure AD via Device Code Flow.
%   Affiche un code + URL pour que l'utilisateur s'authentifie dans un
%   navigateur. 100% compatible MATLAB Online (pas de CLI nécessaire).

    % Azure CLI public client ID (utilisable sans inscription d'app)
    clientId = '04b07795-cd7b-4f4a-9e04-ef4caa8b6e84';
    resource = 'https://management.azure.com';

    % Étape 1 : Demander un device code
    % Note: on utilise l'endpoint v1 (/oauth2/devicecode) avec "resource"
    % pour une meilleure compatibilité avec le client public Azure CLI.
    deviceUrl = sprintf( ...
        'https://login.microsoftonline.com/%s/oauth2/devicecode', tenantId);
    opts = weboptions('MediaType', 'application/x-www-form-urlencoded', ...
                       'ContentType', 'json');

    try
        deviceResp = webwrite(deviceUrl, ...
            'client_id', clientId, ...
            'resource', resource, ...
            opts);
    catch ME
        error('azureMLConnect:deviceCodeRequestFailed', ...
            ['Échec de la demande Device Code (HTTP 400).\n' ...
             'Vérifiez tenant_id dans azure-ml/config.json et votre accès AAD.\n' ...
             'Détail: %s'], ME.message);
    end

    % Afficher les instructions
    fprintf('\n');
    fprintf('══════════════════════════════════════════════════════════════\n');
    fprintf('  AUTHENTIFICATION AZURE — Device Code Flow\n');
    fprintf('══════════════════════════════════════════════════════════════\n');
    fprintf('  1. Ouvrez : https://microsoft.com/devicelogin\n');
    fprintf('  2. Entrez le code : %s\n', deviceResp.user_code);
    fprintf('  3. Connectez-vous avec votre compte Azure\n');
    fprintf('══════════════════════════════════════════════════════════════\n\n');

    % Étape 2 : Polling (attendre que l'utilisateur s'authentifie)
    tokenUrl = sprintf( ...
        'https://login.microsoftonline.com/%s/oauth2/token', tenantId);
    interval = 5;
    if isfield(deviceResp, 'interval'), interval = deviceResp.interval; end

    maxWait = 300;  % 5 minutes max
    elapsed = 0;

    while elapsed < maxWait
        pause(interval);
        elapsed = elapsed + interval;

        try
            tokenResp = webwrite(tokenUrl, ...
                'grant_type',  'urn:ietf:params:oauth:grant-type:device_code', ...
                'client_id',   clientId, ...
                'device_code', deviceResp.device_code, ...
                'resource',    resource, ...
                opts);

            token = tokenResp.access_token;
            fprintf('\n[Azure ML] ✓ Authentification réussie !\n');
            return;

        catch ME
            if contains(ME.message, 'authorization_pending')
                fprintf('.');
            elseif contains(ME.message, 'expired')
                error('azureMLConnect:authExpired', ...
                    'Le code a expiré. Relancez azureMLConnect().');
            end
        end
    end

    error('azureMLConnect:authTimeout', ...
        'Délai dépassé (5 min). Relancez azureMLConnect().');
end

function mlflowUri = normalizeMlflowUri(rawUri)
%NORMALIZEMLFLOWURI  Convertit une URI Azure ML en URL HTTP(S) utilisable.
%   Exemples:
%   - azureml://eastus.api.azureml.ms/mlflow/v1.0/... -> https://eastus.api.azureml.ms/mlflow/v1.0/...
%   - https://... reste inchangé

    mlflowUri = string(rawUri);

    if startsWith(mlflowUri, "azureml://")
        mlflowUri = replace(mlflowUri, "azureml://", "https://");
    end

    mlflowUri = char(mlflowUri);

    if endsWith(mlflowUri, '/')
        mlflowUri = mlflowUri(1:end-1);
    end
end
