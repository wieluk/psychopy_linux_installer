import os
import re
import pytest
from psychopy import core, data, logging, visual, event

# -------------------- Fixtures --------------------

@pytest.fixture
def clock():
    logging.console.setLevel(logging.ERROR)
    return core.Clock()

@pytest.fixture(scope="module")
def script_dir():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    logging.setDefaultClock(core.Clock())
    logging.console.setLevel(logging.WARNING)
    return current_dir

# -------------------- Data/Timing Tests --------------------

def test_trial_timing(clock):
    trial_conditions = [
        {'trialNum': 1, 'waitTime': 1.0},
        {'trialNum': 2, 'waitTime': 2.0},
        {'trialNum': 3, 'waitTime': 3.0}
    ]
    trial_data = data.TrialHandler(trialList=trial_conditions, nReps=1, method='sequential')

    last_trial_output = None
    for trial in trial_data:
        clock.reset()
        core.wait(trial['waitTime'])
        output = f"Trial {trial['trialNum']}: Elapsed time {clock.getTime()} seconds"
        last_trial_output = output
        core.wait(0.5)

    assert last_trial_output is not None
    assert re.match(r"Trial 3: Elapsed time .* seconds", last_trial_output), (
        f"Unexpected final trial output format: {last_trial_output}"
    )

def test_timing_clock():
    timer = core.Clock()
    timer.reset()
    wait_time = 1.0
    core.wait(wait_time)
    elapsed = timer.getTime()
    assert elapsed == pytest.approx(wait_time, abs=0.15), f"Timing inaccurate: expected {wait_time}, got {elapsed}"

# -------------------- Visual and Keyboard Tests --------------------

def test_visual():
    win = visual.Window([800, 600], fullscr=False)
    message = visual.TextStim(win, text="Visual Test")
    message.draw()
    win.flip()
    core.wait(1)
    win.close()

def test_keyboard():
    win = visual.Window([800, 600], fullscr=False)
    message = visual.TextStim(win, text="Keyboard Test")
    message.draw()
    win.flip()
    event._onPygletKey(symbol=ord('a'), modifiers=0)
    core.wait(1)
    keys = event.getKeys()
    win.close()
    assert keys, "No keyboard input detected"
    assert keys[0] == 'a', f"Wrong key detected: expected 'a' but got {keys[0]}"

def test_image(script_dir):
    img_path = os.path.join(script_dir, 'test_image.png')
    assert os.path.exists(img_path), "Test image file not found"

    win = visual.Window([800, 600], fullscr=False)
    img = visual.ImageStim(win, image=img_path)
    img.draw()
    win.flip()
    core.wait(1)
    win.close()

def test_visual_rect():
    win = visual.Window([800, 600], fullscr=False)
    rect = visual.Rect(win, width=0.5, height=0.5, fillColor="red")
    rect.draw()
    win.flip()
    core.wait(1)
    win.close()

def test_visual_circle():
    win = visual.Window([800, 600], fullscr=False)
    circle = visual.Circle(win, radius=0.2, fillColor="blue")
    circle.draw()
    win.flip()
    core.wait(1)
    win.close()
