#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import json
import logging
import re
import socket
import unittest
import yaml

from kafka import KafkaConsumer

handlers = {}

# Mapping of continent names to ISO 3166 country codes.
# From https://dev.maxmind.com/geoip/legacy/codes/country_continent/.
# Antarctica excluded on account of its miniscule population.
iso_3166_continent = {
    'Africa': [
        'AO', 'BF', 'BI', 'BJ', 'BW', 'CD', 'CF', 'CG', 'CI', 'CM', 'CV', 'DJ',
        'DZ', 'EG', 'EH', 'ER', 'ET', 'GA', 'GH', 'GM', 'GN', 'GQ', 'GW', 'KE',
        'KM', 'LR', 'LS', 'LY', 'MA', 'MG', 'ML', 'MR', 'MU', 'MW', 'MZ', 'NA',
        'NE', 'NG', 'RE', 'RW', 'SC', 'SD', 'SH', 'SL', 'SN', 'SO', 'ST', 'SZ',
        'TD', 'TG', 'TN', 'TZ', 'UG', 'YT', 'ZA', 'ZM', 'ZW'
    ],
    'Asia': [
        'AE', 'AF', 'AM', 'AP', 'AZ', 'BD', 'BH', 'BN', 'BT', 'CC', 'CN', 'CX',
        'CY', 'GE', 'HK', 'ID', 'IL', 'IN', 'IO', 'IQ', 'IR', 'JO', 'JP', 'KG',
        'KH', 'KP', 'KR', 'KW', 'KZ', 'LA', 'LB', 'LK', 'MM', 'MN', 'MO', 'MV',
        'MY', 'NP', 'OM', 'PH', 'PK', 'PS', 'QA', 'SA', 'SG', 'SY', 'TH', 'TJ',
        'TL', 'TM', 'TW', 'UZ', 'VN', 'YE'
    ],
    'Europe': [
        'AD', 'AL', 'AT', 'AX', 'BA', 'BE', 'BG', 'BY', 'CH', 'CZ', 'DE', 'DK',
        'EE', 'ES', 'EU', 'FI', 'FO', 'FR', 'FX', 'GB', 'GG', 'GI', 'GR', 'HR',
        'HU', 'IE', 'IM', 'IS', 'IT', 'JE', 'LI', 'LT', 'LU', 'LV', 'MC', 'MD',
        'ME', 'MK', 'MT', 'NL', 'NO', 'PL', 'PT', 'RO', 'RS', 'RU', 'SE', 'SI',
        'SJ', 'SK', 'SM', 'TR', 'UA', 'VA'
    ],
    'North America': [
        'AG', 'AI', 'AN', 'AW', 'BB', 'BL', 'BM', 'BS', 'BZ', 'CA', 'CR', 'CU',
        'DM', 'DO', 'GD', 'GL', 'GP', 'GT', 'HN', 'HT', 'JM', 'KN', 'KY', 'LC',
        'MF', 'MQ', 'MS', 'MX', 'NI', 'PA', 'PM', 'PR', 'SV', 'TC', 'TT', 'US',
        'VC', 'VG', 'VI'
    ],
    'Oceania': [
        'AS', 'AU', 'CK', 'FJ', 'FM', 'GU', 'KI', 'MH', 'MP', 'NC', 'NF', 'NR',
        'NU', 'NZ', 'PF', 'PG', 'PN', 'PW', 'SB', 'TK', 'TO', 'TV', 'UM', 'VU',
        'WF', 'WS'
    ],
    'South America': [
        'AR', 'BO', 'BR', 'CL', 'CO', 'EC', 'FK', 'GF', 'GY', 'PE', 'PY', 'SR',
        'UY', 'VE'
    ]
}

iso_3166_countries = {}
for continent, countries in iso_3166_continent.items():
    for country in countries:
        iso_3166_countries[country] = continent

# Map of ISO 3166-1 country codes to country name, with entries for the world's
# 40 most populous countries as of 1 January 2016, plus Australia. About 83% of
# the world's population lives in one of these countries. Australia is included
# because it has a large user base while being remote from anywhere else.
# Australia
iso_3166_top_40_plus_australia = {
    'AR': 'Argentina',      'BD': 'Bangladesh',       'BR': 'Brazil',
    'CA': 'Canada',         'CD': 'DR Congo',         'CN': 'China',
    'CO': 'Colombia',       'DE': 'Germany',          'DZ': 'Algeria',
    'EG': 'Egypt',          'ES': 'Spain',            'ET': 'Ethiopia',
    'FR': 'France',         'GB': 'United Kingdom',   'ID': 'Indonesia',
    'IN': 'India',          'IQ': 'Iraq',             'IR': 'Iran',
    'IT': 'Italy',          'JP': 'Japan',            'KE': 'Kenya',
    'KR': 'South Korea',    'MA': 'Morocco',          'MM': 'Myanmar',
    'MX': 'Mexico',         'NG': 'Nigeria',          'PH': 'Philippines',
    'PK': 'Pakistan',       'PL': 'Poland',           'RU': 'Russia',
    'SA': 'Saudi Arabia',   'SD': 'Sudan',            'TH': 'Thailand',
    'TR': 'Turkey',         'TZ': 'Tanzania',         'UA': 'Ukraine',
    'UG': 'Uganda',         'US': 'United States',    'VN': 'Vietnam',
    'ZA': 'South Africa',   'AU': 'Australia',
}

# Only return the small subset of browsers we whitelisted, this to avoid arbitrary growth
# in Graphite with low-sampled properties that are not useful
# (which has lots of other negative side effects too).
# Anything not in the whitelist should go into "Other" instead.


def parse_ua(ua):
    """Return a tuple of browser_family and browser_major, or None.

    Can parse a raw user agent or a json object alredy digested by ua-parser

    Inspired by https://github.com/ua-parser/uap-core

    - Add unit test with sample user agent string for each match.
    - Must return a string in form "<browser_family>.<browser_major>".
    - Use the same family name as ua-parser.
    - Ensure version number match doesn't contain dots (or transform them).

    """
    # trick, if app version is there this is a digested user agent
    m = re.search('wmf_app_version', ua)

    if m is not None:
        return parse_ua_obj(ua)
    else:
        return parse_ua_legacy(ua)


def parse_ua_obj(ua):
    """
    Parses user agent digested by ua-parser
    Note that only browser major is reported
    """
    ua_obj = json.loads(ua)

    browser_family = "Other"
    version = ua_obj['browser_major']

    # Chrome for iOS
    if ua_obj['browser_family'] == 'Chrome Mobile iOS' and ua_obj['os_family'] == 'iOS':
        browser_family = 'Chrome_Mobile_iOS'

    # Mobile Safari on iOS
    elif ua_obj['browser_family'] == 'Mobile Safari' and ua_obj['os_family'] == 'iOS':
        browser_family = 'Mobile_Safari'
        version = "{0}_{1}".format(ua_obj['browser_major'], ua_obj['browser_minor'])

    # iOS WebView
    elif ua_obj['os_family'] == 'iOS' and ua_obj['browser_family'] == 'Mobile Safari UIWebView':
        browser_family = 'iOS_WebView'

    # Opera >=14 for Android (WebKit-based)
    elif ua_obj['browser_family'] == 'Opera Mobile' and ua_obj['os_family'] == 'Android':
        browser_family = 'Opera_Mobile'

    # Android browser (pre Android 4.4)
    elif ua_obj['browser_family'] == 'Android' and ua_obj['os_family'] == 'Android':
        browser_family = 'Android'

    # Chrome for Android
    elif ua_obj['browser_family'] == 'Chrome Mobile' and ua_obj['os_family'] == 'Android':
        browser_family = 'Chrome_Mobile'

    # Opera >= 15 (Desktop)
    # todo assuming all operas not iOS or Android are desktop
    elif (ua_obj['browser_family'] == 'Opera' and int(ua_obj['browser_major']) >= 15
            and ua_obj['os_family'] != 'Android' and ua_obj['os_family'] != 'iOS'):
        browser_family = 'Opera'

    # Internet Explorer 11
    elif ua_obj['browser_family'] == 'IE' and ua_obj['browser_major'] == '11':
        browser_family = 'MSIE'

    # Internet Explorer <= 10
    elif ua_obj['browser_family'] == 'IE' and int(ua_obj['browser_major']) < 11:
        browser_family = 'MSIE'

    # Firefox for Android
    elif ua_obj['browser_family'] == 'Firefox Mobile' and ua_obj['os_family'] == 'Android':
        browser_family = 'Firefox_Mobile'

    # Firefox (Desktop)
    elif ua_obj['browser_family'] == 'Firefox':
        browser_family = 'Firefox'

    # Microsoft Edge (but note, not 'Edge Mobile')
    elif ua_obj['browser_family'] == 'Edge':
        browser_family = 'Edge'

    # Chrome/Chromium
    elif ua_obj['browser_family'] == 'Chrome' or ua_obj['browser_family'] == 'Chromium':
        browser_family = ua_obj['browser_family']

    # Safari (Desktop)
    elif ua_obj['browser_family'] == 'Safari' and ua_obj['os_family'] != 'iOS':
        browser_family = 'Safari'

    # Misc iOS
    elif ua_obj['os_family'] == 'iOS':
        browser_family = 'iOS_other'

    # Opera (Desktop)
    elif ua_obj['browser_family'] == 'Opera':
        browser_family = 'Opera'

    # 'Other' should report no version
    else:
        browser_family == 'Other'
        version = '_'

    return (browser_family, version)


def parse_ua_legacy(ua):
    """
    Parses raw user agent
    """

    # Chrome for iOS
    m = re.search('CriOS/(\d+)', ua)
    if m is not None:
        return ('Chrome_Mobile_iOS', m.group(1))

    # Mobile Safari on iOS
    m = re.search('OS [\d_]+ like Mac OS X.*Version/([\d.]+).+Safari', ua)
    if m is not None:
        return ('Mobile_Safari', '_'.join(m.group(1).split('.')[:2]))

    # iOS WebView
    m = re.search('OS ([\d_]+) like Mac OS X.*Mobile', ua)
    if m is not None:
        return ('iOS_WebView', '_'.join(m.group(1).split('_')[:2]))

    # Opera 14 for Android (WebKit-based)
    m = re.search('Mobile.*OPR/(\d+)', ua)
    if m is not None:
        return ('Opera_Mobile', m.group(1))

    # Android browser (pre Android 4.4)
    m = re.search('Android (\d).*Version/[\d.]+', ua)
    if m is not None:
        return ('Android', m.group(1))

    # Chrome for Android
    m = re.search('Android.*Chrome/(\d+)', ua)
    if m is not None:
        return ('Chrome_Mobile', m.group(1))

    # Opera >= 15 (Desktop)
    m = re.search('Chrome.*OPR/(\d+)', ua)
    if m is not None:
        return ('Opera', m.group(1))

    # Internet Explorer 11
    m = re.search('Trident.*rv:11\.', ua)
    if m is not None:
        return ('MSIE', '11')

    # Internet Explorer <= 10
    m = re.search('MSIE (\d+)', ua)
    if m is not None:
        return ('MSIE', m.group(1))

    # Firefox for Android
    m = re.search('(?:Mobile|Tablet);.*Firefox/(\d+)', ua)
    if m is not None:
        return ('Firefox_Mobile', m.group(1))

    # Firefox (Desktop)
    m = re.search('Firefox/(\d+)', ua)
    if m is not None:
        return ('Firefox', m.group(1))

    # Microsoft Edge
    m = re.search('Edge/(\d+)\.', ua)
    if m is not None:
        return ('Edge', m.group(1))

    # Chrome/Chromium
    m = re.search('(Chromium|Chrome)/(\d+)\.', ua)
    if m is not None:
        return (m.group(1), m.group(2))

    # Safari (Desktop)
    m = re.search('Version/(\d+).+Safari/', ua)
    if m is not None:
        return ('Safari', m.group(1))

    # Misc iOS
    m = re.search('OS ([\d_]+) like Mac OS X', ua)
    if m is not None:
        return ('iOS_other', '_'.join(m.group(1).split('_')[:2]))

    # Opera <= 12 (Desktop)
    m = re.match('Opera/9.+Version/(\d+)', ua)
    if m is not None:
        return ('Opera', m.group(1))

    # Opera < 10 (Desktop)
    m = re.match('Opera/(\d+)', ua)
    if m is not None:
        return ('Opera', m.group(1))

    return ('Other', '_')


def dispatch_stat(stat):
    sock.sendto(stat, addr)


def make_stat(*args):
    args = list(args)
    value = args.pop()
    name = '.'.join(arg.replace(' ', '_') for arg in args)
    stat = '%s:%s|ms' % (name, value)
    return stat.encode('utf-8')


def handles(schema):
    def wrapper(f):
        handlers[schema] = f
        return f
    return wrapper


def is_sane(value):
    return isinstance(value, int) and value > 0 and value < 180000


def is_sanev2(value):
    return isinstance(value, int) and value >= 0 and value < 180000


@handles('SaveTiming')
def handle_save_timing(meta):
    event = meta['event']
    duration = event.get('saveTiming')
    version = event.get('mediaWikiVersion')
    if duration is None:
        duration = event.get('duration')
    if duration and is_sane(duration):
        yield make_stat('mw.performance.save', duration)
        if version:
            yield make_stat('mw.performance.save_by_version',
                            version.replace('.', '_'), duration)


@handles('NavigationTiming')
def handle_navigation_timing(meta):
    event = meta['event']
    metrics = {}
    metrics_nav2 = {}
    isSane = True

    for metric in (
        'dnsLookup',
        'domComplete',
        'domInteractive',
        'fetchStart',
        'firstPaint',
        'loadEventEnd',
        'loadEventStart',
        'mediaWikiLoadComplete',
        'mediaWikiLoadEnd',
        'mediaWikiLoadStart',
        'redirecting',
        'responseStart',
    ):
        if metric in event:
            metrics[metric] = event[metric]

    for metric in (
        'domComplete',
        'domInteractive',
        'domContentLoaded',
        'firstPaint',
        'loadEventEnd'
    ):
        if metric in event:
            # The new way is to fetch start as base, so if we got it, rebase
            if 'fetchStart' in event:
                metrics_nav2[metric] = event[metric] - event['fetchStart']
            else:
                metrics_nav2[metric] = event[metric]

    for difference, minuend, subtrahend in (
        ('waiting', 'responseStart', 'requestStart'),
        ('connecting', 'connectEnd', 'connectStart'),
        ('receiving', 'responseEnd', 'responseStart'),
        ('rendering', 'loadEnd', 'responseEnd'),
        ('pageSpeed', 'loadEnd', 'domInteractive'),
        ('sslNegotiation', 'connectEnd', 'secureConnectionStart'),
    ):
        if minuend in event and subtrahend in event:
            metrics[difference] = event[minuend] - event[subtrahend]

    # https://www.w3.org/TR/navigation-timing/#process
    for difference, minuend, subtrahend in (
        # ('unload', 'unloadEventEnd', 'unloadEventStart'),
        ('redirect', 'redirectEnd', 'redirectStart'),
        ('appCache', 'domainLookupStart', 'fetchStart'),
        ('dns', 'domainLookupEnd', 'domainLookupStart'),
        ('tcp', 'connectEnd', 'connectStart'),
        ('request', 'responseStart', 'requestStart'),
        ('response', 'responsetEnd', 'responseStart'),
        ('processing', 'domComplete', 'domLoading'),
        ('onLoad', 'loadEventEnd', 'loadEventStart'),
        ('mediaWikiLoad', 'mediaWikiLoadEnd', 'mediaWikiLoadStart'),
        ('ssl', 'connectEnd', 'secureConnectionStart'),
    ):
        if minuend in event and subtrahend in event:
            metrics_nav2[difference] = event[minuend] - event[subtrahend]

    if 'mobileMode' in event:
        if event['mobileMode'] == 'stable':
            site = 'mobile'
        else:
            site = 'mobile-beta'
    else:
        site = 'desktop'
    auth = 'anonymous' if event.get('isAnon') else 'authenticated'

    country_code = event.get('originCountry')
    continent = iso_3166_countries.get(country_code)
    country_name = iso_3166_top_40_plus_australia.get(country_code)

    if 'sslNegotiation' in metrics:
        metrics = {'sslNegotiation': metrics['sslNegotiation']}

    for metric, value in metrics.items():
        prefix = 'frontend.navtiming'

        if is_sane(value):
            yield make_stat(prefix, metric, site, auth, value)
            yield make_stat(prefix, metric, site, 'overall', value)
            yield make_stat(prefix, metric, 'overall', value)

            ua = parse_ua(meta['userAgent']) or ('Other', '_')
            yield make_stat(prefix, metric, 'by_browser', ua[0], ua[1], value)
            yield make_stat(prefix, metric, 'by_browser', ua[0], 'all', value)

        if continent is not None:
            yield make_stat(prefix, metric, 'by_continent', continent, value)

        if country_name is not None:
            yield make_stat(prefix, metric, 'by_country', country_name, value)

    # If one of the metrics are wrong, don't send them at all
    for metric, value in metrics_nav2.items():
        isSane = is_sanev2(value)
        if not isSane:
            break

    # If one of the metrics are over the max then skip it entirely
    if (isSane):
        for metric, value in metrics_nav2.items():
            prefix = 'frontend.navtiming2'
            yield make_stat(prefix, metric, site, auth, value)
            yield make_stat(prefix, metric, site, 'overall', value)
            yield make_stat(prefix, metric, 'overall', value)

            yield make_stat(prefix, metric, 'by_browser', ua[0], ua[1], value)
            yield make_stat(prefix, metric, 'by_browser', ua[0], 'all', value)

            if continent is not None:
                yield make_stat(prefix, metric, 'by_continent', continent, value)

            if country_name is not None:
                yield make_stat(prefix, metric, 'by_country', country_name, value)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='NavigationTiming subscriber')
    ap.add_argument('--brokers', required=True,
                    help='Comma-separated list of kafka brokers')
    ap.add_argument('--consumer-group', required=True,
                    help='Consumer group to register with Kafka')
    ap.add_argument('--statsd-host', default='localhost',
                    type=socket.gethostbyname)
    ap.add_argument('--statsd-port', default=8125, type=int)
    args = ap.parse_args()

    logging.basicConfig(format='%(asctime)-15s %(message)s',
                        level=logging.INFO, stream=sys.stdout)

    addr = args.statsd_host, args.statsd_port
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    kafka_bootstrap_servers = tuple(args.brokers.split(','))
    kafka_topics = ('eventlogging_' + key for key in handlers.keys())
    kafka_consumer_timeout_seconds = 60
    consumer = KafkaConsumer(
        *kafka_topics,
        bootstrap_servers=kafka_bootstrap_servers,
        group_id=args.consumer_group,
        auto_offset_reset='latest',
        enable_auto_commit=False,
        consumer_timeout_ms=kafka_consumer_timeout_seconds * 1000
    )

    logging.info('Starting statsv Kafka consumer.')
    try:
        for message in consumer:
            meta = json.loads(message.value)
            if 'schema' in meta:
                f = handlers.get(meta['schema'])
                if f is not None:
                    for stat in f(meta):
                        dispatch_stat(stat)
        # If we reach this line, consumer_timeout_ms elapsed without events
        raise RuntimeError('No messages received in %d seconds.' % kafka_consumer_timeout_seconds)
    finally:
        consumer.close()


# ##### Tests ######
# To run:
#   python -m unittest -v navtiming
#
class TestNavTiming(unittest.TestCase):
    def test_parse_ua(self):
        with open('navtiming_ua_data.yaml') as file:
            data = yaml.safe_load(file)
            for case in data:
                expect = tuple(case.split('.'))
                uas = data.get(case)
                for ua in uas:
                    self.assertEqual(
                        parse_ua(ua),
                        expect
                    )

    def test_handlers(self):
        with open('navtiming_fixture.yaml') as fixture_file:
            fixture = yaml.safe_load(fixture_file)
            actual = []
            for meta in fixture:
                f = handlers.get(meta['schema'])
                assert f is not None
                for stat in f(meta):
                    actual.append(stat)
            with open('navtiming_expected.txt') as expected_file:
                expect = expected_file.read().splitlines()
                self.assertItemsEqual(
                    actual,
                    expect
                )
