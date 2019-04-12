class openstack::nova::compute::service::mitaka::stretch(
    $libvirt_type,
    $certname,
    $ca_target,
    $libvirt_unix_sock_group,
) {
    require openstack::serverpackages::mitaka::stretch

    # make sure we don't have libssl1.0.0 installed. I don't remember
    # the exact reasons for this.
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

    # packages will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { $packages:
        ensure  => 'present',
        require => Package['busybox'],
        before  => Package['virt-top'],
    }

    # install this later, once the right version of libvirt0 is already present
    package { 'virt-top':
        ensure => 'present',
    }

    file {'/etc/libvirt/original':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => true,
        source  => 'puppet:///modules/openstack/mitaka/nova/libvirt/original',
        require => Package['nova-compute'],
    }

    service { 'libvirtd':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-daemon-system],
    }

    file { '/etc/libvirt/libvirtd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/libvirtd.conf.erb'),
        notify  => Service['libvirtd'],
        require => Package['nova-compute'],
    }

    file { '/etc/default/libvirtd':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/libvirt.default.erb'),
        notify  => Service['libvirtd'],
        require => Package['nova-compute'],
    }

    file { '/etc/nova/nova-compute.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/nova-compute.conf.erb'),
        notify  => Service['nova-compute'],
        require => Package['nova-compute'],
    }
}
