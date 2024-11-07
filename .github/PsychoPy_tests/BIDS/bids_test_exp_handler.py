import unittest
import os
import shutil
import seedir as sd
import pandas as pd
from psychopy import core, data
from psychopy_bids.bids import BIDSTaskEvent, BIDSHandler

class TestBIDSExpHandler(unittest.TestCase):
    def setUp(self):
        self.dataset_name = "experiment_handler"
        self.clock = core.Clock()
        self.info = {"participant_id": "01", "sex": "male", "age": 20}
        # Clean up any existing test datasets
        if os.path.exists(self.dataset_name):
            shutil.rmtree(self.dataset_name)
    
    def tearDown(self):
        # Clean up after tests
        if os.path.exists(self.dataset_name):
            shutil.rmtree(self.dataset_name)
    
    def test_exp_handler_bids(self):
        """Test BIDS with ExperimentHandler"""
        # Setup experiment
        exp = data.ExperimentHandler(
            name='experiment_handler',
            extraInfo={'participant_id': 'A',
                      'session': 1,
                      'sex': 'M',
                      'age': 20},
            runtimeInfo=None,
            originPath=None,
            savePickle=True,
            saveWideText=True,
            dataFileName='simple')
        
        # Add start event
        exp.addData(
            "start",
            BIDSTaskEvent(onset=self.clock.getTime(), duration=0, trial_type="start")
        )
        
        # Run trials
        outerLoop = data.TrialHandler(
            trialList=[1, 2, 3], nReps=1, name='stairBlock', method='random'
        )
        exp.addLoop(outerLoop)
        for thisRep in outerLoop:
            number = BIDSTaskEvent(
                onset=self.clock.getTime(),
                duration=0,
                trial_type="number",
                value=thisRep
            )
            exp.addData("number", number)
            exp.nextEntry()
        
        # Add stop event
        exp.addData(
            "stop",
            BIDSTaskEvent(onset=self.clock.getTime(), duration=0, trial_type="stop")
        )
        
        # Get subject and events
        ignore_list = ['participant', 'session', 'date', 'expName',
                      'psychopyVersion', 'OS', 'frameRate']
        subject = {key: exp.extraInfo[key] for key in exp.extraInfo 
                  if key not in ignore_list}
        events = list(exp.getAllEntries()[0].values())
        
        # Create BIDS dataset
        handler = BIDSHandler(
            dataset=self.dataset_name,
            subject=subject['participant_id'],
            task="task1"
        )
        handler.createDataset()
        tsv_file = handler.addTaskEvents(events, subject)
        
        # Print directory structure (for debugging)
        sd.seedir(self.dataset_name)
        
        # Verify results
        self.assertTrue(os.path.exists(tsv_file), "TSV file should exist")
        df = pd.read_csv(tsv_file, sep='\t')
        
        # Verify data structure
        self.assertEqual(len(df), 5, "Should have 5 events (start + 3 numbers + stop)")
        self.assertTrue('start' in df['trial_type'].tolist(), "Should have start event")
        self.assertTrue('stop' in df['trial_type'].tolist(), "Should have stop event")
        self.assertEqual(len(df[df['trial_type'] == 'number']), 3, 
                        "Should have exactly 3 number trials")

if __name__ == '__main__':
    unittest.main(verbosity=2)