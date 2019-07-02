#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Check the MediaWiki version of wikitech-static.wikimedia.org against the
# latest stable release as reported by mediawiki.org.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# http://www.gnu.org/copyleft/gpl.html
"""Icinga check to ensure wikietech static is running the correct version"""

import os
import sys

import requests


TARGET = 'wikitech-static.wikimedia.org'

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

STATES = {
    OK: 'OK',
    WARNING: 'WARNING',
    CRITICAL: 'CRITICAL',
    UNKNOWN: 'UNKNOWN',
}


def icinga_exit(state, message, *args, **kwargs):
    """Print status message and exit."""
    print('MWVERSION {} - {}'.format(
        STATES[state],
        message.format(*args, **kwargs)
    ))
    sys.exit(state)


def mwapi(server, **kwargs):
    """Make a MediaWiki Action API call and return the result."""
    url = 'https://{}/w/api.php'.format(server)
    query = {'format': 'json', 'formatversion': '2'}
    query.update(kwargs)
    headers = requests.utils.default_headers()
    headers['User-agent'] = 'wmf-icinga/{} (root@wikimedia.org)'.format(os.path.basename(__file__))
    try:
        req = requests.get(url, params=query, headers=headers)
        req.raise_for_status()
    except requests.exceptions.HTTPError as error:
        msg = 'Failed to fetch json from {}: {}'.format(server, error)
        icinga_exit(UNKNOWN, msg)
    return req.json()


def main():
    """Main entry point"""
    # Fetch the latest stable version number from mediawiki.org's
    # [[Template:MW stable release number]] in a format that will match siteinfo
    # output.
    mediawiki_data = mwapi(
        'www.mediawiki.org',
        action='expandtemplates', prop='wikitext',
        text='MediaWiki {{MW stable release number}}',
    )
    stable_version = mediawiki_data.get('expandtemplates', {}).get('wikitext', None)
    target_data = mwapi(TARGET, action='query', meta='siteinfo', siprop='general')
    target_version = target_data.get('query', {}).get('general', {}).get('generator', None)

    if stable_version is None:
        icinga_exit(UNKNOWN, 'Unable to fetch version number from www.mediawiki.org')
    if target_version is None:
        icinga_exit(UNKNOWN, 'Unable to fetch version number from {}'.format(TARGET))

    if target_version == stable_version:
        icinga_exit(OK, '{} is running {}', TARGET, stable_version)
    else:
        icinga_exit(
            WARNING,
            '{} is running {}, latest is {} '
            'Consult https://wikitech.wikimedia.org/wiki/Wikitech-static '
            'for details.', TARGET, target_version, stable_version)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        icinga_exit(UNKNOWN, 'An unknown error occurred: {}'.format(error))
