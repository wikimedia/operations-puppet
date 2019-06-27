# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::service(
    $version,
    $certpath,
    $all_cloudvirts,
    ){

    # jessie: libvirt:x:121:nova
    # stretch: libvirt:x:121:nova
    $libvirt_unix_sock_group = $::facts['lsbdistcodename'] ? {
        'jessie'  => 'libvirt',
        'stretch' => 'libvirt',
    }

    class { "openstack::nova::compute::service::${version}::${::lsbdistcodename}":
    }

    include openstack::nova::compute::kmod

    # use exec to set the shell to not shadow the manage
    # the user for the package which causes Puppet
    # to see the user as a dependency anywhere the
    # nova user is used to ensure good permission
    exec {'set_shell_for_nova':
        command   => '/usr/sbin/usermod -c "shell set for online operations" -s /bin/bash nova',
        unless    => '/bin/grep "nova:" /etc/passwd | /bin/grep ":\/bin\/bash"',
        logoutput => true,
        require   => Package['nova-compute'],
    }

    ssh::userkey { 'nova':
        content => secret('ssh/nova/nova.pub'),
        require => Exec['set_shell_for_nova'],
    }

    file { '/var/lib/nova/.ssh':
        ensure  => 'directory',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0700',
        require => Package['nova-compute'],
    }

    file { '/var/lib/nova/.ssh/id_rsa':
        owner     => 'nova',
        group     => 'nova',
        mode      => '0600',
        content   => secret('ssh/nova/nova.key'),
        require   => File['/var/lib/nova/.ssh'],
        show_diff => false,
    }

    file { '/var/lib/nova/.ssh/id_rsa.pub':
        owner   => 'nova',
        group   => 'nova',
        mode    => '0600',
        content => secret('ssh/nova/nova.pub'),
        require => File['/var/lib/nova/.ssh'],
    }

    service { 'nova-compute':
        ensure    => 'running',
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/nova-compute.conf'],
            ],
        require   => Package['nova-compute'],
    }

    # Guest management on host startup/reboot
    if os_version('debian >= stretch') {

        file { '/etc/default/libvirt-guests':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/openstack/nova/libvirt/libvirt-guests',
        }

        service { 'libvirt-guests':
            ensure => 'running',
            enable => true,
        }
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

    file { '/etc/libvirt/libvirtd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openstack/mitaka/nova/compute/libvirtd.conf.erb'),
        notify  => Service['libvirtd'],
        require => [Package['nova-compute'], File['/var/lib/nova/cacert.pem']]
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
