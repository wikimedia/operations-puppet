class profile::openstack::eqiad1::radosgw (
    String              $version       = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
) {
    class { '::profile::openstack::base::radosgw':
        version       => $version,
        haproxy_nodes => $haproxy_nodes,
    }
}
