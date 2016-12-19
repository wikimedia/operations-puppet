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

from netaddr import IPNetwork, IPAddress

from oslo_log import log
from oslo_config import cfg

from keystone.auth import plugins as auth_plugins
from keystone.auth.plugins import password
from keystone import exception
from keystone.i18n import _

METHOD_NAME = 'password'

LOG = log.getLogger(__name__)

whitelist_ops = [
    cfg.MultiStrOpt('password_whitelist',
                    default=[],
                    help='user:ip range permitted to use password auth.'
                         'also supports a simple one-character * wildcard'
                         'for user.'),
]

CONF = cfg.CONF
CONF.register_opts(whitelist_ops, group='auth')


def check_whitelist(user_id, remote_addr):
    """Return True if the user_id/remote_addr combination is in our whitelist.
       Otherwise, return raise Unauthorized"""
    LOG.debug("Auth request for user %s from %s" % (user_id,
                                                    remote_addr))

    for entry in CONF.auth.password_whitelist:
        user, subnet = entry.split(':', 1)
        if user == "*" or user_id == user:
            if IPAddress(remote_addr) in IPNetwork(subnet):
                return True

    LOG.warn('Password auth not allowed for %s from %s' % (user_id,
                                                           remote_addr))

    msg = _('Password auth not allowed for this username from this ip.')
    raise exception.Unauthorized(msg)


class PasswordWhitelist(password.Password):

    def authenticate(self, context, auth_payload, auth_context):
        """Verify username and password but only allow access for configured
           accounts and from configured IP ranges."""

        user_info = auth_plugins.UserAuthInfo.create(auth_payload, METHOD_NAME)
        check_whitelist(user_info.user_id,
                        context['environment']['REMOTE_ADDR'])

        return super(PasswordWhitelist, self).authenticate(context,
                                                           auth_payload,
                                                           auth_context)
