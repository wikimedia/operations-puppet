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
    requires_os('Ubuntu >= Trusty || Debian >= Jessie')

    package { [
        'redir',
        'bridge-utils',
    ]:
        ensure => present,
    }

    if os_version('Ubuntu >= Trusty') {
        # T154294: Running a jessie image in the container requires newer
        # versions of LXC and it's dependencies than Trusty shipped with.
        # Install the versions provided by trusty-backports instead.
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
    }

    if os_version('Debian >= Jessie') {
        package { [
            'dnsmasq-base',
            'ebtables',
            'libvirt-bin',
            'lxc',
        ]:
            ensure => present,
        }

        file { '/etc/lxc/default.conf':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/lxc/jessie-etc-lxc-default.conf',
            require => Package['lxc'],
        }

        exec { '/sbin/modprobe br_netfilter':
            unless  => '/sbin/lsmod | grep -q br_netfilter',
            require => Package['ebtables'],
        }

        file { '/usr/local/bin/setup-libvirt.sh':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/lxc/jessie-setup-libvirt.sh',
        }

        # FIXME: this won't succeed until ebtables has been installed AND the
        # host has been rebooted.
        # https://wiki.debian.org/LXC/LibVirtDefaultNetwork
        exec { '/usr/local/bin/setup-libvirt.sh':
            unless  => '/usr/bin/virsh -c lxc:/// net-list | /bin/grep -q default',
            require => [
                File['/usr/local/bin/setup-libvirt.sh'],
                Package['dnsmasq-base'],
                Package['ebtables'],
                Package['libvirt-bin'],
                Exec['/sbin/modprobe br_netfilter'],
            ],
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
