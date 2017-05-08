import json


def exclude_bots(e):
    return not json.loads(e['userAgent'])['is_bot']
