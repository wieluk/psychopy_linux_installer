import os
import sys
import unittest
from psychopy import prefs, visual, core, event, sound, logging

prefs.hardware['audioLib'] = ['sounddevice', 'pyo', 'dummy']

class PsychopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script_dir = os.path.dirname(os.path.abspath(__file__))
        logging.setDefaultClock(core.Clock())
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
            error_message = str(e).lower()
            if isinstance(e, IndexError) or "list index out of range" in error_message or "manageddeviceerror" in error_message:
                self.skipTest(f"Audio hardware not available or misconfigured: {str(e)}")
            elif isinstance(e, AttributeError) and "_masterstream" in error_message and "handle" in error_message:
                self.skipTest(f"Audio hardware backend error: {str(e)}")
            else:
                self.fail(f"Unexpected exception during audio test: {str(e)}")

if __name__ == "__main__":
    suite = unittest.TestLoader().loadTestsFromTestCase(PsychopyTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)

    sys.exit(not result.wasSuccessful())
