#
#  Custom addition for Wikimedia Labs to add a totp plugin to keystoneclient
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

import sys

from oslo_config import cfg

from keystoneclient.auth.identity.v3 import base
from keystoneclient import utils

__all__ = ['WmtotpMethod', 'Wmtotp']


class WmtotpMethod(base.AuthMethod):
    """Construct a User/Password/totp based authentication method.

    :param string password: Password for authentication.
    :param string totp: 2FA (TOTP) token for authentication.
    :param string username: Username for authentication.
    :param string user_id: User ID for authentication.
    :param string user_domain_id: User's domain ID for authentication.
    :param string user_domain_name: User's domain name for authentication.
    """

    _method_parameters = ['user_id',
                          'username',
                          'user_domain_id',
                          'user_domain_name',
                          'password',
                          'totp']

    def get_auth_data(self, session, auth, headers, **kwargs):
        user = {'password': self.password, 'totp': self.totp}

        if self.user_id:
            user['id'] = self.user_id
        elif self.username:
            user['name'] = self.username

            if self.user_domain_id:
                user['domain'] = {'id': self.user_domain_id}
            elif self.user_domain_name:
                user['domain'] = {'name': self.user_domain_name}

        return 'wmtotp', {'user': user}


class Wmtotp(base.AuthConstructor):
    """A plugin for authenticating with a username, password, totp token

    :param string auth_url: Identity service endpoint for authentication.
    :param string password: Password for authentication.
    :param string totp: totp token for authentication
    :param string username: Username for authentication.
    :param string user_id: User ID for authentication.
    :param string user_domain_id: User's domain ID for authentication.
    :param string user_domain_name: User's domain name for authentication.
    :param string trust_id: Trust ID for trust scoping.
    :param string domain_id: Domain ID for domain scoping.
    :param string domain_name: Domain name for domain scoping.
    :param string project_id: Project ID for project scoping.
    :param string project_name: Project name for project scoping.
    :param string project_domain_id: Project's domain ID for project.
    :param string project_domain_name: Project's domain name for project.
    :param bool reauthenticate: Allow fetching a new token if the current one
                                is going to expire. (optional) default True
    """

    _auth_method_class = WmtotpMethod

    @classmethod
    def get_options(cls):
        options = super(Wmtotp, cls).get_options()

        options.extend([
            cfg.StrOpt('user-id', help='User ID'),
            cfg.StrOpt('user-name', dest='username', help='Username',
                       deprecated_name='username'),
            cfg.StrOpt('user-domain-id', help="User's domain id"),
            cfg.StrOpt('user-domain-name', help="User's domain name"),
            cfg.StrOpt('password', secret=True, help="User's password"),
            cfg.StrOpt('totp', secret=True, help="2FA (TOTP) token"),
        ])

        return options

    @classmethod
    def load_from_argparse_arguments(cls, namespace, **kwargs):
        if not (kwargs.get('password') or namespace.os_password):
            kwargs['password'] = utils.prompt_user_password()

        if not kwargs.get('totp') and (hasattr(sys.stdin, 'isatty') and
                                       sys.stdin.isatty()):
            try:
                kwargs['totp'] = getpass.getpass('2FA (TOTP) token: ')
            except EOFError:
                pass

        return super(Wmtotp, cls).load_from_argparse_arguments(namespace,
                                                               **kwargs)
