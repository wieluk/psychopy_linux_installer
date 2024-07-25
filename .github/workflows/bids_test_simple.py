import seedir as sd
import pandas as pd

from psychopy_bids.bids import BIDSTaskEvent, BIDSHandler

# Define the base path for saving files
base_path = '/tmp_dir'

subject = {"participant_id": "01", "sex": "male", "age": 20}

start = BIDSTaskEvent(onset=0, duration=0, trial_type="start")
presentation = BIDSTaskEvent(onset=0.5, duration=5, trial_type="presentation")
stop = BIDSTaskEvent(onset=10, duration=0, trial_type="stop")

events = [start, presentation, stop]

handler = BIDSHandler(
    dataset=f"{base_path}/simple_dataset",  # Use the base path variable
    subject=subject['participant_id'],
    task="task1"
)
handler.createDataset()
tsv_file = handler.addTaskEvents(events, subject)

# List the directory contents for debugging
sd.seedir(f"{base_path}/simple_dataset")

df = pd.read_csv(tsv_file, sep='\t')
print(df.head())
