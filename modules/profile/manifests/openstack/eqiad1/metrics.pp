class profile::openstack::eqiad1::metrics (
) {
    class { '::profile::prometheus::openstack_exporter':
        listen_port => 12345,
        cloud       => 'eqiad1',
    }
    contain '::profile::prometheus::openstack_exporter'
}
