# = Class: jupyterhub::sytemd
#
# Sets up systemd version new enough for JupyterHub's systemd spawner to run.
#
# Installs systemd from jessie-backports.
class jupyterhub::sytemd {
    apt::pin { 'systemd':
        package  => 'systemd',
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['systemd'],
    }

    package { 'systemd':
        # FIXME: Is pinning this version required?
        # A simple `ensure => present` will not work as systemd is already
        # installed.
        ensure => '230-7~bpo8+2',
    }
}
