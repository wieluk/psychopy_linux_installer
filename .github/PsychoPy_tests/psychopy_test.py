import unittest
from psychopy import core, data, logging
import re

class TestPsychoPyBasic(unittest.TestCase):
    def setUp(self):
        logging.console.setLevel(logging.ERROR)
        self.clock = core.Clock()
        
    def test_trial_timing(self):
        trial_conditions = [
            {'trialNum': 1, 'waitTime': 1.0},
            {'trialNum': 2, 'waitTime': 2.0},
            {'trialNum': 3, 'waitTime': 3.0}
        ]
        trial_data = data.TrialHandler(trialList=trial_conditions, nReps=1, method='sequential')
        
        last_trial_output = None
        for trial in trial_data:
            self.clock.reset()
            core.wait(trial['waitTime'])
            output = f"Trial {trial['trialNum']}: Elapsed time {self.clock.getTime()} seconds"
            print(output)  # Keep printing for debugging
            last_trial_output = output
            core.wait(0.5)
            
        # Verify the last trial output format
        self.assertIsNotNone(last_trial_output)
        self.assertTrue(
            re.match(r"Trial 3: Elapsed time .* seconds", last_trial_output),
            f"Unexpected final trial output format: {last_trial_output}"
        )
        
if __name__ == '__main__':
    unittest.main(verbosity=2)
