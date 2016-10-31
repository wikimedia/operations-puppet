"""
Configure JupyterHub securely with SystemdSpawner & LDAP/Dummy Authenticator

We pick up configuration on what to do from environment variables which
are set via puppet. This allows us to keep this a pure python file, rather
than a ruby template (erb) that generates python.
"""
import os
import subprocess
import shutil
from tornado import gen


AUTHENTICATOR = os.environ['AUTHENTICATOR']
WHEELS_PATH = os.environ['WHEELS_PATH']
DATA_PATH = os.environ['DATA_PATH']

if AUTHENTICATOR == 'dummy':
    from dummyauthenticator import DummyAuthenticator as Authenticator
elif AUTHENTICATOR == 'ldap':
    from ldapauthenticator import LDAPAuthenticator as Authenticator
else:
    raise ImportError('Unknown AUTHENTICATOR_CLASS %s' % AUTHENTICATOR)



c.JupyterHub.log_level = 'WARN'

# Isolate the db file into a specific directory, and give JupyterHub write
# access only to this. This prevents it from overwriting its own code easily.
c.JupyterHub.db_url = 'sqlite:///{dp}/jupyterhub.sqlite'.format(dp=DATA_PATH)

# Have the hub itself listen only on localhost
c.JupyterHub.hub_ip = '127.0.0.1'
c.JupyterHub.hub_port = 8081

# The hub will look for a proxy that's listening on this ip and port
# We manage that via another systemd unit file + configuration
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000
c.JupyterHub.proxy_api_port = 8001

# Do not kill servers when the hub restarts
c.JupyterHub.cleanup_servers = False

c.JupyterHub.spawner_class = 'systemdspawner.SystemdSpawner'
# This is enough, since we'll put a jupyterhub-singleuser script in
# here from the LocalAuthenticator. This also enables users to install
# things via pip easily and have them be immediately available
c.SystemdSpawner.extra_paths = ['/home/{USERNAME}/venv/bin']

# ???
c.SystemdSpawner.environment = {
    'HADOOP_CONF_DIR': '/etc/hadoop/conf.analytics-cluster/',
}

class VenvCreatingAuthenticator(Authenticator):
    """
    Authenticator that creates venvs for each user.

    - If a user's homedirectory does not exist, we create it and chown it
      appropriately
    - if the user doesn't have a venv in their homedir, we create one under
      $HOME/venv, and install jupyterhub+jupyter in it from our wheelhouse

    This happens before the notebook is launched for each users, and thus
    users can install packages they want with pip from here.
    """
    @gen.coroutine
    def add_user(self, user):
        home_path = os.path.join('/home', user.name)
        venv_path = os.path.join(home_path, 'venv')
        if not os.path.exists(home_path):
            os.mkdir(home_path, 0o755)
            shutil.chown(home_path, user.name, 'wikidev')
        if not os.path.exists(venv_path):
            subprocess.check_call([
                'sudo',
                '-u', user.name,
                '/usr/bin/python3',
                '-m', 'venv',
                venv_path
            ])
            subprocess.check_call([
                'sudo',
                '-u', user.name,
                os.path.join(venv_path, 'bin', 'pip'),
                'install',
                '--no-index',
                '--find-links={wp}/wheelhouse'.format(wp=WHEELS_PATH),
                'jupyter',
                'jupyterhub'
            ])


c.JupyterHub.authenticator_class = VenvCreatingAuthenticator

if AUTHENTICATOR == 'ldap':
    c.LDAPAuthenticator.server_address = 'ldap-labs.eqiad.wikimedia.org'
    c.LDAPAuthenticator.bind_dn_template = \
        'uid={username},ou=people,dc=wikimedia,dc=org'
    c.LDAPAuthenticator.allowed_groups = [
        'cn=ops,ou=groups,dc=wikimedia,dc=org',
    ]

# Security settings! Let's lock this down!
# This provides arbitrary code execution over the web, so needs to be as
# secure as possible.
# The threat model is dual:
#  1. Compromise of JupyterHub itself
#  2. Compromise of individual user's notebook
#
# We aren't patching for (1) here, but just for (2). In case of a compromise,
# we want the attacker to not be able to gain any extra privilages at all.
# We want the attack to be as confined as possible. We'll need auditing and
# what not built eventually, but here are some basic rudimentary protections.
# This also requires systemd > 228, so we must have systemd from jessie-backports

# Give each user their own /tmp! Prevents data leaks via accidentally writing
# to /tmp
c.SystemdSpawner.isolate_tmp = True

# Give each user their own /dev. This prevents users from gaining direct
# device access, which helps prevent escalation via device specific bugs
c.SystemdSpawner.isolate_devices = True

# Disable users from ever gaining root privilages for anything at all.
# This protects against the notebook of a privilaged user being compromised
# to gain root
c.SystemdSpawner.disable_user_sudo = True

# We allow users to only write to their homedirs, and nowhere else
c.SystemdSpawner.readonly_paths = ['/']
c.SystemdSpawner.readwrite_paths = ['/home/{USERNAME}']
