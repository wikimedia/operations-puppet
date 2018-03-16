class profile::openstack::base::neutron::service(
    $version = hiera('profile::openstack::base::version'),
    ) {

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')

    class {'::openstack::neutron::service':
        version => $version,
    }
    contain '::openstack::neutron::service'

    ferm::rule{'neutron-server-api':
        ensure => 'present',
        rule   => "saddr (${prod_networks}) proto tcp dport (9696) ACCEPT;",
    }
}
