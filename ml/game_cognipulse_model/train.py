"""Train a lightweight neural network for CogniPulse score prediction."""

from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from generate_synthetic_data import generate

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
DATA_PATH = DATA_DIR / "synthetic_sessions.csv"
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
TARGET = "cognipulse_score"


def _ensure_training_data() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not DATA_PATH.exists():
        generate(output_path=DATA_PATH)


def main() -> None:
    _ensure_training_data()

    df = pd.read_csv(DATA_PATH)
    print(f"Loaded {len(df)} samples from {DATA_PATH}")

    x = df[FEATURE_NAMES].values.astype(np.float32)
    y = df[TARGET].values.astype(np.float32)

    scaler = StandardScaler()
    x_scaled = scaler.fit_transform(x).astype(np.float32)
    joblib.dump(scaler, SCALER_PATH)
    print(f"Saved scaler to {SCALER_PATH}")

    x_train, x_val, y_train, y_val = train_test_split(
        x_scaled,
        y,
        test_size=0.2,
        random_state=42,
    )

    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(len(FEATURE_NAMES),)),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dense(32, activation="relu"),
            tf.keras.layers.Dense(1),
        ]
    )
    model.compile(optimizer="adam", loss="mse", metrics=["mae"])

    model.fit(
        x_train,
        y_train,
        validation_data=(x_val, y_val),
        epochs=100,
        batch_size=64,
        verbose=1,
    )

    predictions = model.predict(x_val, verbose=0).flatten()
    mae = float(np.mean(np.abs(predictions - y_val)))
    rmse = float(np.sqrt(np.mean((predictions - y_val) ** 2)))
    print(f"Validation MAE: {mae:.2f}")
    print(f"Validation RMSE: {rmse:.2f}")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    MODEL_PATH.write_bytes(tflite_model)
    print(f"Saved TFLite model to {MODEL_PATH}")


if __name__ == "__main__":
    main()
