# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

""" Module defining the Django auth backend class for the Keystone API. """

import datetime
import logging
import pytz

from django.conf import settings
from django.utils.module_loading import import_string  # noqa
from django.utils.translation import ugettext_lazy as _
from keystoneauth1 import exceptions as keystone_exceptions

from openstack_auth import exceptions
from openstack_auth import user as auth_user
from openstack_auth import utils


LOG = logging.getLogger(__name__)


KEYSTONE_CLIENT_ATTR = "_keystoneclient"


class KeystoneBackend(object):
    """Django authentication backend for use with ``django.contrib.auth``."""

    def __init__(self):
        self._auth_plugins = None

    @property
    def auth_plugins(self):
        if self._auth_plugins is None:
            plugins = getattr(
                settings,
                'AUTHENTICATION_PLUGINS',
                ['openstack_auth.plugin.password.PasswordPlugin',
                 'openstack_auth.plugin.token.TokenPlugin'])

            self._auth_plugins = [import_string(p)() for p in plugins]

        return self._auth_plugins

    def check_auth_expiry(self, auth_ref, margin=None):
        if not utils.is_token_valid(auth_ref, margin):
            msg = _("The authentication token issued by the Identity service "
                    "has expired.")
            LOG.warning("The authentication token issued by the Identity "
                        "service appears to have expired before it was "
                        "issued. This may indicate a problem with either your "
                        "server or client configuration.")
            raise exceptions.KeystoneAuthException(msg)
        return True

    def get_user(self, user_id):
        """Returns the current user from the session data.

        If authenticated, this return the user object based on the user ID
        and session data.

        Note: this required monkey-patching the ``contrib.auth`` middleware
        to make the ``request`` object available to the auth backend class.
        """
        if (hasattr(self, 'request') and
                user_id == self.request.session["user_id"]):
            token = self.request.session['token']
            endpoint = self.request.session['region_endpoint']
            services_region = self.request.session['services_region']
            user = auth_user.create_user_from_token(self.request, token,
                                                    endpoint, services_region)
            return user
        else:
            return None

    def authenticate(self, auth_url=None, **kwargs):
        """Authenticates a user via the Keystone Identity API."""
        LOG.debug('Beginning user authentication')

        if not auth_url:
            auth_url = settings.OPENSTACK_KEYSTONE_URL

        auth_url = utils.fix_auth_url_version(auth_url)

        for plugin in self.auth_plugins:
            unscoped_auth = plugin.get_plugin(auth_url=auth_url, **kwargs)

            if unscoped_auth:
                break
        else:
            msg = _('No authentication backend could be determined to '
                    'handle the provided credentials.')
            LOG.warn('No authentication backend could be determined to '
                     'handle the provided credentials. This is likely a '
                     'configuration error that should be addressed.')
            raise exceptions.KeystoneAuthException(msg)

        session = utils.get_session()
        keystone_client_class = utils.get_keystone_client().Client

        try:
            unscoped_auth_ref = unscoped_auth.get_access(session)
        except keystone_exceptions.ConnectFailure as exc:
            LOG.error(str(exc))
            msg = _('Unable to establish connection to keystone endpoint.')
            raise exceptions.KeystoneAuthException(msg)
        except (keystone_exceptions.Unauthorized,
                keystone_exceptions.Forbidden,
                keystone_exceptions.NotFound) as exc:
            LOG.debug(str(exc))
            raise exceptions.KeystoneAuthException(_('Invalid credentials.'))
        except (keystone_exceptions.ClientException,
                keystone_exceptions.AuthorizationFailure) as exc:
            msg = _("An error occurred authenticating. "
                    "Please try again later.")
            LOG.debug(str(exc))
            raise exceptions.KeystoneAuthException(msg)

        # Check expiry for our unscoped auth ref.
        self.check_auth_expiry(unscoped_auth_ref)

        # domain support can require domain scoped tokens to perform
        # identity operations depending on the policy files being used
        # for keystone.
        domain_auth = None
        domain_auth_ref = None
        if utils.get_keystone_version() >= 3 and 'user_domain_name' in kwargs:
            try:
                token = unscoped_auth_ref.auth_token
                domain_auth = utils.get_token_auth_plugin(
                    auth_url,
                    token,
                    domain_name=kwargs['user_domain_name'])
                domain_auth_ref = domain_auth.get_access(session)
            except Exception:
                LOG.debug('Error getting domain scoped token.', exc_info=True)

        projects = plugin.list_projects(session,
                                        unscoped_auth,
                                        unscoped_auth_ref)
        # Attempt to scope only to enabled projects
        projects = [project for project in projects if project.enabled]

        # Abort if there are no projects for this user and a valid domain
        # token has not been obtained
        #
        # The valid use cases for a user login are:
        #    Keystone v2: user must have a role on a project and be able
        #                 to obtain a project scoped token
        #    Keystone v3: 1) user can obtain a domain scoped token (user
        #                    has a role on the domain they authenticated to),
        #                    only, no roles on a project
        #                 2) user can obtain a domain scoped token and has
        #                    a role on a project in the domain they
        #                    authenticated to (and can obtain a project scoped
        #                    token)
        #                 3) user cannot obtain a domain scoped token, but can
        #                    obtain a project scoped token
        if not projects and not domain_auth_ref:
            msg = _('You are not authorized for any projects.')
            if utils.get_keystone_version() >= 3:
                msg = _('You are not authorized for any projects or domains.')
            raise exceptions.KeystoneAuthException(msg)

        # the recent project id a user might have set in a cookie
        recent_project = None
        request = kwargs.get('request')

        if request:
            # Grab recent_project found in the cookie, try to scope
            # to the last project used.
            recent_project = request.COOKIES.get('recent_project')

        # if a most recent project was found, try using it first
        if recent_project:
            for pos, project in enumerate(projects):
                if project.id == recent_project:
                    # move recent project to the beginning
                    projects.pop(pos)
                    projects.insert(0, project)
                    break

        for project in projects:
            token = unscoped_auth_ref.auth_token
            scoped_auth = utils.get_token_auth_plugin(auth_url,
                                                      token=token,
                                                      project_id=project.id)

            try:
                scoped_auth_ref = scoped_auth.get_access(session)
            except (keystone_exceptions.ClientException,
                    keystone_exceptions.AuthorizationFailure):
                pass
            else:
                break
        else:
            # if the user can't obtain a project scoped token, set the scoped
            # token to be the domain token, if valid
            if domain_auth_ref:
                scoped_auth = domain_auth
                scoped_auth_ref = domain_auth_ref
            else:
                # if no domain or project token for user, abort
                msg = _("Unable to authenticate to any available projects.")
                raise exceptions.KeystoneAuthException(msg)

        # Check expiry for our new scoped token.
        self.check_auth_expiry(scoped_auth_ref)

        interface = getattr(settings, 'OPENSTACK_ENDPOINT_TYPE', 'public')

        # If we made it here we succeeded. Create our User!
        unscoped_token = unscoped_auth_ref.auth_token
        user = auth_user.create_user_from_token(
            request,
            auth_user.Token(scoped_auth_ref, unscoped_token=unscoped_token),
            scoped_auth_ref.service_catalog.url_for(service_type='identity',
                                                    interface=interface))

        if request is not None:
            request.session['unscoped_token'] = unscoped_token
            if domain_auth_ref:
                # check django session engine, if using cookies, this will not
                # work, as it will overflow the cookie so don't add domain
                # scoped token to the session and put error in the log
                if utils.using_cookie_backed_sessions():
                    LOG.error('Using signed cookies as SESSION_ENGINE with '
                              'OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT is '
                              'enabled. This disables the ability to '
                              'perform identity operations due to cookie size '
                              'constraints.')
                else:
                    request.session['domain_token'] = domain_auth_ref

            request.user = user

            # Custom hack for WMF:
            if 'extended_session' in kwargs and kwargs['extended_session']:
                timeout = getattr(settings, "SESSION_TIMEOUT", 86400)
            else:
                timeout = getattr(settings, "SESSION_SHORT_TIMEOUT", 1800)

            token_life = user.token.expires - datetime.datetime.now(pytz.utc)

            # Fix for https://bugs.launchpad.net/django-openstack-auth/+bug/1562452:
            session_time = min(timeout, int(token_life.total_seconds()))

            request.session.set_expiry(session_time)

            scoped_client = keystone_client_class(session=session,
                                                  auth=scoped_auth)

            # Support client caching to save on auth calls.
            setattr(request, KEYSTONE_CLIENT_ATTR, scoped_client)

        LOG.debug('Authentication completed.')
        return user

    def get_group_permissions(self, user, obj=None):
        """Returns an empty set since Keystone doesn't support "groups"."""
        # Keystone V3 added "groups". The Auth token response includes the
        # roles from the user's Group assignment. It should be fine just
        # returning an empty set here.
        return set()

    def get_all_permissions(self, user, obj=None):
        """Returns a set of permission strings that the user has.

        This permission available to the user is derived from the user's
        Keystone "roles".

        The permissions are returned as ``"openstack.{{ role.name }}"``.
        """
        if user.is_anonymous() or obj is not None:
            return set()
        # TODO(gabrielhurley): Integrate policy-driven RBAC
        #                      when supported by Keystone.
        role_perms = {"openstack.roles.%s" % role['name'].lower()
                      for role in user.roles}

        services = []
        for service in user.service_catalog:
            try:
                service_type = service['type']
            except KeyError:
                continue
            service_regions = [utils.get_endpoint_region(endpoint) for endpoint
                               in service.get('endpoints', [])]
            if user.services_region in service_regions:
                services.append(service_type.lower())
        service_perms = {"openstack.services.%s" % service
                         for service in services}
        return role_perms | service_perms

    def has_perm(self, user, perm, obj=None):
        """Returns True if the given user has the specified permission."""
        if not user.is_active:
            return False
        return perm in self.get_all_permissions(user, obj)

    def has_module_perms(self, user, app_label):
        """Returns True if user has any permissions in the given app_label.

        Currently this matches for the app_label ``"openstack"``.
        """
        if not user.is_active:
            return False
        for perm in self.get_all_permissions(user):
            if perm[:perm.index('.')] == app_label:
                return True
        return False
