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
    c.LocalAuthenticator.server_address = 'ldap-labs.eqiad.wikimedia.org'
    c.LocalAuthenticator.bind_dn_template = \
        'uid={username},ou=people,dc=wikimedia,dc=org'
    c.LocalAuthenticator.allowed_groups = [
        'cn=ops,ou=groups,dc=wikimedia,dc=org',
    ]
