class openstack::nova::compute::service::rocky::buster() {
    require openstack::serverpackages::rocky::buster

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
        'python3-libvirt',
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

    # Hack to fix live migration deletion
    # This applies a bug fix that is in upstream version S;
    # without it nova-compute deadlocks after a live migration.
    file { '/usr/lib/python3/dist-packages/nova/compute/manager.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/rocky/nova/hacks/manager.py';
    }
}
