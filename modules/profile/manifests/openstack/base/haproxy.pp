class profile::openstack::base::haproxy(
    Boolean $logging = lookup('profile::openstack::base::haproxy::logging'),
) {
    include ::profile::prometheus::haproxy_exporter

    class { 'haproxy':
        logging  => $logging,
        template => 'profile/openstack/base/haproxy/haproxy.cfg.erb',
    }
}
