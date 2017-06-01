import json


def is_not_bot(e):
    user_agent_dict = json.loads(e['userAgent'])
    try:
        return (not user_agent_dict['is_bot']) or (user_agent_dict['is_mediawiki'])
    except (ValueError, KeyError):
        return True
