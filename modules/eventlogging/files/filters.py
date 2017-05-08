import json


def exclude_bots(e):
    try:
        return not json.loads(e['userAgent'])['is_bot']
    except (ValueError, KeyError):
        return True