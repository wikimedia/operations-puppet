#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import logging
import re
import socket
import unittest

import eventlogging
import yaml


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


def parse_ua(ua):
    """Return a tuple of browser_family and browser_major, or None.

    Inspired by https://github.com/ua-parser/uap-core

    - Add unit test with sample user agent string for each match.
    - Must return a string in form "<browser_family>.<browser_major>".
    - Use the same family name as ua-parser.
    - Ensure version number match doesn't contain dots (or transform them).
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


def dispatch_stat(*args):
    args = list(args)
    value = args.pop()
    name = '.'.join(arg.replace(' ', '_') for arg in args)
    stat = '%s:%s|ms' % (name, value)
    sock.sendto(stat.encode('utf-8'), addr)


def handles(schema):
    def wrapper(f):
        handlers[schema] = f
        return f
    return wrapper


def is_sane(value):
    return isinstance(value, int) and value > 0 and value < 180000


@handles('SaveTiming')
def handle_save_timing(meta):
    event = meta['event']
    duration = event.get('saveTiming')
    version = event.get('mediaWikiVersion')
    if duration is None:
        duration = event.get('duration')
    if duration and is_sane(duration):
        dispatch_stat('mw.performance.save', duration)
        if version:
            dispatch_stat('mw.performance.save_by_version',
                          version.replace('.', '_'), duration)


@handles('NavigationTiming')
def handle_navigation_timing(meta):
    event = meta['event']
    metrics = {}

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
            dispatch_stat(prefix, metric, site, auth, value)
            dispatch_stat(prefix, metric, site, 'overall', value)
            dispatch_stat(prefix, metric, 'overall', value)

            ua = parse_ua(meta['userAgent']) or ('Other', '_')
            dispatch_stat(prefix, metric, 'by_browser', ua[0], ua[1], value)
            dispatch_stat(prefix, metric, 'by_browser', ua[0], 'all', value)

        if continent is not None:
            dispatch_stat(prefix, metric, 'by_continent', continent, value)

        if country_name is not None:
            dispatch_stat(prefix, metric, 'by_country', country_name, value)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='NavigationTiming subscriber')
    ap.add_argument('endpoint', help='URI of EventLogging endpoint')
    ap.add_argument('--statsd-host', default='localhost',
                    type=socket.gethostbyname)
    ap.add_argument('--statsd-port', default=8125, type=int)
    args = ap.parse_args()

    logging.basicConfig(format='%(asctime)-15s %(message)s',
                        level=logging.INFO, stream=sys.stdout)

    addr = args.statsd_host, args.statsd_port
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    events = eventlogging.connect(args.endpoint)

    for meta in events:
        f = handlers.get(meta['schema'])
        if f is not None:
            f(meta)


# ##### Tests ######
# To run:
#   python -m unittest navtiming
#
class TestParseUa(unittest.TestCase):

    def test_parse_ua(self):
        with open('navtiming_ua_data.yaml') as f:
            data = yaml.safe_load(f)
            for case in data:
                if case['result']:
                    expect = tuple(case['result'].split('.'))
                else:
                    expect = None
                self.assertEqual(
                    parse_ua(case['ua']),
                    expect
                )
