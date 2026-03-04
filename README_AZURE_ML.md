# MATLAB Online + Azure ML README

Ce guide résume comment utiliser la démo Azure ML depuis ce dépôt.

## 0) Objectif de la démo

Cette démo montre comment passer d'un pipeline MATLAB local à un workflow MLOps Azure ML :

- **MATLAB Online** pour développer et entraîner
- **Azure ML** pour tracer, gouverner et déployer
- **GitHub Actions** pour automatiser test/train/deploy


## 1) Pré-requis

- Workspace Azure ML existant
- MATLAB Online (R2024b+)
- Toolboxes MATLAB : Signal Processing + Deep Learning
- Permissions Azure sur le storage du workspace :
  - `Storage Blob Data Contributor`
  - `Storage Queue Data Contributor`

## 2) Configuration

Éditer `azure-ml/config.json` et renseigner :

- `subscription_id`
- `resource_group`
- `workspace_name`
- `tenant_id`
- `access_token` (token ARM valide)

Token ARM (Cloud Shell) :

```bash
az account get-access-token --resource https://management.azure.com --query accessToken -o tsv
```

### 2.1 Commandes MATLAB pour la connexion AML

#### Option A — Connexion avec token (`access_token` déjà renseigné)

```matlab
configPath = fullfile(pwd, "azure-ml", "config.json");
conn = azureMLConnect(configPath);

fprintf("Workspace: %s\n", conn.workspaceName);
fprintf("Location : %s\n", conn.location);
fprintf("MLflow   : %s\n", conn.mlflowUri);
```

#### Option B — Connexion via Device Code Flow

Laisser `tenant_id` renseigné dans `config.json` et mettre `access_token` avec un placeholder.
Puis exécuter :

```matlab
conn = azureMLConnect();
```

MATLAB affichera un code à entrer sur `https://microsoft.com/devicelogin`.

#### Test rapide de la connexion Azure Resource Manager

```matlab
conn = azureMLConnect();

opts = weboptions( ...
  "HeaderFields", {"Authorization", sprintf("Bearer %s", conn.accessToken)}, ...
  "ContentType", "json", ...
  "Timeout", 30);

wsUrl = sprintf("%s?api-version=2023-10-01", conn.baseUrl);
wsInfo = webread(wsUrl, opts);

disp(wsInfo.name)
disp(wsInfo.location)
```

#### Test rapide de l'API MLflow (création d'une expérience)

```matlab
conn = azureMLConnect();

mlflowOpts = weboptions( ...
  "HeaderFields", { ...
    "Authorization", sprintf("Bearer %s", conn.accessToken); ...
    "Content-Type", "application/json" ...
  }, ...
  "ContentType", "json", ...
  "MediaType", "application/json", ...
  "Timeout", 30);

expBody = jsonencode(struct("name", "matlab-connection-test"));
webwrite(sprintf("%s/api/2.0/mlflow/experiments/create", conn.mlflowUri), expBody, mlflowOpts);
```

Si la dernière commande échoue avec `Authentication to workspace storage account failed`,
la connexion Azure est OK mais les droits RBAC storage sont insuffisants.

## 3) Exécution dans MATLAB Online

Depuis la racine du projet :

```matlab
startup
mainWithAzureML
```

Entraînement + export ONNX :

```matlab
trainAndExportModel
```

## 4) Azure ML en détail

### 4.1 Expérimentation et traçabilité

Avec `mainWithAzureML`, chaque exécution est tracée dans Azure ML (via API MLflow REST) :

- paramètres (`sample_rate`, `duration`, `noise_level`, etc.)
- métriques (`snr_db`, `rms`, `num_peaks`, fréquences détectées)
- statut des runs (succès/échec)

Résultat : comparaison de runs et reproductibilité au niveau équipe.

### 4.2 Gouvernance modèle

Avec `trainAndExportModel` :

- entraînement du modèle LSTM dans MATLAB Online
- export ONNX (`models/signal_classifier.onnx`)
- tracking des métriques de training dans Azure ML

Résultat : cycle modèle lisible, versionnable, prêt pour le déploiement.

### 4.3 Serving managé

Le modèle ONNX est servi via un endpoint Azure ML managé :

- endpoint : `azure-ml/endpoint.yml`
- déploiement : `azure-ml/deployment.yml`
- scoring script : `azure-ml/scoring/score.py`

Résultat : API REST exploitable par MATLAB, applis métiers et intégrations tierces.

### 4.4 Automatisation MLOps

Le workflow GitHub Actions `/.github/workflows/mlops.yml` automatise :

1. tests MATLAB
2. training Azure ML
3. model registration
4. endpoint deployment

Résultat : passage dev -> prod plus rapide, moins d'opérations manuelles.

## 5) Déploiement endpoint (Cloud Shell)

```bash
az extension add -n ml -y
az ml online-endpoint create --file azure-ml/endpoint.yml --resource-group rg-matlab-demo --workspace-name mlw-matlab-demo
az ml online-deployment create --file azure-ml/deployment.yml --resource-group rg-matlab-demo --workspace-name mlw-matlab-demo --all-traffic
```

## 6) Scoring depuis MATLAB Online

```matlab
scoringUri = "<endpoint-scoring-uri>";
apiKey = "<endpoint-key>";

[t, ~, sig] = generateSignal(1000, 1, [5 8], 0.2);
res = analyseSignal(t, sig, 1000);
features = [res.rmsVal, res.stdVal, res.snrEstimate, res.peakFreqs];

prediction = scoreMATLABToAzure(features, scoringUri, apiKey)
```

## 7) Dépannage rapide

### Erreur `Authentication to workspace storage account failed`

- vérifier les rôles RBAC sur le storage lié au workspace :
  - `Storage Blob Data Contributor`
  - `Storage Queue Data Contributor`
- vérifier `publicNetworkAccess` du storage si MATLAB Online doit écrire vers MLflow
- régénérer le token ARM et mettre à jour `access_token`

### Erreur `Could not access server` sur scoring endpoint

- vérifier que l'URI endpoint correspond à la bonne région (ex: `eastus`)
- vérifier que l'endpoint est en état `Succeeded`
- vérifier que l'auth mode est `key` et récupérer une clé valide

### Erreur token / authentification

- régénérer `access_token` :

```bash
az account get-access-token --resource https://management.azure.com --query accessToken -o tsv
```

### Commandes de vérification utiles

```bash
az ml online-endpoint show -n matlab-signal-classifier -g rg-matlab-demo -w mlw-matlab-demo --query "{state:provisioning_state,scoringUri:scoring_uri,auth:auth_mode}" -o json
az ml online-endpoint get-credentials -n matlab-signal-classifier -g rg-matlab-demo -w mlw-matlab-demo --query "{primaryKey:primaryKey}" -o json
```
