# Démo : MATLAB + GitHub + Azure Machine Learning

## Scénario de démonstration client

---

## 1. Contexte

Le client utilise aujourd'hui **MATLAB** pour ses pipelines de traitement du signal (génération, analyse FFT, détection de pics, visualisation, rapports). Le code est versionné sur **GitHub** avec CI/CD via GitHub Actions.

**Objectif** : Intégrer **Azure Machine Learning** dans cette chaîne de travail pour :

- Entraîner des modèles ML/DL directement depuis MATLAB
- Gérer les expérimentations (tracking, comparaison de runs)
- Déployer des modèles en production (endpoints managés)
- Automatiser le tout dans un pipeline MLOps (GitHub → Azure ML)

---

## 2. Architecture cible

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Développeur MATLAB                          │
│                                                                     │
│  MATLAB Online / Desktop                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │generateSignal│→ │analyseSignal │→ │ trainModel (nouveau)     │  │
│  │              │  │              │  │ - Classification de       │  │
│  │              │  │              │  │   signaux via ML/DL       │  │
│  └──────────────┘  └──────────────┘  └──────────┬───────────────┘  │
│                                                  │                  │
│                                    Export ONNX / .mat               │
└──────────────────────────────────┬───────────────┼──────────────────┘
                                   │               │
                    git push       │               │
                                   ▼               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          GitHub                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  GitHub Actions CI/CD                                          │  │
│  │  1. Tests MATLAB (runAllTests)                                 │  │
│  │  2. Soumission job Azure ML (az ml job create)                 │  │
│  │  3. Enregistrement modèle (az ml model create)                 │  │
│  │  4. Déploiement endpoint (az ml online-endpoint)               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Azure Machine Learning                            │
│                                                                      │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│  │  Workspace    │  │ Datastores  │  │  Compute Clusters           │ │
│  │  - Experiments│  │ - Blob      │  │  - MATLAB Runtime           │ │
│  │  - Runs       │  │ - Data Lake │  │  - GPU / CPU                │ │
│  │  - Models     │  │             │  │  - Custom Docker + MATLAB   │ │
│  └──────────────┘  └─────────────┘  └─────────────────────────────┘ │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  Managed Online Endpoints                                    │    │
│  │  - Modèle ONNX exporté depuis MATLAB                        │    │
│  │  - API REST pour inférence temps réel                        │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Modes d'intégration MATLAB Online ↔ Azure ML

> **Note** : Toutes les intégrations ci-dessous fonctionnent dans **MATLAB Online**
> (navigateur). Aucune installation locale, aucun Python, aucun CLI requis côté MATLAB.

### 3.1 — API REST Azure ML via `webwrite`/`webread` (méthode principale)

MATLAB Online appelle directement les API REST d'Azure ML et MLflow :

```matlab
% Connexion au workspace (Device Code Flow ou token pré-configuré)
conn = azureMLConnect();

% Logger des métriques via l'API REST MLflow
webwrite(sprintf('%s/api/2.0/mlflow/runs/log-metric', conn.mlflowUri), ...
    jsonencode(struct('run_id', runId, 'key', 'accuracy', 'value', 95.2)), ...
    opts);
```

➡️ Voir le fichier `src/azureMLConnect.m`

### 3.2 — Export ONNX depuis MATLAB Online

MATLAB Deep Learning Toolbox (disponible dans MATLAB Online) permet d'exporter
un réseau entraîné au format ONNX, directement déployable sur Azure ML :

```matlab
net = trainNetwork(XTrain, YTrain, layers, options);
exportONNXNetwork(net, 'model.onnx');
```

➡️ Voir le fichier `src/trainAndExportModel.m`

### 3.3 — Scoring d'endpoint REST depuis MATLAB Online

MATLAB Online appelle un endpoint managé Azure ML via `webwrite` :

```matlab
% URI et clé récupérées depuis Azure ML Studio → Endpoints → Consume
result = scoreMATLABToAzure(features, scoringUri, apiKey);
fprintf('Classe prédite : %s\n', result.predictedClass);
```

➡️ Voir le fichier `src/scoreMATLABToAzure.m`

### 3.4 — GitHub Actions pour le déploiement (pas besoin de CLI local)

Toute l'infra Azure ML (compute, endpoint, deployment) est gérée par
**GitHub Actions** — le data scientist reste dans MATLAB Online :

```
git push → GitHub Actions → az ml job create → az ml model create → az ml online-endpoint
```

➡️ Voir `.github/workflows/mlops.yml`

### 3.5 — Authentification depuis MATLAB Online

Deux options sans installer quoi que ce soit :

| Mode | Comment | Idéal pour |
|------|---------|----------|
| **Device Code Flow** | MATLAB affiche un code, vous l'entrez sur microsoft.com/devicelogin | Démo interactive |
| **Token pré-configuré** | Collez un bearer token dans `config.json` | Automatisation / scripting |

---

## 4. Scénario de démo pas-à-pas

### Pré-requis

| Outil | Version | Rôle | Local requis ? |
|-------|---------|------|----------------|
| **MATLAB Online** | R2024b+ | Développement, entraînement | Non (navigateur) |
| Deep Learning Toolbox | — | Export ONNX | Inclus dans MATLAB Online |
| Signal Processing Toolbox | — | Analyse spectrale | Inclus dans MATLAB Online |
| Abonnement Azure | — | Workspace Azure ML | Non |
| GitHub | — | Versioning + CI/CD | Non |
| Azure CLI | 2.x | Setup initial (1 fois) | Optionnel (Cloud Shell) |

> **Aucun Python, aucun Docker, aucun CLI local requis** pour la démo.
> L'Azure CLI n'est nécessaire que pour le setup initial (peut être fait
> dans Azure Cloud Shell depuis le navigateur).

---

### Étape 0 : Préparer l'environnement Azure ML (5 min)

```bash
# Installer l'extension Azure ML pour Azure CLI
az extension add -n ml

# Créer un Resource Group
az group create --name rg-matlab-demo --location francecentral

# Créer un workspace Azure ML
az ml workspace create \
  --name mlw-matlab-demo \
  --resource-group rg-matlab-demo \
  --location francecentral

# Créer un compute cluster
az ml compute create \
  --name matlab-cpu-cluster \
  --resource-group rg-matlab-demo \
  --workspace-name mlw-matlab-demo \
  --type AmlCompute \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 2
```

### Étape 1 : Pipeline MATLAB existant (5 min)

> « Voici le pipeline actuel du client »

```matlab
>> main   % Exécuter la pipeline complète
```

Montrer :
1. Génération du signal synthétique (3 fréquences : 5, 12, 30 Hz)
2. Analyse FFT + détection de pics
3. Graphiques publiés
4. Rapport texte généré

**Message clé** : « Ce pipeline tourne bien, mais les résultats restent en local. Aucun tracking, aucun déploiement. »

---

### Étape 2 : Ajouter le tracking Azure ML depuis MATLAB Online (10 min)

> « On va maintenant logger chaque exécution dans Azure ML — directement depuis le navigateur »

```matlab
>> conn = azureMLConnect()     % Connexion (Device Code Flow dans le navigateur)
>> mainWithAzureML             % Pipeline enrichie avec tracking REST
```

**Ce qui se passe en coulisses** :
1. MATLAB Online affiche un code d'authentification
2. Vous ouvrez https://microsoft.com/devicelogin et entrez le code
3. La pipeline tourne et logge les métriques via l'API REST MLflow
4. Aucun Python, aucun SDK installé — juste des appels `webwrite`

Montrer dans Azure ML Studio (https://ml.azure.com) :
- L'expérience `matlab-signal-analysis` apparaît
- Les métriques loggées : SNR, nombre de pics, RMS
- Chaque run est horodaté et comparable

**Message clé** : « Depuis MATLAB Online, sans rien installer, on ajoute le tracking Azure ML. Chaque run est historisé et comparable. »

---

### Étape 3 : Entraîner un modèle de classification de signaux (10 min)

> « Le client souhaite classifier automatiquement les types de signaux »

```matlab
>> trainAndExportModel     % Entraîne un réseau LSTM + export ONNX
```

Montrer :
1. Génération d'un dataset synthétique (signaux de 3 classes)
2. Architecture LSTM définie en MATLAB
3. Entraînement avec suivi des métriques dans Azure ML
4. Export au format ONNX → `models/signal_classifier.onnx`
5. Enregistrement du modèle dans Azure ML Model Registry

**Message clé** : « MATLAB reste l'outil d'entraînement. Azure ML gère le versioning du modèle et les métriques. »

---

### Étape 4 : Déployer le modèle comme endpoint REST (10 min)

> « On déploie le modèle ONNX sur un endpoint managé Azure »

```bash
az ml online-endpoint create --file azure-ml/endpoint.yml
az ml online-deployment create --file azure-ml/deployment.yml
```

Puis, depuis MATLAB :

```matlab
>> result = scoreMATLABToAzure(newSignalFeatures)
```

Montrer :
1. Endpoint actif dans Azure ML Studio
2. Appel REST depuis MATLAB (`webwrite`)
3. Réponse JSON avec la classe prédite + confiance

**Message clé** : « Le modèle entraîné en MATLAB est maintenant une API REST. N'importe quelle application peut l'appeler. »

---

### Étape 5 : CI/CD avec GitHub Actions (5 min)

> « On automatise tout : tests → entraînement → déploiement »

Montrer le fichier `.github/workflows/mlops.yml` :

1. **Push sur `main`** → Tests MATLAB
2. **Tag `v*`** → Entraînement sur Azure ML → Enregistrement modèle → Déploiement endpoint

**Message clé** : « Du commit au endpoint de production, tout est automatisé. Le data scientist reste dans MATLAB, le MLOps tourne tout seul. »

---

### Étape 6 : Monitoring en production (5 min — optionnel)

Montrer dans Azure ML Studio :
- Métriques de l'endpoint (latence, throughput, erreurs)
- Data drift detection
- Alertes configurables

---

## 5. Résumé des bénéfices client

| Avant (MATLAB + GitHub seul) | Après (+ Azure ML) |
|------------------------------|---------------------|
| Résultats en local uniquement | Tracking centralisé dans Azure ML Studio |
| Pas de versioning de modèles | Model Registry avec versions et métadonnées |
| Pas de déploiement | Endpoints managés avec auto-scaling |
| CI = tests uniquement | CI/CD complet : test → train → deploy |
| Comparaison manuelle des runs | Comparaison visuelle dans Azure ML Studio |
| Collaboration difficile sur les expériences | Workspace partagé, RBAC, audit trail |

---

## 6. Fichiers créés pour cette démo

| Fichier | Description |
|---------|-------------|
| `src/azureMLConnect.m` | Connexion MATLAB Online → Azure ML via API REST (Device Code Flow) |
| `src/trainAndExportModel.m` | Entraînement LSTM + export ONNX |
| `src/mainWithAzureML.m` | Pipeline principale avec tracking Azure ML via API REST MLflow |
| `src/scoreMATLABToAzure.m` | Appel de l'endpoint REST depuis MATLAB |
| `azure-ml/config.json` | Configuration du workspace Azure ML |
| `azure-ml/environment.yml` | Environnement custom avec MATLAB Runtime |
| `azure-ml/endpoint.yml` | Définition de l'endpoint managé |
| `azure-ml/deployment.yml` | Configuration du déploiement |
| `azure-ml/train_job.yml` | Job d'entraînement Azure ML |
| `.github/workflows/mlops.yml` | Pipeline CI/CD GitHub Actions + Azure ML |

---

## 7. Ressources

- [MATLAB Online](https://matlab.mathworks.com) — Environnement MATLAB dans le navigateur
- [MATLAB + Azure (MathWorks)](https://www.mathworks.com/solutions/cloud/azure.html)
- [Azure ML REST API](https://learn.microsoft.com/rest/api/azureml/) — API utilisée par nos scripts
- [MLflow REST API](https://mlflow.org/docs/latest/rest-api.html) — Tracking depuis MATLAB Online
- [Azure ML Studio](https://ml.azure.com) — Interface web pour visualiser les expériences
- [ONNX Runtime](https://onnxruntime.ai/) — Runtime pour modèles exportés
- [GitHub Actions + Azure ML](https://learn.microsoft.com/azure/machine-learning/how-to-github-actions-machine-learning)
- [Azure Cloud Shell](https://shell.azure.com) — CLI Azure dans le navigateur (setup initial)
- [MATLAB webwrite](https://www.mathworks.com/help/matlab/ref/webwrite.html) — Fonction clé pour les appels REST
