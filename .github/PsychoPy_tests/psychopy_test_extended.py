import os
import sys
import unittest
from psychopy import prefs, visual, core, event, sound, logging

prefs.hardware['audioLib'] = ['sounddevice', 'dummy']

class PsychopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script_dir = os.path.dirname(os.path.abspath(__file__))
        cls.log_file = os.path.join(cls.script_dir, "psychopy_test_extended.log")
        logging.setDefaultClock(core.Clock())
        logging.LogFile(cls.log_file, level=logging.WARNING)
        logging.console.setLevel(logging.WARNING)

    def test_visual(self):
        win = visual.Window([800, 600], fullscr=False)
        message = visual.TextStim(win, text="Visual Test")
        message.draw()
        win.flip()
        core.wait(1)
        win.close()

    def test_keyboard(self):
        win = visual.Window([800, 600], fullscr=False)
        message = visual.TextStim(win, text="Keyboard Test")
        message.draw()
        win.flip()
        event._onPygletKey(symbol=ord('a'), modifiers=0)
        core.wait(1)
        keys = event.getKeys()
        win.close()
        self.assertTrue(keys, "No keyboard input detected")
        self.assertEqual(keys[0], 'a', "Wrong key detected")

    def test_image(self):
        img_path = os.path.join(self.script_dir, 'test_image.png')
        self.assertTrue(os.path.exists(img_path), "Test image file not found")
        
        win = visual.Window([800, 600], fullscr=False)
        img = visual.ImageStim(win, image=img_path)
        img.draw()
        win.flip()
        core.wait(1)
        win.close()

    def test_timing(self):
        timer = core.Clock()
        timer.reset()
        wait_time = 1.0
        core.wait(wait_time)
        elapsed = timer.getTime()
        self.assertAlmostEqual(elapsed, wait_time, delta=0.15, 
                             msg=f"Timing inaccurate: expected {wait_time}, got {elapsed}")

    def test_audio(self):
        audio_path = os.path.join(self.script_dir, 'beep.wav')
        self.assertTrue(os.path.exists(audio_path), "Audio file not found")
        
        try:
            beep = sound.Sound(audio_path)
            beep.play()
            core.wait(beep.getDuration())
        except Exception as e:
            if isinstance(e, IndexError) or "list index out of range" in str(e).lower() or "ManagedDeviceError" in str(e):
                self.skipTest(f"Audio hardware not available or misconfigured: {str(e)}")
            else:
                self.fail(f"Unexpected exception during audio test: {str(e)}")

if __name__ == "__main__":
    suite = unittest.TestLoader().loadTestsFromTestCase(PsychopyTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)

    sys.exit(not result.wasSuccessful())
