class profile::openstack::main::pdns::recursor::secondary(
    $pdns_host = hiera('profile::openstack::main::pdns::host_secondary'),
    $pdns_recursor = hiera('profile::openstack::main::pdns::recursor_secondary'),
    ) {

    class {'::profile::openstack::main::pdns::recursor::service:
        pdns_host     => $pdns_host,
        pdns_recursor => $pdns_recursor,
    }
}
