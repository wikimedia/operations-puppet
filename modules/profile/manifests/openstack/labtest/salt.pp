class profile::openstack::labtest::salt(
    $instance_range = hiera('profile::openstack::labtest::nova::fixed_range'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    ) {

    class {'::profile::openstack::base::salt':
        instance_range => $instance_range,
        designate_host => $designate_host,
    }
}
