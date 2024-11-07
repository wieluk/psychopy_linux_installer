import unittest
import os
import shutil
import seedir as sd
import pandas as pd
from psychopy_bids.bids import BIDSTaskEvent, BIDSHandler

class TestBIDSSimple(unittest.TestCase):
    def setUp(self):
        self.dataset_name = "simple_dataset"
        self.subject = {"participant_id": "01", "sex": "male", "age": 20}
        # Clean up any existing test datasets
        if os.path.exists(self.dataset_name):
            shutil.rmtree(self.dataset_name)
    
    def tearDown(self):
        # Clean up after tests
        if os.path.exists(self.dataset_name):
            shutil.rmtree(self.dataset_name)
    
    def test_simple_bids(self):
        """Test basic BIDS functionality"""
        # Create events
        start = BIDSTaskEvent(onset=0, duration=0, trial_type="start")
        presentation = BIDSTaskEvent(onset=0.5, duration=5, trial_type="presentation")
        stop = BIDSTaskEvent(onset=10, duration=0, trial_type="stop")
        events = [start, presentation, stop]
        
        # Create and populate dataset
        handler = BIDSHandler(
            dataset=self.dataset_name,
            subject=self.subject['participant_id'],
            task="task1")
        handler.createDataset()
        tsv_file = handler.addTaskEvents(events, self.subject)
        
        # Print directory structure (for debugging)
        sd.seedir(self.dataset_name)
        
        # Verify results
        self.assertTrue(os.path.exists(tsv_file), "TSV file should exist")
        df = pd.read_csv(tsv_file, sep='\t')
        
        # Verify data structure
        self.assertEqual(len(df), 3, "Should have exactly 3 events")
        self.assertEqual(df['trial_type'].tolist(), ['start', 'presentation', 'stop'])
        self.assertEqual(df['onset'].tolist(), [0, 0.5, 10])
        self.assertEqual(df['duration'].tolist(), [0, 5, 0])

if __name__ == '__main__':
    unittest.main(verbosity=2)