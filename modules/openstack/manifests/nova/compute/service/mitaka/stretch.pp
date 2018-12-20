class openstack::nova::compute::service::mitaka::stretch(
    $libvirt_type,
    $certname,
    $ca_target,
    $libvirt_unix_sock_group,
) {
    require openstack::serverpackages::mitaka::stretch

    $packages = [
        'libvirt-daemon-system',
        'libvirt-clients',
        'qemu-system',
        'spice-html5',
        'websockify',
        'virt-top',
        'dnsmasq-base',
    ]

    package { $packages:
        ensure => 'present',
    }

    $packages_hack = [
        'nova-compute',
        'nova-compute-kvm',
    ]

    package { $packages_hack:
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports']
    }

    # /etc/default/libvirt-guests
    # Guest management on host startup/reboot
    service { 'libvirt-guests':
        ensure => 'stopped',
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
