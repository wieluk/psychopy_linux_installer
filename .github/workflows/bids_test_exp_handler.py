from psychopy import core, data

import seedir as sd
import pandas as pd

from psychopy_bids.bids import BIDSTaskEvent
from psychopy_bids.bids import BIDSHandler

clock = core.Clock()

info = {"participant_id": "01", "sex": "male", "age": 20}

# Make a dummy experiment structure and generate some data
exp = data.ExperimentHandler(name='experiment_handler',
                             extraInfo={'participant_id': 'A',
                                        'session': 1,
                                        'sex': 'M',
                                        'age': 20},
                             runtimeInfo=None,
                             originPath=None,
                             savePickle=True,
                             saveWideText=True,
                             dataFileName='simple')


exp.addData(
    "start",
    BIDSTaskEvent(onset=clock.getTime(), duration=0, trial_type="start")
)

outerLoop = data.TrialHandler(
    trialList=[1, 2, 3], nReps=1, name='stairBlock', method='random'
)
exp.addLoop(outerLoop)
for thisRep in outerLoop:
    number = BIDSTaskEvent(
        onset=clock.getTime(),
        duration=0,
        trial_type="number",
        value=thisRep
    )
    exp.addData("number", number)
    exp.nextEntry()

exp.addData(
    "stop",
    BIDSTaskEvent(onset=clock.getTime(), duration=0, trial_type="stop")
)

# Get subject and events from the ExperimentHandler
ignore_list = ['participant',
               'session',
               'date',
               'expName',
               'psychopyVersion',
               'OS',
               'frameRate']
subject = {key: exp.extraInfo[key] for key in exp.extraInfo if key not in ignore_list}
events = list(exp.getAllEntries()[0].values())

# Init a bids handler and create/update the dataset
handler = BIDSHandler(
    dataset="experiment_handler", subject=subject['participant_id'], task="task1"
)
handler.createDataset()
tsv_file = handler.addTaskEvents(events, subject)

sd.seedir('experiment_handler')

df = pd.read_csv(tsv_file, sep='\t')
df.head()