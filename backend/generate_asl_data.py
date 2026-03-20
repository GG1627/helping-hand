"""
generate_asl_data.py

Generates synthetic ASL glove sensor data for all 36 classes (A-Z, 0-9).
Simulates 5 flex sensors + 6-axis IMU (accel + gyro) for static signs.

Flex sensor values: 0-4095 (12-bit ADC range)
  - 0    = fully extended finger
  - 4095 = fully bent finger

Accel values: roughly in m/s^2, resting wrist orientation varies per sign
Gyro values: near-zero with small noise (static signs, no movement)

Usage:
    python generate_asl_data.py
    -> outputs asl_synthetic.csv
"""

import numpy as np
import pandas as pd

# Reproducibility
np.random.seed(42)

SAMPLES_PER_CLASS = 200
NOISE_STD = 80  # flex sensor noise
ACCEL_NOISE = 0.3
GYRO_NOISE = 0.05

# ─────────────────────────────────────────────
# Sign definitions
# Each sign: [flex_1, flex_2, flex_3, flex_4, flex_5, accel_x, accel_y, accel_z]
# flex = [thumb, index, middle, ring, pinky]
# Values are MEANS, noise is added during sampling
#
# Flex scale:
#   ~500  = fully extended
#   ~2000 = half bent
#   ~3500 = fully bent
# ─────────────────────────────────────────────

SIGN_DEFINITIONS = {
    # ── LETTERS ──────────────────────────────────────────────────────────────

    # A: fist, thumb rests on side of index finger
    "A": dict(flex=[2800, 3400, 3400, 3400, 3400], accel=[0.5, 9.5, 1.0]),

    # B: all fingers extended straight up, thumb tucked across palm
    "B": dict(flex=[3200, 500,  500,  500,  500 ], accel=[0.2, 9.7, 0.5]),

    # C: curved hand like holding a ball
    "C": dict(flex=[1800, 1800, 1800, 1800, 1800], accel=[1.0, 9.0, 1.5]),

    # D: index up, others curl to touch thumb
    "D": dict(flex=[2800, 500,  2800, 2800, 2800], accel=[0.3, 9.6, 0.8]),

    # E: all fingers bent at knuckles, thumb tucked under
    "E": dict(flex=[3000, 2800, 2800, 2800, 2800], accel=[0.4, 9.5, 1.0]),

    # F: index and thumb touch, other three extended
    "F": dict(flex=[2500, 2500, 500,  500,  500 ], accel=[0.6, 9.4, 1.2]),

    # G: index points sideways, thumb out, others curled
    "G": dict(flex=[2200, 500,  3200, 3200, 3200], accel=[5.0, 7.0, 2.0]),

    # H: index and middle extended sideways together
    "H": dict(flex=[2200, 500,  500,  3200, 3200], accel=[5.0, 7.0, 2.0]),

    # I: pinky extended, others curled
    "I": dict(flex=[3000, 3200, 3200, 3200, 500 ], accel=[0.3, 9.6, 0.8]),

    # J: like I but with a J motion — static approximation: pinky up, wrist tilted
    "J": dict(flex=[3000, 3200, 3200, 3200, 500 ], accel=[2.0, 8.5, 3.0]),

    # K: index and middle up in V, thumb between them
    "K": dict(flex=[1500, 500,  500,  3200, 3200], accel=[0.4, 9.5, 1.0]),

    # L: L-shape, index up, thumb out
    "L": dict(flex=[500,  500,  3200, 3200, 3200], accel=[0.5, 9.4, 1.5]),

    # M: three fingers folded over thumb
    "M": dict(flex=[3000, 3000, 3000, 3000, 3200], accel=[0.3, 9.6, 0.8]),

    # N: two fingers folded over thumb
    "N": dict(flex=[3000, 3000, 3000, 3200, 3200], accel=[0.3, 9.6, 0.8]),

    # O: all fingers curve to touch thumb tip
    "O": dict(flex=[2000, 2000, 2000, 2000, 2000], accel=[0.5, 9.4, 1.5]),

    # P: like K but pointing down
    "P": dict(flex=[1500, 500,  500,  3200, 3200], accel=[0.4, 7.0, 6.0]),

    # Q: like G but pointing down
    "Q": dict(flex=[2200, 500,  3200, 3200, 3200], accel=[0.5, 7.0, 6.5]),

    # R: index and middle crossed
    "R": dict(flex=[2800, 1200, 1000, 3200, 3200], accel=[0.3, 9.6, 0.8]),

    # S: fist with thumb over fingers
    "S": dict(flex=[2500, 3400, 3400, 3400, 3400], accel=[0.4, 9.5, 1.0]),

    # T: thumb between index and middle
    "T": dict(flex=[2000, 3200, 3200, 3200, 3200], accel=[0.4, 9.5, 1.0]),

    # U: index and middle extended together upward
    "U": dict(flex=[2800, 500,  500,  3200, 3200], accel=[0.3, 9.6, 0.8]),

    # V: index and middle in V shape (peace sign)
    "V": dict(flex=[2800, 500,  500,  3200, 3200], accel=[0.8, 9.3, 1.5]),

    # W: index, middle, ring extended
    "W": dict(flex=[2800, 500,  500,  500,  3200], accel=[0.5, 9.4, 1.2]),

    # X: index finger hooked
    "X": dict(flex=[2800, 1800, 3200, 3200, 3200], accel=[0.4, 9.5, 1.0]),

    # Y: thumb and pinky out
    "Y": dict(flex=[500,  3200, 3200, 3200, 500 ], accel=[0.5, 9.3, 1.5]),

    # Z: index traces Z — static approx: index extended, slight tilt
    "Z": dict(flex=[2800, 500,  3200, 3200, 3200], accel=[3.0, 8.0, 4.0]),

    # ── NUMBERS ──────────────────────────────────────────────────────────────

    # 0: fingers curved to touch thumb (like O)
    "0": dict(flex=[2000, 2000, 2000, 2000, 2000], accel=[0.6, 9.3, 1.5]),

    # 1: index finger pointing up
    "1": dict(flex=[2800, 500,  3200, 3200, 3200], accel=[0.3, 9.7, 0.5]),

    # 2: index and middle up (like V)
    "2": dict(flex=[2800, 500,  500,  3200, 3200], accel=[0.4, 9.6, 0.8]),

    # 3: thumb, index, middle extended
    "3": dict(flex=[500,  500,  500,  3200, 3200], accel=[0.5, 9.5, 1.0]),

    # 4: four fingers extended, thumb tucked
    "4": dict(flex=[3000, 500,  500,  500,  500 ], accel=[0.3, 9.6, 0.8]),

    # 5: all five fingers extended (open hand)
    "5": dict(flex=[500,  500,  500,  500,  500 ], accel=[0.4, 9.5, 1.0]),

    # 6: pinky and thumb touch, others extended
    "6": dict(flex=[1800, 500,  500,  500,  1800], accel=[0.5, 9.4, 1.2]),

    # 7: ring and thumb touch
    "7": dict(flex=[2200, 500,  500,  1800, 500 ], accel=[0.4, 9.5, 1.0]),

    # 8: middle and thumb touch
    "8": dict(flex=[2200, 500,  1800, 500,  500 ], accel=[0.4, 9.5, 1.0]),

    # 9: index and thumb touch (like F/1 hybrid)
    "9": dict(flex=[2200, 1800, 3200, 3200, 3200], accel=[0.5, 9.4, 1.2]),
}


def generate_samples(label, flex_means, accel_means, n=SAMPLES_PER_CLASS):
    rows = []
    for _ in range(n):
        flex = [max(0, min(4095, int(np.random.normal(m, NOISE_STD)))) for m in flex_means]
        accel = [round(np.random.normal(m, ACCEL_NOISE), 4) for m in accel_means]
        # gyro near zero for static signs
        gyro = [round(np.random.normal(0, GYRO_NOISE), 4) for _ in range(3)]
        rows.append(flex + accel + gyro + [label])
    return rows


def main():
    columns = [
        "flex_thumb", "flex_index", "flex_middle", "flex_ring", "flex_pinky",
        "accel_x", "accel_y", "accel_z",
        "gyro_x", "gyro_y", "gyro_z",
        "label"
    ]

    all_rows = []
    for label, params in SIGN_DEFINITIONS.items():
        samples = generate_samples(label, params["flex"], params["accel"])
        all_rows.extend(samples)

    df = pd.DataFrame(all_rows, columns=columns)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)  # shuffle

    output_path = "./data/asl_synthetic.csv"
    df.to_csv(output_path, index=False)

    print(f"Generated {len(df)} samples across {df['label'].nunique()} classes")
    print(f"Saved to {output_path}")
    print(f"\nClass distribution (all should be {SAMPLES_PER_CLASS}):")
    print(df["label"].value_counts().sort_index().to_string())


if __name__ == "__main__":
    main()