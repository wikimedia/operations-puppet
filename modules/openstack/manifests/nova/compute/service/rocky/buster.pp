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

    # The default ebtables installed on Buster causes a fail in the l3 bridge:
    #
    #  Exit code: 255; Stdin: ; Stdout: ; Stderr: Policy DROP not allowed for user defined chains.
    #
    # This is resolved by using the legacy alternative, as discussed (briefly) here:
    #  https://ask.openstack.org/en/question/120060/neutron-failing-to-deploy-with-policy-drop-not-allowed-for-user-defined-chains/
    #
    exec {'use_legacy_ebtables_for_neutron':
        command   => '/usr/bin/update-alternatives --set ebtables  /usr/sbin/ebtables-legacy',
        unless    => '/usr/bin/update-alternatives --query ebtables | /usr/bin/grep Value | /usr/bin/grep ebtables-legacy',
        logoutput => true,
        require   => Package['nova-compute'],
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
