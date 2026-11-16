#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
#
# JupyterHub configuration for the jupyter-analytics package. See T321512.
# Puppet writes the host settings to config.json in the same directory.

import grp
import json
import os
import socket
import ssl
import sys

from jupyterhub.utils import maybe_future
from traitlets import List, Unicode

from wmf_spawner import CondaEnvSpawner

c = get_config()  # noqa: F821

# Defaults. The values in config.json override them.
config = {
    'conda_base_env_prefix': '/opt/conda-analytics',
    'jupyter_env_prefix': '/opt/jupyter-analytics',
    # Users connect to this port.
    'port': 8880,
    # The hub listens on this port. The proxy and the single-user servers connect to it.
    'hub_port': 8881,
    # The configurable-http-proxy API listens on this port.
    'proxy_api_port': 8882,
    'proxy_pid_file': '/srv/jupyterhub/data/jupyterhub-proxy.pid',
    'db_url': 'sqlite:////srv/jupyterhub/data/jupyterhub.sqlite',
    'cookie_secret_file': '/srv/jupyterhub/data/jupyterhub_cookie_secret',
    'template_path': '/etc/jupyterhub/templates',
    'singleuser_script': '/etc/jupyterhub/jupyterhub-singleuser.sh',
    'server_config_dir': '/etc/jupyterhub/server_config',
    'terminal_bashrc': '/etc/jupyterhub/terminal_bashrc',
    'conda_kernel_launcher': '/etc/jupyterhub/conda_kernel_launcher.sh',
    # 'ldap' or 'dummy'. Use 'dummy' only for tests.
    'authenticator': 'ldap',
    'ldap_server': 'ldap-ro.eqiad.wikimedia.org',
    'ldap_ca_certs_file': '/etc/ssl/certs/ca-certificates.crt',
    'ldap_bind_dn_template': 'uid={username},ou=people,dc=wikimedia,dc=org',
    'allowed_ldap_groups': [
        'cn=nda,ou=groups,dc=wikimedia,dc=org',
        'cn=wmf,ou=groups,dc=wikimedia,dc=org',
    ],
    # Users must also be in one of these posix groups on the host.
    'allowed_posix_groups': [
        'analytics-privatedata-users',
        'analytics-admins',
        'gpu-users',
        'analytics-search-users',
        'analytics-wmde-users',
        'analytics-product-users',
    ],
    # Members of these posix groups are JupyterHub admins.
    'admin_posix_groups': ['ops', 'analytics-admins'],
    'log_level': 'DEBUG',
    'external_http_proxy_host': 'webproxy.eqiad.wmnet',
    'external_http_proxy_port': 8080,
    'java_home': '/usr/lib/jvm/java-1.8.0-openjdk-amd64',
}

with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.json')) as f:
    config.update(json.load(f))

conda_base_env_prefix = config['conda_base_env_prefix']
jupyter_env_prefix = config['jupyter_env_prefix']

for prefix in (conda_base_env_prefix, jupyter_env_prefix):
    if not os.path.exists(prefix):
        sys.exit(f'Cannot start JupyterHub: {prefix} does not exist.')

host_ip_address = socket.gethostbyname(socket.gethostname())


def posix_group_members(groups):
    """Return the members of the posix groups. Ignore groups that do not exist."""
    members = set()
    for group in groups:
        try:
            members.update(grp.getgrnam(group).gr_mem)
        except KeyError:
            pass
    return members


# == Hub and proxy ==

c.JupyterHub.log_level = config['log_level']

# configurable-http-proxy listens on this address. Users connect to it.
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = int(config['port'])

c.JupyterHub.template_paths = [config['template_path']]

# The single-user servers connect to the hub on this address.
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_connect_ip = host_ip_address
c.JupyterHub.hub_port = int(config['hub_port'])

c.ConfigurableHTTPProxy.command = [
    os.path.join(jupyter_env_prefix, 'bin', 'node'),
    os.path.join(jupyter_env_prefix, 'bin', 'configurable-http-proxy'),
]
c.ConfigurableHTTPProxy.api_url = f'http://127.0.0.1:{config["proxy_api_port"]}'
c.ConfigurableHTTPProxy.pid_file = config['proxy_pid_file']

c.JupyterHub.db_url = config['db_url']
c.JupyterHub.cookie_secret_file = config['cookie_secret_file']

# Each user has one server.
c.JupyterHub.allow_named_servers = False

# Keep the single-user servers running when the hub restarts.
c.JupyterHub.cleanup_servers = False

# Creating a new conda environment at spawn time can take some time.
c.Spawner.http_timeout = 120
c.Spawner.start_timeout = 120

# == Admin access ==

# The default admin role can access the servers of all users.
admin_users = posix_group_members(config['admin_posix_groups'])
if admin_users:
    c.Authenticator.admin_users = admin_users

# == Authenticator ==

# The hub does not call check_allowed if allow_all is True, and
# PosixGroupAuthenticator.check_allowed does the posix group check.
c.Authenticator.allow_all = False

if config['authenticator'] == 'ldap':
    from ldapauthenticator import LDAPAuthenticator as BaseAuthenticator

    c.LDAPAuthenticator.server_address = config['ldap_server']
    c.LDAPAuthenticator.bind_dn_template = [config['ldap_bind_dn_template']]
    c.LDAPAuthenticator.allowed_groups = config['allowed_ldap_groups']
    # Use StartTLS and make sure that the server certificate is valid.
    c.LDAPAuthenticator.tls_strategy = 'before_bind'
    c.LDAPAuthenticator.tls_kwargs = {
        'validate': ssl.CERT_REQUIRED,
        'ca_certs_file': config['ldap_ca_certs_file'],
    }
elif config['authenticator'] == 'dummy':
    from jupyterhub.auth import DummyAuthenticator as BaseAuthenticator
else:
    raise ValueError(f'Authenticator {config["authenticator"]} is not supported.')


class PosixGroupAuthenticator(BaseAuthenticator):
    """Allow only the users that are members of one of the allowed posix groups."""

    allowed_posix_groups = List(
        Unicode(),
        help='Users must be members of one of these posix groups on the host.',
    ).tag(config=True)

    async def check_allowed(self, username, authentication=None):
        if username not in posix_group_members(self.allowed_posix_groups):
            self.log.warning(
                'User %s is not in the allowed posix groups (%s)',
                username, ', '.join(self.allowed_posix_groups),
            )
            return False
        if config['authenticator'] == 'dummy':
            # DummyAuthenticator has no allow settings of its own.
            return True
        # LDAPAuthenticator checks allowed_groups here.
        return await maybe_future(super().check_allowed(username, authentication))


c.JupyterHub.authenticator_class = PosixGroupAuthenticator
c.PosixGroupAuthenticator.allowed_posix_groups = config['allowed_posix_groups']

# == Spawner ==

# The single-user servers, kernels and terminals get these environment variables.
user_environment = {
    'JAVA_HOME': config['java_home'],
    'CONDA_BASE_ENV_PREFIX': conda_base_env_prefix,
    'JUPYTER_ENV_PREFIX': jupyter_env_prefix,
    'JUPYTER_SERVER_CONFIG_DIR': config['server_config_dir'],
    'JUPYTER_TERMINAL_BASHRC': config['terminal_bashrc'],
    'JUPYTER_CONDA_KERNEL_LAUNCHER': config['conda_kernel_launcher'],
    # nb_conda_kernels uses this conda to find the user environments.
    'CONDA_EXE': os.path.join(conda_base_env_prefix, 'bin', 'conda'),
}
if config.get('external_http_proxy_host'):
    external_http_proxy_url = (
        f'http://{config["external_http_proxy_host"]}:{config["external_http_proxy_port"]}'
    )
    user_environment['http_proxy'] = external_http_proxy_url
    user_environment['https_proxy'] = external_http_proxy_url
    # Do not use the proxy for the hub, localhost or *.wmnet.
    user_environment['no_proxy'] = f'localhost,127.0.0.1,{host_ip_address},.wmnet'
    # Make JVM processes use the proxy too.
    user_environment['JAVA_OPTS'] = '-Djava.net.useSystemProxies'

c.JupyterHub.spawner_class = CondaEnvSpawner
c.CondaEnvSpawner.environment = user_environment
c.CondaEnvSpawner.default_url = '/lab'
c.CondaEnvSpawner.singleuser_script = config['singleuser_script']

# The hub runs conda as the user to list the conda environments of the user.
c.CondaEnvSpawner.conda_cmd = [
    'sudo', '--set-home', '-u', '{USERNAME}',
    os.path.join(conda_base_env_prefix, 'condabin', 'conda'),
]
# Users cannot install packages into the base environments, so do not offer them.
c.CondaEnvSpawner.hidden_env_prefixes = [
    conda_base_env_prefix,
    f'{conda_base_env_prefix}-next',
    jupyter_env_prefix,
]

c.SystemdSpawner.slice = 'user.slice'

# Do not use PrivateTmp. The Kerberos credential caches are in /tmp.
c.SystemdSpawner.isolate_tmp = False

# Users can never get root privileges from their servers.
c.SystemdSpawner.disable_user_sudo = True

# readonly_paths does not work with HDFS-FUSE after bullseye. See T333511.
c.SystemdSpawner.readonly_paths = None
c.SystemdSpawner.readwrite_paths = [
    '/home/{USERNAME}', '/dev/shm', '/run/user', '/tmp', '/srv/spark-tmp',
]

# modules/profile/files/rsyslog/lookup_table_output.json sends this identifier to Kafka.
c.SystemdSpawner.unit_extra_properties = {
    'SyslogIdentifier': 'jupyterhub-singleuser',
    'CollectMode': 'inactive-or-failed',
}

# This name is different from the units of jupyterhub::server.
c.SystemdSpawner.unit_name_template = 'jupyter-{USERNAME}-singleuser'
