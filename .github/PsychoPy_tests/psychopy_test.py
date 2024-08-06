from psychopy import core, data, logging

# Set logging to error only
logging.console.setLevel(logging.ERROR)

# Create core.Clock instance
clock = core.Clock()

# Define trial conditions
trial_conditions = [{'trialNum': 1, 'waitTime': 1.0}, {'trialNum': 2, 'waitTime': 2.0}, {'trialNum': 3, 'waitTime': 3.0}]

# Create a TrialHandler to manage these conditions
trial_data = data.TrialHandler(trialList=trial_conditions, nReps=1, method='sequential')

# Run through each trial
for trial in trial_data:
    # Reset the clock at the beginning of each trial
    clock.reset()

    # Wait for the specified time for this trial
    core.wait(trial['waitTime'])

    # Print the trial number and the elapsed time
    print(f"Trial {trial['trialNum']}: Elapsed time {clock.getTime()} seconds")

    # Wait for the sound to finish
    core.wait(0.5)

# Exit PsychoPy to clean up everything properly
core.quit()
