class profile::openstack::base::nova::placement::service(
    String $version = lookup('profile::openstack::base::version'),
    String $region = lookup('profile::openstack::base::region'),
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')

    class {'::openstack::nova::placement::service':
        version => $version,
        active  => true,
    }
    contain '::openstack::nova::placement::service'

    ferm::rule{'nova_placement_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks}) proto tcp dport (8779) ACCEPT;",
    }
}
