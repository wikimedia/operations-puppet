class openstack::nova::compute::service::mitaka::trusty(
    $libvirt_type,
    $certname,
    $ca_target,
    $libvirt_unix_sock_group,
) {
    require ::openstack::serverpackages::mitaka::trusty

    $packages = [
        'libvirt-bin',
        'qemu-system',
        'nova-compute',
        'nova-compute-kvm',
        'spice-html5',
        'websockify',
        'virt-top',
        'dnsmasq-base',
    ]

    package { $packages:
        ensure => 'present',
    }

    # On Ubuntu as of Liberty:
    #   qemu-kvm and qemu-system are alternative packages to meet
    #   the needs of libvirt.
    package { [ 'qemu-kvm' ]:
        ensure  => 'absent',
        require => Package['qemu-system'],
    }

    # On Ubuntu as of Liberty:
    #   Some older VMs have a hardcoded path to the emulator
    #   binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
    #   new distros don't create a kvm binary.  We can safely
    #   alias kvm to qemu-system-x86_64 which keeps those old
    #   instances happy.
    #   (Note: Jessie handles this by creating a shell script shortcut)
    file { '/usr/bin/kvm':
        ensure  => 'link',
        target  => '/usr/bin/qemu-system-x86_64',
        require => Package['qemu-system'],
    }

    file { '/etc/libvirt/qemu/networks/autostart/default.xml':
        ensure  => 'absent',
        require => Package['libvirt-bin'],
    }

    service { 'libvirt-bin':
        ensure  => 'running',
        enable  => true,
        require => Package[libvirt-bin],
    }

    file { '/etc/libvirt/libvirtd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/libvirtd.conf.erb'),
        notify  => Service['libvirt-bin'],
        require => Package['nova-compute'],
    }

    file { '/etc/default/libvirt-bin':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/libvirt.default.erb'),
        notify  => Service['libvirt-bin'],
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

    # By default trusty allows the creation of user namespaces by unprivileged users
    # (Debian defaulted to disallowing these since the feature was introduced for security reasons)
    # Unprivileged user namespaces are not something we need in general (and especially
    # not in trusty where support for namespaces is incomplete) and was the source for
    # several local privilege escalation vulnerabilities. The 4.4 HWE kernel for trusty
    # contains a backport of the Debian patch allowing to disable the creation of user
    # namespaces via a sysctl, so disable to limit the attack footprint
    if versioncmp($::kernelversion, '4.4') >= 0 {
        sysctl::parameters { 'disable-unprivileged-user-namespaces-labvirt':
            values => {
                'kernel.unprivileged_userns_clone' => 0,
            },
        }
    }
}
