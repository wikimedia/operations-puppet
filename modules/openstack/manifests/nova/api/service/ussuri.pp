class openstack::nova::api::service::ussuri(
    Stdlib::Port $api_bind_port,
    Stdlib::Port $metadata_bind_port,
) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ussuri::${::lsbdistcodename}"

    package { 'nova-api':
        ensure => 'present',
    }

    file { '/etc/init.d/nova-api':
        content => template('openstack/ussuri/nova/api/nova-api'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api'],
        require => Package['nova-api'];
    }

    # Hack in regex validation for instance names.
    #  Context can be found in T207538
    file { '/usr/lib/python3/dist-packages/nova/api/openstack/compute/servers.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/ussuri/nova/hacks/servers.py',
        require => Package['nova-api'];
    }

    file { '/etc/init.d/nova-api-metadata':
        content => template('openstack/ussuri/nova/api/nova-api-metadata'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api-metadata'],
        require => Package['nova-api'];
    }
    service { 'nova-api-metadata':
        ensure    => 'running',
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.yaml'],
            ],
        require   => Package['nova-api'];
    }
}
