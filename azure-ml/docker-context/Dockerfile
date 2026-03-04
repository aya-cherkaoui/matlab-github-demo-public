# Dockerfile pour l'environnement MATLAB Runtime sur Azure ML
# =========================================================================
# Ce Dockerfile crée un conteneur avec :
# - MATLAB Runtime R2024b (pour exécuter du code MATLAB compilé)
# - Python 3.10 + SDK Azure ML (pour le tracking et l'interop)
# - ONNX Runtime (pour le scoring de modèles exportés)
# =========================================================================

FROM mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu22.04:latest

# Installer les dépendances systèmes
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    libxt6 \
    libxmu6 \
    && rm -rf /var/lib/apt/lists/*

# Installer MATLAB Runtime R2024b
# Note : En production, utiliser l'image officielle mathworks/matlab-runtime
RUN wget -q https://ssd.mathworks.com/supportfiles/downloads/R2024b/Release/0/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2024b_glnxa64.zip \
    -O /tmp/matlab_runtime.zip && \
    unzip -q /tmp/matlab_runtime.zip -d /tmp/matlab_runtime && \
    /tmp/matlab_runtime/install -mode silent -agreeToLicense yes -destinationFolder /opt/matlab/runtime && \
    rm -rf /tmp/matlab_runtime /tmp/matlab_runtime.zip

# Configurer les variables d'environnement MATLAB Runtime
ENV LD_LIBRARY_PATH="/opt/matlab/runtime/R2024b/runtime/glnxa64:\
/opt/matlab/runtime/R2024b/bin/glnxa64:\
/opt/matlab/runtime/R2024b/sys/os/glnxa64:\
/opt/matlab/runtime/R2024b/extern/bin/glnxa64:${LD_LIBRARY_PATH}"

# Installer les packages Python nécessaires
RUN pip install --no-cache-dir \
    azure-ai-ml>=1.12.0 \
    azure-identity>=1.15.0 \
    onnxruntime>=1.17.0 \
    numpy>=1.24.0 \
    pandas>=2.0.0 \
    mlflow>=2.10.0

WORKDIR /app
