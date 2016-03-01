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

import logging

from keystoneclient.auth.identity import v2 as v2_auth
from keystoneclient.auth.identity import v3 as v3_auth

from openstack_auth.plugin import base
from openstack_auth import utils

LOG = logging.getLogger(__name__)

__all__ = ['WmtotpPlugin']


class WmtotpPlugin(base.BasePlugin):
    """Authenticate against keystone given a username, password, totp token.
    """

    def get_plugin(self, auth_url=None, username=None, password=None,
                   user_domain_name=None, totp=None, **kwargs):
        if not all((auth_url, username, password, totp)):
            return None

        LOG.debug('Attempting to authenticate for %s', username)

        if utils.get_keystone_version() >= 3:
            return v3_auth.Wmtotp(auth_url=auth_url,
                                  username=username,
                                  password=password,
                                  totp=totp,
                                  user_domain_name=user_domain_name,
                                  unscoped=True)

        else:
            msg = "Totp authentication requires the keystone v3 api."
            raise exceptions.KeystoneAuthException(msg)
