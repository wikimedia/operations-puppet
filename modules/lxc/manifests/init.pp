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
        'bridge-utils',
        'dnsmasq-base',
        'redir',
    ]:
        ensure => present,
    }

    $package = [
      'libapparmor1',
      'liblxc1',
      'libseccomp2',
      'lxc',
      'python3-lxc',
    ]

    # T154294: Running a jessie image in the container requires newer versions
    # of LXC and it's dependencies than Trusty or Jessie shipped with.
    # Install the versions provided by backports instead.
    $backports = $::lsbdistcodename ? {
        trusty => [
            'cgroup-lite',
            'liblxc1',
            'lxc',
            'lxc-common',
            'lxc-templates',
            'lxc1',
            'python3-lxc',
        ],
        jessie => $package,
        default => $package,
    }

    if os_version('ubuntu == trusty || debian == jessie') {
      apt::pin { $backports:
        pin      => "release a=${::lsbdistcodename}-backports",
        priority => 500,
        before   => Package[$backports],
      }
    }

    package { $backports:
      ensure  => present,
    }

    if os_version('debian >= jessie') {
        file { '/etc/default/lxc-net':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => 'USE_LXC_BRIDGE="true"',
            require => Package['lxc'],
            notify  => Service['lxc-net'],
        }

        file { '/etc/lxc/default.conf':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/lxc/jessie/etc-lxc-default.conf',
            require => Package['lxc'],
            notify  => Service['lxc-net'],
        }

        service { 'lxc-net':
            ensure => 'running',
        }
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
