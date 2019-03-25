#!/usr/bin/python3
# check the last modified header of a website (T203208)
# Daniel Zahn (<dzahn@wikimedia.org>)

"""Check the last modified header of a website,
convert it to UNIX epoch, compare to local time
and alert if it's too old."""

import sys
import argparse
from time import time, mktime, strptime
import requests
from rfc3986 import is_valid_uri


def handle_args():
    """Handle command line arguments"""
    parser = argparse.ArgumentParser(
        description='Check website for recent content updates')
    parser.add_argument(
        '-u', '--url',
        required=True,
        type=valid_url,
        help='Full URL, incl. protocol, to check for last-modified header',)
    parser.add_argument(
        '-w', '--warn',
        required=True,
        type=positive_int,
        help='Maximum age in hours before a WARN is triggered',)
    parser.add_argument(
        '-c', '--crit',
        required=True,
        type=positive_int,
        help='Maximum age in hours before a CRIT is triggered',)
    args = parser.parse_args()
    return vars(args)


def positive_int(string):
    value = int(string)
    if value <= 0:
        msg = "%r is not a positive integer" % int
        raise argparse.ArgumentTypeError(msg)
    return value


def valid_url(string):
    if not is_valid_uri(string):
        msg = "%r is not a valid URI" % int
        raise argparse.ArgumentTypeError(msg)
    return string


def main():
    """Check the last modified header of a website,
    convert it to UNIX epoch, compare to local time
    and alert if it's too old"""

    args = handle_args()

    check_url = args['url']

    max_age_hours_warn = int(args['warn'])
    max_age_hours_crit = int(args['crit'])

    max_age_secs_warn = int((max_age_hours_warn * 24 * 60))
    max_age_secs_crit = int((max_age_hours_crit * 24 * 60))

    if max_age_secs_warn >= max_age_secs_crit:
        msg = "threshold for CRIT must be equal or \
               larger than threshold for WARN"
        raise argparse.ArgumentTypeError(msg)

    try:
        req = requests.get(check_url)
        req.raise_for_status()
        last_modified_string = req.headers['Last-Modified']
    except requests.exceptions.RequestException as e:
        print('CRITICAL - exception while fetching the URL. ' + str(e))
        sys.exit(2)

    last_modified_epoch = mktime(strptime(last_modified_string,
                                          "%a, %d %b %Y %H:%M:%S GMT"))

    remote_ts = (int(last_modified_epoch))
    local_ts = int(time())
    diff_ts = (local_ts - remote_ts)

    if diff_ts > max_age_secs_crit:
        print('CRITICAL - Content not updated recently ({diff} > {crit})'.
              format(crit=max_age_secs_crit, diff=diff_ts))
        sys.exit(2)
    elif diff_ts > max_age_secs_warn:
        print('WARNING - Content not updated recently ({diff} > {warn})'.
              format(warn=max_age_secs_warn, diff=diff_ts))
        sys.exit(1)
    elif diff_ts <= max_age_secs_warn:
        print('OK - Website content is current ({diff} <= {warn})'.
              format(warn=max_age_secs_warn, diff=diff_ts))
        sys.exit(0)


if __name__ == "__main__":
    main()
