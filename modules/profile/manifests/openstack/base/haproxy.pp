class profile::openstack::base::haproxy(
    Boolean $logging = lookup('profile::openstack::base::haproxy::logging'),
) {
    class { 'haproxy':
        logging  => $logging,
        template => 'profile/openstack/base/haproxy/haproxy.cfg.erb',
    }
}
