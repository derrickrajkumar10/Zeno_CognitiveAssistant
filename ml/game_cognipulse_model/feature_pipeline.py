"""Python-side feature and inference helpers for the game CogniPulse model."""

from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import tensorflow as tf

BASE_DIR = Path(__file__).resolve().parent
SCALER_PATH = BASE_DIR / "scaler.pkl"
MODEL_PATH = BASE_DIR / "cognipulse_game.tflite"

FEATURE_NAMES = [
    "reaction_ms_z",
    "tap_pressure_z",
    "pressure_variance_z",
    "error_rate_z",
    "hesitation_index_z",
    "session_completion_rate",
    "fatigue_curve_drop",
    "memory_score_z",
    "flexibility_recovery_ms",
    "rumination_event_count",
]

WEIGHTS = {
    "reaction_ms_z": 0.20,
    "pressure_variance_z": 0.15,
    "error_rate_z": 0.15,
    "memory_score_z": 0.12,
    "hesitation_index_z": 0.12,
    "session_completion_rate": 0.10,
    "fatigue_curve_drop": 0.08,
    "flexibility_recovery_ms": 0.05,
    "rumination_event_count": 0.03,
}


def weighted_score(feature_dict: dict) -> float:
    return float(sum(feature_dict.get(name, 0.0) * weight for name, weight in WEIGHTS.items()))


class CogniPulsePredictor:
    def __init__(self, scaler_path: Path = SCALER_PATH, model_path: Path = MODEL_PATH):
        self.scaler = joblib.load(scaler_path)
        self.interpreter = tf.lite.Interpreter(model_path=str(model_path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

    def predict(self, session_dict: dict) -> float:
        features = np.array(
            [[session_dict.get(name, 0.0) for name in FEATURE_NAMES]],
            dtype=np.float32,
        )
        scaled = self.scaler.transform(features).astype(np.float32)
        self.interpreter.set_tensor(self.input_details[0]["index"], scaled)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details[0]["index"])
        return float(np.clip(output[0][0], 0.0, 100.0))


_predictor: Optional[CogniPulsePredictor] = None


def predict(session_dict: dict) -> float:
    global _predictor
    if _predictor is None:
        _predictor = CogniPulsePredictor()
    return _predictor.predict(session_dict)
