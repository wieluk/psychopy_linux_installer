from psychopy import visual, core

# Create dummy attributes for testing purposes
dummy_text = 'Hello, world!'
dummy_color = (-1, -1, -1)
dummy_radius = 0.1
dummy_fillColor = 'red'
dummy_lineColor = 'black'

# Create core.Clock instance and test it
clock = core.Clock()

def test_clock():
    try:
        assert isinstance(clock, core.Clock), "Clock is not an instance of core.Clock"
        print("Clock test passed.")
    except AssertionError as e:
        print(f"Clock test failed: {e}")


# Run the tests
test_clock()

# Exit PsychoPy to clean up everything properly
core.quit()
