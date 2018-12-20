# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::service(
    $version,
    $libvirt_type,
    $certname,
    $ca_target,
    ){

    # trusty: libvirtd:x:117:nova
    # jessie: libvirt:x:121:nova
    # stretch: libvirt:x:121:nova
    $libvirt_unix_sock_group = $facts['lsbdistcodename'] ? {
        'trusty'  => 'libvirtd',
        'jessie'  => 'libvirt',
        'stretch' => 'libvirt',
    }

    class { "openstack::nova::compute::service::${version}::${::lsbdistcodename}":
        libvirt_type            => $libvirt_type,
        certname                => $certname,
        ca_target               => $ca_target,
        libvirt_unix_sock_group => $libvirt_unix_sock_group,
    }

    require openstack::nova::compute::audit
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

    sslcert::certificate { $certname: }

    file { "/var/lib/nova/${certname}.key":
        owner     => 'nova',
        group     => $libvirt_unix_sock_group,
        mode      => '0440',
        content   => secret("ssl/${certname}.key"),
        require   => Package['nova-compute'],
        show_diff => false,
    }

    file { '/var/lib/nova/clientkey.pem':
        ensure => link,
        target => "/var/lib/nova/${certname}.key",
    }

    file { '/var/lib/nova/clientcert.pem':
        ensure  => link,
        target  => "/etc/ssl/localcerts/${certname}.crt",
        require => Sslcert::Certificate[$certname],
    }

    file { '/var/lib/nova/cacert.pem':
        ensure  => link,
        target  => $ca_target,
        require => Sslcert::Certificate[$certname],
    }

    service { 'nova-compute':
        ensure    => 'running',
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/nova-compute.conf'],
            ],
        require   => Package['nova-compute'],
    }
}
