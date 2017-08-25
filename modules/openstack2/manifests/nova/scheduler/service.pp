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

    # Temp exclude
    #  notify  => Service['nova-scheduler'],
    file { '/usr/lib/python2.7/dist-packages/nova/scheduler/filters/scheduler_pool_filter.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openstack2/${version}/nova/scheduler/scheduler_pool_filter.py",
        require => Package['nova-scheduler'],
    }

    # Temp exclude
    #   subscribe => File['/etc/nova/nova.conf'],
    service { 'nova-scheduler':
        ensure    => $active,
        require   => Package['nova-scheduler'];
    }
}
