"""
score.py — Script de scoring pour l'endpoint managé Azure ML.

Charge le modèle ONNX exporté depuis MATLAB et effectue l'inférence
sur les signaux envoyés via l'API REST.
"""

import os
import json
import logging
import numpy as np
import onnxruntime as ort

logger = logging.getLogger(__name__)


def init():
    """Appelé une fois au démarrage du conteneur. Charge le modèle ONNX."""
    global session, class_names, input_name

    model_path = os.path.join(
        os.getenv("AZUREML_MODEL_DIR", "."),
        "signal_classifier.onnx"
    )

    logger.info(f"Chargement du modèle : {model_path}")
    session = ort.InferenceSession(model_path)
    input_name = session.get_inputs()[0].name

    # Classes correspondant aux catégories MATLAB
    class_names = ["low_freq", "mid_freq", "high_freq"]

    logger.info(f"Modèle chargé. Input: {input_name}, Classes: {class_names}")


def run(raw_data):
    """
    Appelé à chaque requête d'inférence.

    Paramètres
    ----------
    raw_data : str
        JSON avec le format :
        {
            "input_data": {
                "columns": ["feature_1", ...],
                "data": [[0.1, 0.2, ...], ...]
            }
        }

    Retour
    ------
    str : JSON avec les prédictions et scores
    """
    try:
        data = json.loads(raw_data)

        if "input_data" in data:
            input_array = np.array(data["input_data"]["data"], dtype=np.float32)
        elif "data" in data:
            input_array = np.array(data["data"], dtype=np.float32)
        else:
            input_array = np.array(data, dtype=np.float32)

        # Reshape pour le modèle LSTM : (batch, sequence_length, features)
        if input_array.ndim == 1:
            input_array = input_array.reshape(1, -1, 1)
        elif input_array.ndim == 2:
            input_array = input_array.reshape(input_array.shape[0], -1, 1)

        # Inférence ONNX
        results = session.run(None, {input_name: input_array})

        # results[0] = labels, results[1] = probabilities (si disponible)
        predictions = []
        scores_list = []

        if len(results) >= 2:
            # Le modèle retourne labels + probabilités
            labels = results[0]
            probabilities = results[1]

            for i in range(len(labels)):
                pred_idx = int(labels[i])
                pred_class = class_names[pred_idx] if pred_idx < len(class_names) else str(pred_idx)
                predictions.append(pred_class)

                if isinstance(probabilities[i], dict):
                    scores = {class_names[k]: float(v) for k, v in probabilities[i].items()}
                else:
                    scores = {class_names[j]: float(probabilities[i][j])
                              for j in range(len(class_names))}
                scores_list.append(scores)
        else:
            # Le modèle retourne uniquement les scores
            output = results[0]
            for i in range(output.shape[0]):
                pred_idx = int(np.argmax(output[i]))
                predictions.append(class_names[pred_idx])
                scores = {class_names[j]: float(output[i][j])
                          for j in range(min(len(class_names), output.shape[1]))}
                scores_list.append(scores)

        response = {
            "predictions": predictions,
            "scores": scores_list
        }

        logger.info(f"Inférence réussie — {len(predictions)} prédiction(s)")
        return json.dumps(response)

    except Exception as e:
        logger.error(f"Erreur d'inférence : {str(e)}")
        return json.dumps({"error": str(e)})
