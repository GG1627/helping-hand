# Project Setup

Follow these instructions to set up the repository and run the project locally.

## Prerequisites

Ensure you have [Python](https://www.python.org/downloads/) installed on your system.

## Installation & Setup

**1. Clone the repository (if you haven't already)**
```bash
git clone https://github.com/GG1627/helping-hand.git
cd helping-hand
```

**2. Create the virtual environment**
Create a virtual environment named `venv` in the root directory of the project:
```bash
python -m venv .venv
```
*(Note: Depending on your system, you might need to use `python3` instead of `python`)*

**3. Activate the virtual environment**
You need to activate the virtual environment before installing dependencies or running the code.

* **On Windows:**
  ```bash
  venv\Scripts\activate
  ```
* **On macOS and Linux:**
  ```bash
  source venv/bin/activate
  ```
*(You should now see `(venv)` at the beginning of your terminal prompt.)*

**4. Install dependencies**
With the virtual environment activated, install the required packages using `pip`:
```bash
pip install -r requirements.txt
```

---

## Deactivating the Environment
When you are done working on the project, you can easily exit the virtual environment by running:
```bash
deactivate
```