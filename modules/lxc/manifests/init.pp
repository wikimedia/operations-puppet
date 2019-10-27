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

    if os_version('debian == jessie') {
        # T154294: Running a jessie image in the container requires newer versions
        # of LXC and it's dependencies than Trusty or Jessie shipped with.
        # Install the versions provided by backports instead.
        $backports = $::lsbdistcodename ? {
            jessie => [
              'libapparmor1',
              'liblxc1',
              'libseccomp2',
              'lxc',
              'python3-lxc',
            ],
        }

        apt::pin { $backports:
          pin      => "release a=${::lsbdistcodename}-backports",
          priority => 500,
          before   => Package['lxc'],
        }
    }

    package { 'lxc':
        ensure => present,
    }

    if os_version('debian >= buster') {
        package { 'lxc-templates':
            ensure => present,
        }

        require_package(
            'ebtables',
            'iptables',
            'libvirt-clients',
            'libvirt-daemon-system',
        )

        exec { 'virsh net-start default':
            command => '/usr/bin/virsh net-start default',
            unless  => "/usr/bin/virsh -q net-list --all|/bin/grep -Eq '^\s*default\s+active'",
            require => [
                Package['ebtables'],
                Package['iptables'],
                Package['libvirt-clients'],
                Package['libvirt-daemon-system'],
            ],
        }
        exec { 'virsh net-autostart default':
            command => '/usr/bin/virsh net-autostart default',
            creates => '/etc/libvirt/qemu/networks/autostart/default.xml',
            require => [
                Package['ebtables'],
                Package['iptables'],
                Package['libvirt-clients'],
                Package['libvirt-daemon-system'],
            ],
        }
    }

    file { '/etc/lxc/default.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/lxc/${::lsbdistcodename}/etc-lxc-default.conf",
        require => Package['lxc'],
        notify  => Service['lxc-net'],
    }

    file { '/etc/default/lxc-net':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'USE_LXC_BRIDGE="true"',
        require => Package['lxc'],
        notify  => Service['lxc-net'],
    }

    service { 'lxc-net':
        ensure => 'running',
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
