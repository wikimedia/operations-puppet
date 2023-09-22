class profile::openstack::eqiad1::metrics (
    Stdlib::Fqdn $active_host = lookup('profile::wmcs::prometheus::openstack_exporter_host'),
) {
    class { '::profile::prometheus::openstack_exporter':
        ensure      => ($active_host == $::facts['networking']['fqdn']).bool2str('present', 'absent'),
        listen_port => 12345,
        cloud       => 'eqiad1',
    }
}
