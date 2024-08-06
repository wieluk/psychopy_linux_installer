import seedir as sd
import pandas as pd

from psychopy_bids.bids import BIDSTaskEvent
from psychopy_bids.bids import BIDSHandler

subject = {"participant_id": "01", "sex": "male", "age": 20}

start = BIDSTaskEvent(onset=0, duration=0, trial_type="start")
presentation = BIDSTaskEvent(onset=0.5, duration=5, trial_type="presentation")
stop = BIDSTaskEvent(onset=10, duration=0, trial_type="stop")

events = [start, presentation, stop]

handler = BIDSHandler(
    dataset="simple_dataset",
    subject=subject['participant_id'],
    task="task1")
handler.createDataset()
tsv_file = handler.addTaskEvents(events, subject)

sd.seedir('simple_dataset')
df = pd.read_csv(tsv_file, sep='\t')
df.head()