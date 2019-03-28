class openstack::nova::api::service::mitaka
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    package { 'nova-api':
        ensure => 'present',
    }

    # TEMP HOTPATCH for T198950
    file { '/usr/lib/python2.7/dist-packages/nova/api/manager.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/mitaka/nova/api/manager.py',
        require => Package['nova-api'],
    }
}
