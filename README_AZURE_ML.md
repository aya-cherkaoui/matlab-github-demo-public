# MATLAB Online + Azure ML README

Ce guide résume comment utiliser la démo Azure ML depuis ce dépôt.

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

## 4) Déploiement endpoint (Cloud Shell)

```bash
az extension add -n ml -y
az ml online-endpoint create --file azure-ml/endpoint.yml --resource-group rg-matlab-demo --workspace-name mlw-matlab-demo
az ml online-deployment create --file azure-ml/deployment.yml --resource-group rg-matlab-demo --workspace-name mlw-matlab-demo --all-traffic
```

## 5) Scoring depuis MATLAB Online

```matlab
scoringUri = "<endpoint-scoring-uri>";
apiKey = "<endpoint-key>";

[t, ~, sig] = generateSignal(1000, 1, [5 8], 0.2);
res = analyseSignal(t, sig, 1000);
features = [res.rmsVal, res.stdVal, res.snrEstimate, res.peakFreqs];

prediction = scoreMATLABToAzure(features, scoringUri, apiKey)
```

## 6) Dépannage rapide

- Erreur `Authentication to workspace storage account failed` :
  - vérifier les rôles RBAC sur le storage lié au workspace
  - vérifier `publicNetworkAccess` si MATLAB Online doit écrire vers MLflow
- Erreur token : régénérer `access_token`.
