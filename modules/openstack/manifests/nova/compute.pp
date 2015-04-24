class openstack::nova::compute(
    $openstack_version=$::openstack::version,
    $novaconfig
){
    include openstack::repo

    if ( $::realm == 'production' ) {
        if ($::hostname =~ /^labvirt/) {
            $certname = "labvirt-star.${site}.wmnet"
            $ca_target = '/etc/ssl/certs/wmf_ca_2014_2017.pem'
        } else {
            $certname = "virt-star.${site}.wmnet"
            $ca_target = '/etc/ssl/certs/wmf_ca_2014_2017.pem'
        }
        install_certificate{ "${certname}": }

        file { "/var/lib/nova/${certname}.key":
            owner   => 'nova',
            group   => 'libvirtd',
            mode    => '0440',
            source  => "puppet:///private/ssl/${certname}.key",
            require => Package['nova-common'],
        }
        file { '/var/lib/nova/clientkey.pem':
            ensure  => link,
            target  => "/var/lib/nova/${certname}.key",
        }
        file { '/var/lib/nova/clientcert.pem':
            ensure  => link,
            target  => "/etc/ssl/localcerts/${certname}.crt",
            require => Install_certificate["${certname}"],
        }
        file { '/var/lib/nova/cacert.pem':
            ensure  => link,
            target  => $ca_target,
            require => Install_certificate["${certname}"],
        }
        file { '/var/lib/nova/.ssh':
            ensure  => directory,
            owner   => 'nova',
            group   => 'nova',
            mode    => '0700',
            require => Package['nova-common'],
        }
        file { '/var/lib/nova/.ssh/id_rsa':
            source  => 'puppet:///private/ssh/nova/nova.key',
            owner   => 'nova',
            group   => 'nova',
            mode    => '0600',
            require => File['/var/lib/nova/.ssh'],
        }
        file { '/var/lib/nova/.ssh/id_rsa.pub':
            source  => 'puppet:///private/ssh/nova/nova.pub',
            owner   => 'nova',
            group   => 'nova',
            mode    => '0600',
            require => File['/var/lib/nova/.ssh'],
        }
        file { '/etc/libvirt/libvirtd.conf':
            notify  => Service['libvirt-bin'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('openstack/common/nova/libvirtd.conf.erb'),
            require => Package['nova-common'],
        }
        file { '/etc/default/libvirt-bin':
            notify  => Service['libvirt-bin'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('openstack/common/nova/libvirt-bin.default.erb'),
            require => Package['nova-common'],
        }
        file { '/etc/nova/nova-compute.conf':
            notify  => Service['nova-compute'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('openstack/common/nova/nova-compute.conf.erb'),
            require => Package['nova-common'],
        }
    }

    ssh::userkey { 'nova':
        source => 'puppet:///private/ssh/nova/nova.pub',
    }

    service { 'libvirt-bin':
        ensure  => running,
        enable  => true,
        require => Package['nova-common'],
    }

    # Fail hard and loud if the kernel is not recent enough to have a
    # fix for the KSM bug in Trusty and refuse to install nova-compute
    # entirely.
    #
    # see: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1346917

    if os_version('ubuntu >= trusty') {

        if( versioncmp($::kernelrelease, '3.13.0-49') < 0 ) {

            fail("nova-compute not installed on buggy kernels")

        } else {

            package { [ 'nova-compute', 'nova-compute-kvm' ]:
                ensure  => present,
                require => [Class['openstack::repo'], Package['qemu-system']],
            }

        }
    }

    # Without qemu-system, apt will install qemu-kvm by default,
    # which is somewhat broken.
    package { 'qemu-system':
        ensure  => present,
        require => Class['openstack::repo'],
    }

    # qemu-kvm and qemu-system are alternative packages to meet the needs of
    # libvirt.
    #  Lately, Precise has been installing qemu-kvm by default.  That's
    #  different
    #  from our old, existing servers, and it also defaults to use spice for vms
    #  even though spice is not installed.  Messy.
    package { [ 'qemu-kvm' ]:
        ensure  => absent,
        require => Package['qemu-system'],
    }

    # nova-compute adds the user with /bin/false, but resize, live migration,
    # etc.
    # need the nova use to have a real shell, as it uses ssh.
    user { 'nova':
        ensure  => present,
        shell   => '/bin/bash',
        require => Package['nova-common'],
    }

    service { 'nova-compute':
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-compute'],
    }

    file { '/etc/libvirt/qemu/networks/autostart/default.xml':
            ensure  => absent,
    }

    # Live hack to use qcow2 ephemeral base images. Need to upstream
    # a config option for this.
    if ($::lsbdistcodename == 'precise') {
        file { '/usr/share/pyshared/nova/virt/libvirt/driver.py':
            source  => "puppet:///modules/openstack/${openstack_version}/nova/virt-libvirt-driver",
            notify  => Service['nova-compute'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['nova-common'],
        }
    }
    if ($::lsbdistcodename == 'trusty') {
        file { '/usr/lib/python2.7/dist-packages/nova/virt/libvirt/driver.py':
            source  => "puppet:///modules/openstack/${openstack_version}/nova/virt-libvirt-driver",
            notify  => Service['nova-compute'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['nova-common'],
        }
    }

    nrpe::monitor_service { 'check_nova_compute_process':
        description  => 'nova-compute process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-compute'",
    }
}
