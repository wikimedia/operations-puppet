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
    # T154294: Running a jessie image in the container requires newer versions
    # of LXC and it's dependencies than Trusty shipped with. Install the
    # versions provided by trusty-backports instead.
    $lxc_backports = [
        'cgroup-lite',
        'liblxc1',
        'lxc',
        'lxc-common',
        'lxc-templates',
        'lxc1',
        'python3-lxc',
    ]
    apt::pin { $lxc_backports:
        pin      => 'release a=trusty-backports',
        priority => 500,
    }
    package { $lxc_backports:
      ensure => present,
    }

    package { [
        'redir',
        'bridge-utils',
    ]:
        ensure => present,
    }

    file { $container_root:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $container_root != '/var/lib/lxc' {
        # Symlink default LXC container storage directory to configured
        # location
        file { '/var/lib/lxc':
            ensure => 'link',
            target => $container_root,
            force  => true,
        }
    }
}

