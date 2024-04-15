# SPDX-License-Identifier: Apache-2.0
#
# Copyright 2016 Andrew Bogott for the Wikimedia Foundation
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
from netaddr import IPNetwork, IPAddress

from oslo_log import log
from oslo_config import cfg

from keystone.auth import plugins as auth_plugins
from keystone.auth.plugins import password
from keystone import exception
from keystone.i18n import _

METHOD_NAME = 'password'

LOG = log.getLogger(__name__)

safelist_ops = [
    cfg.MultiStrOpt('password_safelist',
                    default=[],
                    help='user:ip range permitted to use password auth.'
                         'also supports a simple one-character * wildcard'
                         'for user.'),
    cfg.ListOpt('password_restricted_domains',
                default=['default'],
                help='list of domain ids on which to restrict password '
                     'access. Typically we restrict password access on '
                     'the default domain but permit access in service '
                     'domains (e.g. Heat) for VM-managed orchestration.'),
]

CONF = cfg.CONF
CONF.register_opts(safelist_ops, group='auth')


def check_safelist(user_id, remote_addr, domain_id):
    """Return True if the user_id/remote_addr combination is in our safelist.
       Otherwise, return raise Unauthorized"""
    LOG.debug("Auth request for user %s from %s in domain %s" % (user_id,
                                                                 remote_addr,
                                                                 domain_id))

    if domain_id not in CONF.auth.password_restricted_domains:
        LOG.debug('Password auth permitted on unrestricted domain %s' % domain_id)
        return True

    for entry in CONF.auth.password_safelist:
        user, subnet = entry.split(':', 1)
        if user == "*" or user_id == user:
            if IPAddress(remote_addr) in IPNetwork(subnet):
                LOG.debug('Password auth found in safelist.')
                return True

    LOG.warn('Password auth not allowed for %s from %s' % (user_id,
                                                           remote_addr))

    msg = _('Password auth not allowed for this username from this ip.')
    raise exception.Unauthorized(msg)


class PasswordSafelist(password.Password):

    def authenticate(self, auth_payload):
        """Verify username and password but only allow access for configured
           accounts and from configured IP ranges."""

        user_info = auth_plugins.UserAuthInfo.create(auth_payload, METHOD_NAME)
        check_safelist(user_info.user_id,
                       flask.request.environ.get('REMOTE_ADDR'),
                       user_info.domain_id)

        return super(PasswordSafelist, self).authenticate(auth_payload)
