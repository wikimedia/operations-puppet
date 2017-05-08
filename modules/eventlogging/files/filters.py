import json


def is_not_bot(e):
    try:
        return not json.loads(e['userAgent'])['is_bot']
    except (ValueError, KeyError):
        return True
