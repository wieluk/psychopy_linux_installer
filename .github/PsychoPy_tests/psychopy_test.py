from psychopy import core, data, logging

logging.console.setLevel(logging.ERROR)

clock = core.Clock()
trial_conditions = [{'trialNum': 1, 'waitTime': 1.0}, {'trialNum': 2, 'waitTime': 2.0}, {'trialNum': 3, 'waitTime': 3.0}]
trial_data = data.TrialHandler(trialList=trial_conditions, nReps=1, method='sequential')

for trial in trial_data:
    clock.reset()
    core.wait(trial['waitTime'])
    print(f"Trial {trial['trialNum']}: Elapsed time {clock.getTime()} seconds")
    core.wait(0.5)

core.quit()
