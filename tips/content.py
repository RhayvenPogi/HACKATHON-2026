"""Topics people can ask tips for, plus reviewed fallback tips.

Only these fixed topic keys are ever sent to the AI provider. No
questionnaire answers, scores or free text are sent.
"""

TOPICS = {
    "sleep": "sleeping better",
    "stress": "handling everyday stress",
    "worry": "coping with worry and racing thoughts",
    "low_mood": "low mood and low motivation",
    "school_work": "pressure from school or work",
    "relationships": "feeling disconnected or lonely",
}

TOPIC_LABELS = {
    "sleep": "Sleep",
    "stress": "Stress",
    "worry": "Worry",
    "low_mood": "Low mood",
    "school_work": "School or work",
    "relationships": "Feeling lonely",
}

# Used whenever the AI is unavailable, slow, or returns something unsafe.
CURATED_TIPS = {
    "sleep": [
        ("Keep a steady schedule", "Try to sleep and wake at about the same time every day, including weekends."),
        ("Wind down without screens", "Put your phone away 30 minutes before bed and do something calm instead."),
        ("Watch late caffeine", "Avoid coffee, energy drinks and strong tea in the late afternoon and evening."),
    ],
    "stress": [
        ("Slow your breathing", "Breathe in for 4 counts and out for 6 counts, a few times, when you feel tense."),
        ("Break it down", "Write down what is on your mind and pick one small step you can do today."),
        ("Move a little", "A short walk or light stretching can ease tension and clear your head."),
    ],
    "worry": [
        ("Set a worry time", "Give worries 15 minutes a day. When they come at other times, note them for later."),
        ("Ground yourself", "Name five things you can see, four you can hear and three you can touch."),
        ("Talk it through", "Sharing a worry with someone you trust can make it feel more manageable."),
    ],
    "low_mood": [
        ("Start very small", "Choose one easy task, like making your bed or a short walk, and count it as a win."),
        ("Stay connected", "Send a message to a friend or family member, even if you do not feel like it."),
        ("Get some daylight", "Spend a little time outside or near a window during the day."),
    ],
    "school_work": [
        ("Plan the week", "List your deadlines and spread the work out so it does not pile up at the end."),
        ("Take real breaks", "Short breaks away from your desk help you focus better when you return."),
        ("Ask early", "If something is too much, talk to a teacher, supervisor or classmate sooner rather than later."),
    ],
    "relationships": [
        ("Reach out once", "Reconnect with one person today with a simple message or call."),
        ("Join something", "A club, class, church or volunteer group is an easy way to meet people."),
        ("Be kind to yourself", "Feeling lonely is common and does not mean something is wrong with you."),
    ],
}
