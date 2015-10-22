#!/usr/bin/env python
import urllib
import argparse
import sys

APP_VERSION = 0.1
PROTOCOL_VERSION = 3.1
GSB_URL = 'https://sb-ssl.google.com/safebrowsing/api/lookup'
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def check_url(url, client_id, api_key):
    t = urllib.urlopen(
        '%s?client=%s&key=%s&appver=%s&pver=%s&url=%s' %
        (GSB_URL, client_id, api_key, APP_VERSION, PROTOCOL_VERSION, url))
    status = t.getcode()
    if status == 200:
        return (CRITICAL, '%s marked as %s' % (url, t.read()))
    elif status == 204:
        return (OK, '%s is OK' % url)
    else:
        return (UNKNOWN, 'Status: %s' % status)


def handle_args():
    parser = argparse.ArgumentParser(
        description='Google Safebrowsing Lookup API client')
    parser.add_argument('-v',
                        '--version',
                        action='version',
                        version='%s' % APP_VERSION)
    parser.add_argument(
        'client_id',
        help='Client ID as specified by developers console',
        action='store')
    parser.add_argument(
        'api_key',
        help='API key as specified by developers console',
        action='store')
    parser.add_argument(
        'url',
        help='url to check',
        action='store')
    args = parser.parse_args()
    return vars(args)


def main():
    args = handle_args()
    url = args['url']
    client_id = args['client_id']
    api_key = args['api_key']
    state, text = check_url(url, client_id, api_key)
    print text
    sys.exit(state)


if __name__ == '__main__':
    main()
