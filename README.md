# HelpingHand 🤝

A wearable ASL learning glove with real-time haptic feedback. Built with an ESP32, flex sensors, IMU, and a companion Flutter app.

---

## ML Pipeline (Semester 1)

Classifies static ASL signs (A-Z, 0-9) using a lightweight MLP trained on glove sensor data and exported to TFLite for on-device inference on the ESP32.

---

## Setup

**Prerequisites:** Python 3.10+

**1. Clone the repo**
```bash
git clone https://github.com/GG1627/helping-hand.git
cd helping-hand
```

**2. Create and activate virtual environment**
```bash
python -m venv .venv
```
Windows:
```bash
.venv\Scripts\activate
```
macOS/Linux:
```bash
source .venv/bin/activate
```

**3. Install dependencies**
```bash
pip install -r requirements.txt
```

---

## Running the ML Pipeline

**Generate synthetic training data**
```bash
python generate_asl_data.py
```

**Train the model**

Open and run `asl_train.ipynb` top to bottom. Outputs saved to `models/`.

> When real glove data is available, update `DATA_PATH` in the notebook and rerun.

---

## Deactivate
```bash
deactivate
```