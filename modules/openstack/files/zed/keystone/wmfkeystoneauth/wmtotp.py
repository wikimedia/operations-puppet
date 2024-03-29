# SPDX-License-Identifier: Apache-2.0

# Copyright 2016 Wikimedia Foundation
#
#  (this is a custom hack local to the Wikimedia Labs deployment)
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

import flask

from oslo_log import log
from oslo_config import cfg

from keystone.auth.plugins import base
from keystone.auth import plugins as auth_plugins
from . import password_safelist
from keystone.common import provider_api
from keystone import exception
from keystone.i18n import _

from . import wikitechclient

METHOD_NAME = 'wmtotp'
PROVIDERS = provider_api.ProviderAPIs

LOG = log.getLogger(__name__)
CONF = cfg.CONF

oathoptions = [
    cfg.StrOpt('dbuser',
               default='wiki_user',
               help='Database user for retrieving OATH secret.'),
    cfg.StrOpt('dbpass',
               default='12345',
               help='Database password for retrieving OATH secret.'),
    cfg.StrOpt('dbhost',
               default='localhost',
               help='Database host for retrieving OATH secret.'),
    cfg.StrOpt('dbname',
               default='labswiki',
               help='Database name for retrieving OATH secret.'),
    cfg.StrOpt('wikitech_host',
               default='wikitech.wikimedia.org',
               help='fqdn for the mediawiki host that supports the oath api'),
    cfg.StrOpt('wikitech_consumer_token'),
    cfg.StrOpt('wikitech_consumer_secret'),
    cfg.StrOpt('wikitech_access_token'),
    cfg.StrOpt('wikitech_access_secret'),
]

for option in oathoptions:
    CONF.register_opt(option, group='oath')


class Wmtotp(base.AuthMethodHandler):

    method = METHOD_NAME

    def authenticate(self, auth_payload):
        """Try to authenticate against the identity backend."""
        response_data = {}
        user_info = auth_plugins.UserAuthInfo.create(auth_payload, self.method)

        # Before we do anything else, make sure that this user is allowed
        #  access from their source IP
        password_safelist.check_safelist(user_info.user_id,
                                         flask.request.environ.get('REMOTE_ADDR'),
                                         user_info.domain_id)

        try:
            PROVIDERS.identity_api.authenticate(
                user_id=user_info.user_id,
                password=user_info.password)
        except AssertionError:
            # authentication failed because of invalid username or password
            msg = _('Invalid username or password')
            raise exception.Unauthorized(msg)

        # Password auth succeeded, check two-factor
        # LOG.debug("OATH: Doing 2FA for user_info " +
        #     ( "%s(%r)" % (user_info.__class__, user_info.__dict__) ) )
        # LOG.debug("OATH: Doing 2FA for auth_payload " +
        #     ( "%s(%r)" % (auth_payload.__class__, auth_payload) ) )
        if 'totp' not in auth_payload['user']:
            LOG.debug("OATH: 2FA failed, missing totp param")
            msg = _('Missing two-factor token')
            raise exception.Unauthorized(msg)

        wtclient = wikitechclient.WikitechClient(
            CONF.oath.wikitech_host,
            CONF.oath.wikitech_consumer_token,
            CONF.oath.wikitech_consumer_secret,
            CONF.oath.wikitech_access_token,
            CONF.oath.wikitech_access_secret)
        valid = wtclient.oathvalidate(user_info.user_ref['name'],
                                      auth_payload['user']['totp'])

        if valid['enabled']:
            if valid['valid']:
                LOG.debug("OATH: 2FA passed")
            else:
                LOG.debug("OATH: 2FA failed")
                msg = _('Invalid two-factor token')
                raise exception.Unauthorized(msg)
        else:
            LOG.debug("OATH: user '%s' does not have 2FA enabled.",
                      user_info.user_ref['name'])
            msg = _('2FA is not enabled; login forbidden')
            raise exception.Unauthorized(msg)

        response_data['user_id'] = user_info.user_id

        return base.AuthHandlerResponse(status=True, response_body=None,
                                        response_data=response_data)
