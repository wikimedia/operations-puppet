import dateutil.parser
import json
import time
import unittest
import logging

"""
If a schema is in this list, it will be mapped to None, causing
eventlogging-processor to skip it.  This will be used
for the migration to Event Platform, away from the python eventlogging
backend.  Once a schema has been fully migrated to an Event Platform stream,
it can be added to this list.
See: https://phabricator.wikimedia.org/T259163
"""
eventlogging_schemas_disabled = (
    # Deleted schemas (on metawiki)
    'CitationUsagePageLoad',
    'CitationUsage',
    'ReadingDepth',
    'EditConflict',

    'ContentTranslationAbuseFilter',
    'DesktopWebUIActionsTracking',
    'MobileWebUIActionsTracking',
    'PrefUpdate',
    'QuickSurveyInitiation',
    'QuickSurveysResponses',
    'SpecialInvestigate',
    'SearchSatisfaction',
    'SuggestedTagsAction',
    'TemplateWizard',
    'Test',
    'UniversalLanguageSelector',
    'WikidataCompletionSearchClicks',

    # Editor schemas
    'EditAttemptStep',
    'VisualEditorFeatureUse',

    # Growth team schemas
    'HelpPanel',
    'HomepageModule',
    'NewcomerTask',
    'HomepageVisit',
    'ServerSideAccountCreation',

    # NavigationTiming extension legacy schemas
    'CpuBenchmark',
    'NavigationTiming',
    'PaintTiming',
    'SaveTiming',

    # WMDE Technical Wishes schemas
    'CodeMirrorUsage',
    'ReferencePreviewsBaseline',
    'ReferencePreviewsCite',
    'ReferencePreviewsPopups',
    'TemplateDataApi',
    'TemplateDataEditor',
    'TwoColConflictConflict',
    'TwoColConflictExit',
    'VirtualPageView',
    'VisualEditorTemplateDialogUse',
    'WikibaseTermboxInteraction',
    'WMDEBannerEvents',
    'WMDEBannerInteractions',
    'WMDEBannerSizeIssue',

    # FR Tech schemas
    'LandingPageImpression',
    'CentralNoticeBannerHistory',
    'CentralNoticeImpression',

    # TranslationRecommendation schemas
    'TranslationRecommendationUserAction',
    'TranslationRecommendationUIRequests',
    'TranslationRecommendationAPIRequests',

    # Readers Web schemas
    'WikipediaPortal',
)


def eventlogging_schemas_disabled_filter(event):
    """
    Returns None if this event's schema_name is in
    eventlogging_schemas_disabled list, else the event.
    """
    schema_name = event.get('schema', '')
    if schema_name in eventlogging_schemas_disabled:
        logging.warn('Encountered event with disabled schema %s, skipping.', schema_name)
        return None

    return event


def mysql_mapper(event):
    """
    The WMF EventLogging Analytics MySQL log database has a lot of curious
    legacy compatibility problems.  This function converts an event
    to a format that the MySQL database expects.  If an event comes from
    a non-MediaWiki bot, it will be mapped to 'None' and thus excluded from the stream.
    """
    if 'userAgent' in event and isinstance(event['userAgent'], dict):
        # Get rid of unwanted bots. T67508
        is_bot = event['userAgent'].get('is_bot', False)
        is_mediawiki = event['userAgent'].get('is_mediawiki', False)
        # Don't insert events generated by bots unless they are mediawiki bots.
        if is_bot and not is_mediawiki:
            # Returning None will cause map://
            # reader to exclude this event.
            return None

        # MySQL expects that userAgent is a string, so we
        # convert it to JSON string now.  T153207
        event['userAgent'] = json.dumps(event['userAgent'])

    # jrm.py expects an integer `timestamp` field to convert into
    #  MediaWiki timestamp. Inject it into the event.
    if 'dt' in event:
        # Use the time from `dt`
        event['timestamp'] = int(dateutil.parser.parse(event['dt']).strftime("%s"))
        # Historicaly, EventCapsule did not have `dt` so we remove it from
        # insertion into MySQL.
        del event['dt']
    else:
        # Else just use current time.
        event['timestamp'] = int(time.time())

    return event


# ##### Tests ######
# To run:
#   python -m unittest -v plugins.py
# Or:
#   python plugins.py
#
class TestEventLoggingPlugins(unittest.TestCase):
    def test_mysql_mapper(self):
        e1 = {
            'dt': '2017-11-01T11:00:00',
            'userAgent': {'browser_family': 'Chrome'}
        }
        should_be1 = {'timestamp': 1509548400, 'userAgent': '{"browser_family": "Chrome"}'}
        self.assertEqual(mysql_mapper(e1), should_be1)

        e2 = {
            'dt': '2017-11-01T11:00:00',
            'userAgent': {'is_bot': True}
        }
        self.assertEqual(mysql_mapper(e2), None)

        e3 = {
            'dt': '2017-11-01T11:00:00',
            'userAgent': {'is_bot': True, 'is_mediawiki': True}
        }
        should_be3 = {'timestamp': 1509548400, 'userAgent': json.dumps(e3['userAgent'])}
        self.assertEqual(mysql_mapper(e3), should_be3)


if __name__ == '__main__':
    unittest.main(verbosity=2)
