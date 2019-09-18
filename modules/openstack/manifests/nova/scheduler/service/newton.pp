class openstack::nova::scheduler::service::newton
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }

    file { '/usr/lib/python2.7/dist-packages/nova/scheduler/filters/scheduler_pool_filter.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openstack/newton/nova/scheduler/scheduler_pool_filter.py',
        notify  => Service['nova-scheduler'],
        require => Package['nova-scheduler'],
    }
}
