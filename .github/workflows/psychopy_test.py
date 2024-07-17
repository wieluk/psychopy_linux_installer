# Import necessary PsychoPy modules
from psychopy import visual, core, event, logging

# Set up a window for testing (even though we won't display it)
# Using 'autoLog' to avoid unnecessary logging output
win = visual.Window(size=(800, 600), fullscr=False, screen=0, allowGUI=True, 
                    monitor='testMonitor', color=[1, 1, 1], colorSpace='rgb', 
                    autoLog=False)

# Create some visual components
text_stim = visual.TextStim(win=win, text='Hello, world!', color=(-1, -1, -1))
circle_stim = visual.Circle(win=win, radius=0.1, fillColor='red', lineColor='black')

# Create a core component
clock = core.Clock()

# Function to test if components are correctly initialized
def test_components():
    try:
        assert text_stim.text == 'Hello, world!', "TextStim text does not match"
        assert text_stim.color == (-1, -1, -1), "TextStim color does not match"
        assert circle_stim.radius == 0.1, "CircleStim radius does not match"
        assert circle_stim.fillColor == 'red', "CircleStim fillColor does not match"
        assert circle_stim.lineColor == 'black', "CircleStim lineColor does not match"
        assert isinstance(clock, core.Clock), "Clock is not an instance of core.Clock"
        print("All components initialized correctly.")
    except AssertionError as e:
        print(f"Test failed: {e}")

# Run the test
test_components()

# Close the window (important to clean up resources)
win.close()

# Exit PsychoPy to clean up everything properly
core.quit()
