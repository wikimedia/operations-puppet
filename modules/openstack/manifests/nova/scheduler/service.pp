# openstack scheduler determines on which host a
# particular instance should run
class openstack::nova::scheduler::service(
    $active,
    $version,
    ){

    class { "openstack::nova::scheduler::service::${version}": }

    service { 'nova-scheduler':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-scheduler'];
    }
}
