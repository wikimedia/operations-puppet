#!/usr/bin/python
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

from __future__ import print_function

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
    req = requests.get(url, params=query, headers=headers)
    req.raise_for_status()
    return req.json()


# Fetch the latest stable version number from mediawiki.org's
# [[Template:MW stable release number]] in a format that will match siteinfo
# output.
try:
    stable = mwapi(
        'www.mediawiki.org',
        action='expandtemplates', prop='wikitext',
        text='MediaWiki {{MW stable release number}}',
    )['expandtemplates']['wikitext']
except Exception:
    icinga_exit(
        UNKNOWN,
        'Failed to fetch latest MediaWiki version from mediawiki.org')

# Fetch the current version from the target wiki.
try:
    version = mwapi(
        TARGET,
        action='query', meta='siteinfo', siprop='general',
    )['query']['general']['generator']
except Exception:
    icinga_exit(
        UNKNOWN, 'Failed to fetch MediaWiki version for {}', TARGET)

if version == stable:
    icinga_exit(OK, '{} is running {}', TARGET, stable)
else:
    icinga_exit(
        WARNING, '{} is running {}, latest is {} '
                 'Consult https://wikitech.wikimedia.org/wiki/Wikitech-static '
                 'for details.', TARGET, version, stable)
