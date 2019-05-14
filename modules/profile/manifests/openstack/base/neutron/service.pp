class profile::openstack::base::neutron::service(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::base::nova_controller'),
    $version = hiera('profile::openstack::base::version'),
    ) {

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::neutron::service':
        version => $version,
        active  => ($::fqdn == $nova_controller),
    }
    contain '::openstack::neutron::service'

    ferm::rule{'neutron-server-api':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}) proto tcp dport (9696) ACCEPT;",
    }

    # restricted proxy for apt
    ferm::rule{'forward-proxy':
        ensure => 'present',
        rule   => 'saddr (172.16.128.0/21 10.196.16.0/21) proto tcp dport (5001) ACCEPT;',
    }
}
