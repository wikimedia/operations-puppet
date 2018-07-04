# openstack scheduler determines on which host a
# particular instance should run
class openstack::nova::scheduler::service(
    $active,
    $version,
    ){

    if os_version('debian jessie') and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package { 'nova-scheduler':
        ensure          => 'present',
        install_options => $install_options,
    }

    file { '/usr/lib/python2.7/dist-packages/nova/scheduler/filters/scheduler_pool_filter.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openstack/${version}/nova/scheduler/scheduler_pool_filter.py",
        notify  => Service['nova-scheduler'],
        require => Package['nova-scheduler'],
    }

    service { 'nova-scheduler':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-scheduler'];
    }
}
