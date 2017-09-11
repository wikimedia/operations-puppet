# openstack scheduler determines on which host a
# particular instance should run
class openstack2::nova::scheduler::service(
    $active,
    $version,
){

    require openstack2::nova::common
    package { 'nova-scheduler':
        ensure  => 'present',
    }

    file { '/usr/lib/python2.7/dist-packages/nova/scheduler/filters/scheduler_pool_filter.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openstack2/${version}/nova/scheduler/scheduler_pool_filter.py",
        notify  => Service['nova-scheduler'],
        require => Package['nova-scheduler'],
    }

    service { 'nova-scheduler':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-scheduler'];
    }
}
