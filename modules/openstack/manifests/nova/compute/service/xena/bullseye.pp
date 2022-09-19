# SPDX-License-Identifier: Apache-2.0

class openstack::nova::compute::service::xena::bullseye() {
    require openstack::serverpackages::xena::bullseye

    # the libvirt-daemon-system install may trigger an update-initramfs run.
    # under some circumstances, the busybox package may not be installed, thus
    # failing the complete stack installation, because initramfs requires it,
    # but is declared as Recommends and not Depends
    package { 'busybox':
        ensure => 'present',
    }

    ensure_packages(['libvirt-clients'])

    $packages = [
        'libvirt-daemon-system',
        'python3-libvirt',
        'qemu-system',
        'spice-html5',
        'websockify',
        'dnsmasq-base',
        'qemu-utils',
        'nova-compute',
        'nova-compute-kvm',
    ]

    package { $packages:
        ensure  => 'present',
        require => Package['busybox'],
    }

    # The only reliable order to get this working is:
    #  - stop libvirtd
    #  - start libvirtd-tls.socket
    #  - start libvirtd
    service { 'libvirtd-tls.socket':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-daemon-system],
        before  => Service['libvirtd'],
        start   => '/usr/bin/systemctl stop libvirtd && /usr/bin/systemctl start libvirtd-tls.socket',
    }

    service { 'libvirtd-tcp.socket':
        ensure  => 'stopped',
        require => Package[libvirt-daemon-system],
        before  => Service['libvirtd-tls.socket'],
    }

    service { 'libvirtd':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-daemon-system],
    }
}
