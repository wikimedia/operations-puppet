import json
import dateutil.parser
from datetime import datetime
import unittest


# Format string for :func:`datetime.datetime.strptime` for MediaWiki
# timestamps. See `<https://www.mediawiki.org/wiki/Manual:Timestamp>`_.
MEDIAWIKI_TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'
def inject_mediawiki_timestamp(e):
    """
    Convert dt to backwards compatible Mediawiki timestamp field.
    If dt is not in event, use current time. T179540
    """

    if 'dt' in e:
        dt = dateutil.parser.parse(e['dt'])
    else:
        dt = datetime.utcnow()

    e['timestamp'] = dt.strftime(MEDIAWIKI_TIMESTAMP_FORMAT)
    return e


def mysql_mapper(e):
    """
    The WMF EventLogging Analytics MySQL log database has a lot of curious
    legacy compatibility problems.  This function converts an event
    to a format that the MySQL database expects.
    """
    if 'userAgent' in e and isinstance(e['userAgent'], dict):
        # Get rid of unwanted bots. T67508
        is_bot = e['userAgent'].get('is_bot', False)
        is_mediawiki = e['userAgent'].get('is_mediawiki', False)
        # Don't insert events generated by bots unless they are mediawiki bots.
        if is_bot and not is_mediawiki:
            # Returning None will cause map://
            # reader to exclude this event.
            return None

        # MySQL expects that userAgent is a string, so we
        # convert it to JSON string now.  T153207
        e['userAgent'] = json.dumps(e['userAgent'])

    # Historicaly, EventCapsule did not have `dt` so we remove it from
    # insertion into MySQL.
    if 'dt' in e:
        del e['dt']

    return e


# ##### Tests ######
# To run:
#   python -m unittest -v plugins.py
# Or:
#   python plugins.py
#
class TestEventLoggingPlugins(unittest.TestCase):
    def test_inject_mediawiki_timestamp(self):
        e = {'dt': '2017-11-01T11:00:00', 'userAgent': {}}
        should_be = {'dt': '2017-11-01T11:00:00', 'timestamp': '20171101110000', 'userAgent': {}}
        self.assertEqual(inject_mediawiki_timestamp(e), should_be)

    def test_mysql_mapper(self):
        e1 = {'dt': '2017-11-01T11:00:00', 'timestamp': '20171101110000', 'userAgent': {'browser_family': 'Chrome'}}
        should_be1 = {'timestamp': '20171101110000', 'userAgent': '{"browser_family": "Chrome"}'}
        self.assertEqual(mysql_mapper(e1), should_be1)

        e2 = {'dt': '2017-11-01T11:00:00', 'timestamp': '20171101110000', 'userAgent': {'is_bot': True}}
        self.assertEqual(mysql_mapper(e2), None)

if __name__ == '__main__':
    unittest.main(verbosity=2)