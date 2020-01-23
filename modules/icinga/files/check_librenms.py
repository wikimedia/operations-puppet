#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (c) 2020 Wikimedia Foundation
# Copyright (c) 2020 Chris Danis <cdanis@wikimedia.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Translates critical LibreNMS alerts into Icinga critical alerts.

Run this as an Icinga custom check command, and it will poll the LibreNMS API for
all critical alerts whose defining alert rule matches a given pattern (e.g. "#page").
Those alerts will become Icinga CRITICALs that can be used to generate notifications,
with nicely-formatted output that breaks down which alerts and devices are the source of
the trouble.
"""

import argparse
from collections import defaultdict
from functools import lru_cache
from enum import IntEnum
import logging
import re
import requests
import sys
import os
from urllib.parse import urljoin
from typing import Any, Dict, Tuple, Pattern


log = logging.getLogger(os.path.basename(__file__))


class NagiosExitCode(IntEnum):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3


class LibreNMSException(Exception):
    pass


class LibreNMS(object):
    def __init__(self, *, base_url: str, escalation_pattern: Pattern[str],
                 api_key: str, retries: int = 2):
        self.query_url = urljoin(base_url, '/api/v0/')
        self.escalation_pattern = escalation_pattern
        self.session = requests.Session()
        self.session.mount(base_url, requests.adapters.HTTPAdapter(max_retries=retries))
        self.session.headers.update({
            'User-Agent': 'wmf-icinga/{} (root@wikimedia.org)'.format(os.path.basename(__file__)),
            'X-Auth-Token': api_key})

    def _run_query(self, endpoint: str) -> Dict[str, Any]:
        """
        Executes a query against the LibreNMS API and returns the JSON response as a dict.
        The useful part of the return value will be in a sub-dictionary whose name depends upon
        the endpoint used (e.g. the 'rules' endpoint will have a 'rules' sub-dictionary).
        Check API docs to be sure. https://docs.librenms.org/API/ """
        url = urljoin(self.query_url, endpoint)
        r = self.session.get(url)
        log.debug('Fetch of "%s" returned HTTP status %s (%s bytes)',
                  url, r.status_code, len(r.content))
        r.raise_for_status()
        j = r.json()
        log.debug('Fetch of "%s" returned LibreNMS API status "%s"', url, j['status'])
        if j['status'] != 'ok':
            raise LibreNMSException('LibreNMS did not return status "ok"', j['status'])
        return j

    @lru_cache()
    def device_name(self, device_id: int) -> str:
        """Given a device ID, returns its hostname."""
        j = self._run_query('devices/' + str(device_id))
        if len(j['devices']) != 1:
            raise LibreNMSException('LibreNMS API returned multiple devices',
                                    device_id, j['devices'])
        d = j['devices'][0]
        if d['device_id'] != device_id:
            raise LibreNMSException('LibreNMS API returned data for a different device_id',
                                    device_id, d)
        return d['hostname']

    def check_alerts(self) -> Tuple[NagiosExitCode, str]:
        """Polls LibreNMS API and returns an Icinga-compatible result."""
        # Fetch the list of any actively-firing critical alerts.
        # LibreNMS alerts are basically a (alert_rule_id, device_id) pair; later we'll need to
        # fetch the list of rules to get a meaningful name for the alert.
        critical_alerts = self._run_query('alerts?state=1&severity=critical')['alerts']
        # We also select only alerts that set alerted=1, indicating their configured
        # delay interval has passed, they aren't just a blip, and that LibreNMS has sent email/IRC.
        # TODO: the presence of these that match escalation_pattern maybe should be a WARNING?
        critical_alerts = [a for a in critical_alerts if a['alerted']]

        if not critical_alerts:
            return (NagiosExitCode.OK, 'OK: zero critical LibreNMS alerts')

        # Get a list of all the alert rules, which are templates that define proto-alerts
        all_alert_rules = self._run_query('rules')['rules']
        # We only care about just the ones that have our magic pattern (e.g. #page) in their name.
        # Alerts refer to rules by numeric ID; build a lookup hash.
        paging_rules = {r['id']: r for r in all_alert_rules
                        if self.escalation_pattern.search(r['name'])}

        critical_paging_alerts = [a for a in critical_alerts if a['rule_id'] in paging_rules]

        if not critical_paging_alerts:
            return (NagiosExitCode.OK,
                    'OK: no critical LibreNMS alerts matching {}'.format(self.escalation_pattern))

        # OK, so we have some critical, page-worthy alerts.  Let's generate friendly output.
        # TODO: Although AFAICT it doesn't seem possible via the API, it would be nice to include
        # port names in addition to device names.  (Ports do appear in LibreNMS's emails.)

        # We group output like: <Alert name>: (list of devices) [// <Alert name>: ...]
        # Example output lines:
        # CRITICAL: Primary inbound port utilisation over 80% (cr3-esams.wikimedia.org)
        # CRITICAL: Primary outbound port utilisation over 80% (cr3-esams.wikimedia.org,cr2-eqsin.wikimedia.org)    # noqa
        # CRITICAL: Primary inbound port utilisation over 80% (cr3-esams.wikimedia.org) // Primary outbound port utilisation over 80% (cr3-esams.wikimedia.org)    # noqa
        # CRITICAL: Primary inbound port utilisation over 80% (cr3-esams.wikimedia.org) // Primary outbound port utilisation over 80% (cr3-esams.wikimedia.org,cr2-eqsin.wikimedia.org)    # noqa

        try:
            # To do this, make a dict mapping active alert rules to a list of device names...
            devices_by_alert = defaultdict(list)
            for a in critical_paging_alerts:
                devices_by_alert[a['rule_id']].append(self.device_name(a['device_id']))
            # ... and then smush that all together with an inner and an outer .join().
            formatted_alerts = ['{} ({})'.format(paging_rules[rule_id]['name'], ','.join(devs))
                                for rule_id, devs in devices_by_alert.items()]
            status = ' // '.join(formatted_alerts)
            return (NagiosExitCode.CRITICAL, status)
        except Exception as e:
            log.exception('Exception %s while building output string', repr(e))
            return (NagiosExitCode.CRITICAL,
                    ('LibreNMS paging criticals detected! '
                     '(but exception {} while building output string)').format(repr(e)))


def main():
    parser = argparse.ArgumentParser(
        description='Scrape the LibreNMS API and generate Icinga alerts.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='https://librenms.wikimedia.org/',
                        help='LibreNMS server base URL')
    parser.add_argument('--escalation-pattern', default='(?i)#page',
                        type=re.compile, metavar='REGEX',
                        help=('A regex to match against LibreNMS rule names.  '
                              'Matching rules will generate an icinga CRITICAL.'))
    parser.add_argument('--debug', action='store_true', default=False,
                        help='Enable debug output')
    parser.add_argument('--api-key-file', type=argparse.FileType('r'), required=True,
                        help=('Path to a file containing an API key for LibreNMS. '
                              'Required.'))
    options = parser.parse_args()

    log_level = logging.INFO
    if options.debug:
        log_level = logging.DEBUG
    logging.basicConfig(level=log_level)
    logging.getLogger('requests.packages.urllib3').setLevel(
        logging.DEBUG if options.debug else logging.WARNING)
    logging.getLogger('urllib3.connectionpool').setLevel(
        logging.DEBUG if options.debug else logging.WARNING)

    librenms = LibreNMS(base_url=options.url, escalation_pattern=options.escalation_pattern,
                        api_key=options.api_key_file.read().strip())
    # No matter what happens, we want to generate a return value that's meaningful to Icinga.
    try:
        status, text = librenms.check_alerts()
    except Exception as e:
        log.exception('Encountered exception %s during execution', repr(e))
        status, text = (NagiosExitCode.UNKNOWN, 'Execution failed; encountered {}'.format(repr(e)))

    print(text)
    log.debug('Exiting with code %s', status)
    return status


if __name__ == '__main__':
    sys.exit(main())
