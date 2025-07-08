"""Shared configuration for the installer speed analysis scripts."""
from pathlib import Path

# Directory structure
SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR / "data"
PLOTS_DIR = SCRIPT_DIR / "duration_plots"

# File paths
CSV_FILE = DATA_DIR / "durations.csv"
JSON_CACHE = DATA_DIR / "runs.json"

# GitHub repository
REPO = "wieluk/psychopy_linux_installer"

# GitHub Actions step name to track
STEP_NAME = "Setup environment and install"

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
PLOTS_DIR.mkdir(exist_ok=True)
