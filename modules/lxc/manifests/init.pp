# == Class: lxc
#
# Provision LXC
#
# === Parameters:
# [*container_root*]
#   Directory where LXC will store containers (default: '/srv/lxc')
#
class lxc(
    $container_root = '/srv/lxc',
) {
    package { [
        'lxc',
        'lxc-templates',
        'cgroup-lite',
        'redir',
        'bridge-utils',
    ]:
        ensure => present,
    }

    file { $container_root:
        ensure => 'directory',
    }

    if $container_root != '/var/lib/lxc' {
        # Symlink default LXC container storage directory to configured
        # location
        file { '/var/lib/lxc':
            ensure => 'link',
            target => $container_root,
        }
    }
}

