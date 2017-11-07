import json


def should_insert_event(e):
    """
    Given an Event dict e, returns true if this event should be inserted into the
    EventLogging storage (MySQL), or false otherwise.  This is used
    to filter out events generated by unwanted bots.
    """
    # If no userAgent information, then insert anyway.
    if 'userAgent' not in e:
        return True

    try:
        user_agent_dict = json.loads(e['userAgent'])
    except ValueError:
        if isinstance(e['userAgent'], str):
            return True
        # MySQL doesn't know how to insert a non string UA!
        else:
            return False

    is_bot = user_agent_dict.get('is_bot', False)
    is_mediawiki = user_agent_dict.get('is_mediawiki', False)

    # Don't insert events generated by bots unless they are mediawiki bots.
    if is_bot and not is_mediawiki:
        return False
    else:
        return True
