class profile::openstack::base::haproxy(
    $logging = lookup('profile::openstack::base::haproxy::logging', {'default_value' => true}),
) {
    class { 'haproxy':
        logging => $logging,
    }
}
