class openstack::nova::placement::service::ocata (
    Stdlib::Port $placement_api_port,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ocata::${::lsbdistcodename}"

    package { 'nova-placement-api':
        ensure => 'present',
    }

    file { '/etc/init.d/nova-placement-api':
        owner   => 'root',
        group   => 'root',
        mode    => '0751',
        content => template('openstack/ocata/nova/placement/nova-placement-api.erb'),
    }
}
