class profile::openstack::base::nova::api::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range')
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::nova::api::service':
        version => $version,
        active  => ($::fqdn == $nova_api_host),
    }
    contain '::openstack::nova::api::service'

    ferm::rule{'nova_api_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8774) ACCEPT;",
    }

    # Allow neutron hosts to access the metadata service
    ferm::rule{'nova_metadata_labs_hosts':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range} proto tcp dport 8775 ACCEPT;",
    }
}
