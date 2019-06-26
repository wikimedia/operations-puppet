class openstack::nova::compute::service::mitaka::jessie() {
    require ::openstack::serverpackages::mitaka::jessie

    $packages = [
        'libvirt-bin',
        'qemu-system',
        'nova-compute',
        'nova-compute-kvm',
        'spice-html5',
        'websockify',
        'virt-top',
        'dnsmasq-base',
        'libguestfs-tools',
    ]

    package { $packages:
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports']
    }

    service { 'libvirtd':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-bin],
    }
}
