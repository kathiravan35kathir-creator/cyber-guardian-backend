import statistics

user_click_history = []

def detect_behavior_anomaly(new_click_value):
    user_click_history.append(new_click_value)

    if len(user_click_history) < 5:
        return 0

    mean = statistics.mean(user_click_history)
    stdev = statistics.stdev(user_click_history)

    if new_click_value > mean + (2 * stdev):
        return 5
    return 0