class profile::openstack::eqiad1::pdns::recursor::secondary(
    $pdns_host = hiera('profile::openstack::eqiad1::pdns::host_secondary'),
    $pdns_recursor = hiera('profile::openstack::eqiad1::pdns::recursor_secondary'),
    ) {

    class {'::profile::openstack::eqiad1::pdns::recursor::service':
        pdns_host     => $pdns_host,
        pdns_recursor => $pdns_recursor,
    }
}
