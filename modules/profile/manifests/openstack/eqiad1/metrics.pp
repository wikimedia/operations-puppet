class profile::openstack::eqiad1::metrics (
    Stdlib::Fqdn $controller = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
) {
    $this_ip = ipresolve($::fqdn, 4)
    $controller_ip = ipresolve($controller, 4)

    if $this_ip == $controller_ip {
        class { '::profile::prometheus::openstack_exporter':
            listen_port => 12345,
            cloud       => 'eqiad1',
        }
        contain '::profile::prometheus::openstack_exporter'
    } else {
        class { '::profile::prometheus::openstack_exporter':
            ensure => absent,
        }
    }
}
