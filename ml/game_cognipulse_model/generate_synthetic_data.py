"""Generate synthetic game feature rows for CogniPulse model training."""

from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd

np.random.seed(42)

NUM_USERS = 200
SESSIONS_PER_USER = 50

STATE_PROFILES = {
    "stressed": {
        "reaction_ms_z": (1.5, 0.6),
        "tap_pressure_z": (1.2, 0.5),
        "pressure_variance_z": (1.8, 0.7),
        "error_rate_z": (1.3, 0.5),
        "hesitation_index_z": (1.0, 0.4),
        "session_completion_rate": (0.55, 0.15),
        "fatigue_curve_drop": (0.3, 0.1),
        "memory_score_z": (1.1, 0.5),
        "flexibility_recovery_ms": (1.4, 0.6),
        "rumination_event_count": (3.0, 1.5),
        "cognipulse_score": (25, 10),
    },
    "focused": {
        "reaction_ms_z": (-1.0, 0.4),
        "tap_pressure_z": (-0.3, 0.3),
        "pressure_variance_z": (-0.8, 0.3),
        "error_rate_z": (-1.2, 0.4),
        "hesitation_index_z": (-0.9, 0.3),
        "session_completion_rate": (0.92, 0.06),
        "fatigue_curve_drop": (-0.1, 0.05),
        "memory_score_z": (-0.8, 0.4),
        "flexibility_recovery_ms": (-0.7, 0.3),
        "rumination_event_count": (0.5, 0.5),
        "cognipulse_score": (82, 8),
    },
    "fatigued": {
        "reaction_ms_z": (1.8, 0.5),
        "tap_pressure_z": (-0.5, 0.4),
        "pressure_variance_z": (0.5, 0.4),
        "error_rate_z": (0.6, 0.4),
        "hesitation_index_z": (1.5, 0.5),
        "session_completion_rate": (0.70, 0.12),
        "fatigue_curve_drop": (0.5, 0.15),
        "memory_score_z": (0.7, 0.5),
        "flexibility_recovery_ms": (1.0, 0.4),
        "rumination_event_count": (2.0, 1.0),
        "cognipulse_score": (45, 12),
    },
}

FEATURES = [
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


def generate(output_path: Optional[Path] = None) -> Path:
    rows = []
    states = list(STATE_PROFILES.keys())
    output_path = output_path or Path(__file__).resolve().parent / "data" / "synthetic_sessions.csv"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    for user_index in range(NUM_USERS):
        user_offsets = {feature: np.random.normal(0, 0.3) for feature in FEATURES}
        user_score_offset = np.random.normal(0, 5)

        for _ in range(SESSIONS_PER_USER):
            state = np.random.choice(states, p=[0.35, 0.35, 0.30])
            profile = STATE_PROFILES[state]
            row = {"user_id": f"user_{user_index:04d}", "state": state}

            for feature in FEATURES:
                mean, std = profile[feature]
                value = np.random.normal(mean + user_offsets[feature], std)
                if feature == "session_completion_rate":
                    value = np.clip(value, 0.0, 1.0)
                if feature == "rumination_event_count":
                    value = max(0.0, value)
                row[feature] = round(value, 4)

            score_mean, score_std = profile["cognipulse_score"]
            score = np.random.normal(score_mean + user_score_offset, score_std)
            row["cognipulse_score"] = int(np.clip(round(score), 0, 100))
            rows.append(row)

    dataframe = pd.DataFrame(rows)
    dataframe.to_csv(output_path, index=False)
    print(f"Generated {len(dataframe)} synthetic sessions at {output_path}")
    return output_path


if __name__ == "__main__":
    generate()
