import os
from psychopy import visual, core, event, sound, logging

script_dir = os.path.dirname(os.path.abspath(__file__))
log_file = os.path.join(script_dir, "psychopy_test_extended.log")

logging.setDefaultClock(core.Clock())
logging.LogFile(log_file, level=logging.WARNING)
logging.console.setLevel(logging.WARNING)

def test_visual():
    try:
        win = visual.Window([800, 600], fullscr=False)
        message = visual.TextStim(win, text="Visual Test")
        message.draw()
        win.flip()
        core.wait(1)
        win.close()
        logging.warning("Visual Test Passed")
    except Exception as e:
        logging.error(f"Visual Test Failed: {e}")

def test_keyboard():
    try:
        win = visual.Window([800, 600], fullscr=False)
        message = visual.TextStim(win, text="Keyboard Test")
        message.draw()
        win.flip()
        event._onPygletKey(symbol=ord('a'), modifiers=0)  # Simulate key press
        core.wait(1)
        keys = event.getKeys()
        win.close()
        if keys:
            logging.warning("Keyboard Test Passed")
        else:
            logging.error("Keyboard Test Failed: No key detected")
    except Exception as e:
        logging.error(f"Keyboard Test Failed: {e}")

def test_image():
    try:
        win = visual.Window([800, 600], fullscr=False)
        img_path = os.path.join(script_dir, 'test_image.png')
        img = visual.ImageStim(win, image=img_path)
        img.draw()
        win.flip()
        core.wait(1)
        win.close()
        logging.warning("Image Test Passed")
    except Exception as e:
        logging.error(f"Image Test Failed: {e}")

def test_timing():
    try:
        timer = core.Clock()
        timer.reset()
        core.wait(1)
        elapsed = timer.getTime()
        if abs(elapsed - 1) < 0.15:  # Allow a small error margin
            logging.warning("Timing Test Passed")
        else:
            logging.error(f"Timing Test Failed: Elapsed time {elapsed} seconds")
    except Exception as e:
        logging.error(f"Timing Test Failed: {e}")

def test_audio():
    try:
        audio_path = os.path.join(script_dir, 'beep.wav')
        beep = sound.Sound(audio_path)
        beep.play()
        core.wait(beep.getDuration())
        logging.warning("Audio Test Passed")
    except Exception as e:
        logging.error(f"Audio Test Failed: {e}")

def run_tests():
    logging.console.setLevel(logging.WARNING)
    logging.warning("Starting PsychoPy Tests")
    
    test_visual()
    test_keyboard()
    test_image()
    test_timing()
    test_audio()

    logging.warning("PsychoPy Tests Completed")

if __name__ == "__main__":
    try:
        run_tests()
    except Exception as e:
        logging.error(f"PsychoPy Tests Failed: {e}")
