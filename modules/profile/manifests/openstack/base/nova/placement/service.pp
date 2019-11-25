class profile::openstack::base::nova::placement::service(
    String $version = lookup('profile::openstack::base::version'),
    String $region = lookup('profile::openstack::base::region'),
    Stdlib::Port $placement_api_port = lookup('profile::openstack::base::nova::placement_api_port'),
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')

    class {'::openstack::nova::placement::service':
        version            => $version,
        active             => true,
        placement_api_port => $placement_api_port,
    }
    contain '::openstack::nova::placement::service'

    ferm::rule{'nova_placement_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks}) proto tcp dport (8778) ACCEPT;",
    }
}
