class profile::openstack::base::neutron::service(
    $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::neutron::bind_port'),
    ) {

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::neutron::service':
        version   => $version,
        active    => true,
        bind_port => $bind_port,
    }
    contain '::openstack::neutron::service'

    ferm::rule{'neutron-server-api':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}) proto tcp dport (29696) ACCEPT;",
    }
}
