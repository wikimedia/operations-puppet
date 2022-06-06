# SPDX-License-Identifier: Apache-2.0
# == Class: lxc
#
# Provision LXC
#
# === Parameters:
# [*container_root*]
#   Directory where LXC will store containers (default: '/srv/lxc')
#
class lxc(
    Stdlib::Unixpath $container_root = '/srv/lxc',
) {
    ensure_packages(['bridge-utils', 'dnsmasq-base', 'redir', 'lxc'])

    if debian::codename::ge('buster') {
        ensure_packages(['lxc-templates', 'ebtables', 'iptables', 'libvirt-clients', 'libvirt-daemon-system'])

        exec { 'virsh net-start default':
            command => '/usr/bin/virsh net-start default',
            unless  => "/usr/bin/virsh -q net-list --all|/bin/grep -Eq '^\s*default\s+active'",
            require => Package['ebtables', 'iptables', 'libvirt-clients', 'libvirt-daemon-system'],
        }
        exec { 'virsh net-autostart default':
            command => '/usr/bin/virsh net-autostart default',
            creates => '/etc/libvirt/qemu/networks/autostart/default.xml',
            require => Package['ebtables', 'iptables', 'libvirt-clients', 'libvirt-daemon-system'],
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
