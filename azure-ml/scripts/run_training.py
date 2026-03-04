"""
run_training.py — Wrapper Python pour l'entraînement MATLAB sur Azure ML.

Ce script est exécuté comme job Azure ML. Il peut :
1. Lancer le code MATLAB compilé via MATLAB Runtime
2. Ou entraîner un modèle équivalent en Python (fallback)
3. Logger les métriques via MLflow

Usage (depuis un job Azure ML) :
    python run_training.py --data-path /mnt/data --output-path /mnt/output
"""

import argparse
import os
import json
import subprocess
import mlflow
import numpy as np


def parse_args():
    parser = argparse.ArgumentParser(description="MATLAB Signal Classifier Training")
    parser.add_argument("--data-path", type=str, required=True,
                        help="Chemin vers les données d'entraînement")
    parser.add_argument("--output-path", type=str, required=True,
                        help="Chemin de sortie pour le modèle")
    parser.add_argument("--epochs", type=int, default=30,
                        help="Nombre d'epochs")
    parser.add_argument("--learning-rate", type=float, default=0.001,
                        help="Learning rate")
    parser.add_argument("--use-matlab-runtime", action="store_true",
                        help="Utiliser MATLAB Runtime au lieu du fallback Python")
    return parser.parse_args()


def run_matlab_training(data_path, output_path, epochs, lr):
    """Exécute le code MATLAB compilé via MATLAB Runtime."""
    matlab_exe = os.environ.get("MATLAB_RUNTIME_PATH",
                                "/opt/matlab/runtime/R2024b/bin/glnxa64")

    compiled_app = os.path.join(os.path.dirname(__file__), "..",
                                "compiled", "trainAndExportModel")

    if os.path.exists(compiled_app):
        cmd = [
            compiled_app,
            "--data-path", data_path,
            "--output-path", output_path,
            "--epochs", str(epochs),
            "--learning-rate", str(lr)
        ]
        print(f"Exécution MATLAB Runtime : {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        if result.returncode != 0:
            print(f"STDERR: {result.stderr}")
            raise RuntimeError(f"MATLAB Runtime a échoué (code {result.returncode})")
        return True
    else:
        print("Application MATLAB compilée non trouvée. Utilisation du fallback Python.")
        return False


def run_python_fallback(data_path, output_path, epochs, lr):
    """
    Fallback Python : entraîne un modèle LSTM équivalent avec ONNX export.
    Utilisé quand MATLAB Runtime n'est pas disponible.
    """
    try:
        import torch
        import torch.nn as nn
        from torch.utils.data import DataLoader, TensorDataset
    except ImportError:
        print("PyTorch non disponible. Installation...")
        subprocess.run(["pip", "install", "torch", "onnx"], check=True)
        import torch
        import torch.nn as nn
        from torch.utils.data import DataLoader, TensorDataset

    # Générer des données synthétiques (même logique que MATLAB)
    print("Génération des données synthétiques...")
    np.random.seed(42)
    fs = 1000
    duration = 1
    n_samples = 200
    t = np.arange(0, duration, 1/fs)

    X_data = []
    y_data = []

    freq_ranges = [(1, 10), (10, 50), (50, 200)]

    for class_idx, (f_low, f_high) in enumerate(freq_ranges):
        for _ in range(n_samples):
            n_freqs = np.random.randint(1, 4)
            freqs = np.random.uniform(f_low, f_high, n_freqs)
            signal = sum(np.sin(2 * np.pi * f * t) for f in freqs)
            signal += 0.3 * np.random.randn(len(t))
            X_data.append(signal)
            y_data.append(class_idx)

    X = np.array(X_data, dtype=np.float32)
    y = np.array(y_data, dtype=np.int64)

    # Shuffle et split
    perm = np.random.permutation(len(X))
    X, y = X[perm], y[perm]
    n_train = int(0.8 * len(X))

    X_train, X_val = X[:n_train], X[n_train:]
    y_train, y_val = y[:n_train], y[n_train:]

    # Reshape pour LSTM : (batch, seq_len, features)
    X_train_t = torch.FloatTensor(X_train).unsqueeze(-1)
    X_val_t = torch.FloatTensor(X_val).unsqueeze(-1)
    y_train_t = torch.LongTensor(y_train)
    y_val_t = torch.LongTensor(y_val)

    train_ds = TensorDataset(X_train_t, y_train_t)
    train_loader = DataLoader(train_ds, batch_size=32, shuffle=True)

    # Définir le modèle LSTM (équivalent MATLAB)
    class SignalClassifier(nn.Module):
        def __init__(self, input_size=1, hidden_size=100, num_classes=3):
            super().__init__()
            self.lstm = nn.LSTM(input_size, hidden_size, batch_first=True)
            self.dropout = nn.Dropout(0.3)
            self.fc = nn.Linear(hidden_size, num_classes)

        def forward(self, x):
            _, (h_n, _) = self.lstm(x)
            out = self.dropout(h_n[-1])
            out = self.fc(out)
            return out

    model = SignalClassifier()
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)

    # Entraînement
    print(f"Entraînement : {epochs} epochs, lr={lr}")
    for epoch in range(epochs):
        model.train()
        total_loss = 0
        for X_batch, y_batch in train_loader:
            optimizer.zero_grad()
            outputs = model(X_batch)
            loss = criterion(outputs, y_batch)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        avg_loss = total_loss / len(train_loader)

        # Validation
        model.eval()
        with torch.no_grad():
            val_outputs = model(X_val_t)
            val_preds = torch.argmax(val_outputs, dim=1)
            val_acc = (val_preds == y_val_t).float().mean().item() * 100

        mlflow.log_metric("train_loss", avg_loss, step=epoch)
        mlflow.log_metric("val_accuracy", val_acc, step=epoch)

        if (epoch + 1) % 5 == 0:
            print(f"  Epoch {epoch+1}/{epochs} — Loss: {avg_loss:.4f} — Val Acc: {val_acc:.1f}%")

    # Export ONNX
    os.makedirs(output_path, exist_ok=True)
    onnx_path = os.path.join(output_path, "signal_classifier.onnx")

    dummy_input = torch.randn(1, fs, 1)
    torch.onnx.export(
        model, dummy_input, onnx_path,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}}
    )
    print(f"Modèle exporté en ONNX : {onnx_path}")

    return val_acc, avg_loss


def main():
    args = parse_args()

    mlflow.start_run()
    mlflow.log_param("epochs", args.epochs)
    mlflow.log_param("learning_rate", args.learning_rate)
    mlflow.set_tag("framework", "matlab" if args.use_matlab_runtime else "pytorch-fallback")

    if args.use_matlab_runtime:
        success = run_matlab_training(
            args.data_path, args.output_path, args.epochs, args.learning_rate
        )
        if not success:
            val_acc, final_loss = run_python_fallback(
                args.data_path, args.output_path, args.epochs, args.learning_rate
            )
            mlflow.log_metric("final_val_accuracy", val_acc)
            mlflow.log_metric("final_loss", final_loss)
    else:
        val_acc, final_loss = run_python_fallback(
            args.data_path, args.output_path, args.epochs, args.learning_rate
        )
        mlflow.log_metric("final_val_accuracy", val_acc)
        mlflow.log_metric("final_loss", final_loss)

    mlflow.end_run()
    print("Entraînement terminé.")


if __name__ == "__main__":
    main()
