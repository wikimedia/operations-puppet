class openstack::nova::api::service::stein(
    Stdlib::Port $api_bind_port,
) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::stein::${::lsbdistcodename}"

    package { 'nova-api':
        ensure => 'present',
    }

    # firstboot/user_data things:
    file { '/usr/lib/python3/dist-packages/wmfnovamiddleware':
        source  => 'puppet:///modules/openstack/stein/nova/api/wmfnovamiddleware',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
    }
    file { '/etc/nova/userdata.txt':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/nova/userdata.txt',
        require => Package['nova-api'],
    }

    file { '/etc/init.d/nova-api':
        content => template('openstack/stein/nova/api/nova-api'),
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
        source  => 'puppet:///modules/openstack/stein/nova/hacks/servers.py',
        require => Package['nova-api'];
    }
}
