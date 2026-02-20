def calculate_risk(call_score, message_score, link_score, behavior_score):
    
    w1 = 0.2
    w2 = 0.3
    w3 = 0.3
    w4 = 0.2

    risk = (w1 * call_score) + \
           (w2 * message_score) + \
           (w3 * link_score) + \
           (w4 * behavior_score)

    return round(risk * 10, 2)