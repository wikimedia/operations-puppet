# Copyright 2016 Wikimedia Foundation
#
#  This is part of a custom Keystone auth extension specific to Wikimedia Labs.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import mwclient

from oslo_log import log

LOG = log.getLogger(__name__)


class WikitechClient(object):
    """MediaWiki client, used for checking oath creds against Wikitech"""

    def __init__(
        self, host,
        consumer_token, consumer_secret,
        access_token, access_secret
    ):
        self.site = self._site_for_host(
            host, consumer_token,
            consumer_secret, access_token, access_secret)

    @classmethod
    def _site_for_host(
        cls, host,
        consumer_token, consumer_secret,
        access_token, access_secret
    ):
        return mwclient.Site(
            host,
            consumer_token=consumer_token,
            consumer_secret=consumer_secret,
            access_token=access_token,
            access_secret=access_secret,
            clients_useragent='Keystone',
            force_login=True
        )

    # Returns a dict with two members:  'valid' and 'enabled'.
    def oathvalidate(self, username, totp):
        token = self.site.get_token('csrf', force=True)
        result = self.site.api(
            'oathvalidate', formatversion=2,
            user=username,
            totp=totp,
            token=token
        )
        return result['oathvalidate']
