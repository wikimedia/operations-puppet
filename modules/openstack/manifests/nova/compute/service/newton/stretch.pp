class openstack::nova::compute::service::newton::stretch() {
    require openstack::serverpackages::newton::stretch

    # make sure we don't have libssl1.0.0 installed. We don't need it in
    # cloudvirt servers running stretch, and it can cause conflicts resolving
    # dependencies
    package { 'libssl1.0.0':
        ensure => 'absent',
    }

    # the libvirt-daemon-system install may trigger an update-initramfs run.
    # under some circumstances, the busybox package may not be installed, thus
    # failing the complete stack installation, because initramfs requires it,
    # but is declared as Recommends and not Depends
    package { 'busybox':
        ensure => 'present',
    }

    $packages = [
        'libvirt-daemon-system',
        'libvirt-clients',
        'qemu-system',
        'spice-html5',
        'websockify',
        'dnsmasq-base',
        'qemu-utils',
        'libguestfs-tools',
        'nova-compute',
        'nova-compute-kvm',
    ]

    package { $packages:
        ensure  => 'present',
        require => Package['busybox'],
        before  => Package['virt-top'],
    }

    # install this later, once the right version of libvirt0 is already present
    package { 'virt-top':
        ensure => 'present',
    }

    service { 'libvirtd':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-daemon-system],
    }
}
