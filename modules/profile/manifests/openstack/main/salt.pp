class profile::openstack::main::salt(
    $instance_range = hiera('profile::openstack::main::nova::fixed_range'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    ) {

    class {'::profile::openstack::base::salt':
        instance_range => $instance_range,
        designate_host => $designate_host,
    }
}
