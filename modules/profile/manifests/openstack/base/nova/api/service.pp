class profile::openstack::base::nova::api::service(
    $version = hiera('profile::openstack::base::version'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::base::labs_hosts_range_v6')
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::nova::api::service':
        version => $version,
        active  => true,
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

    # Allow neutron hosts to access the metadata service
    ferm::rule{'nova_metadata_labs_hosts_v6':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range_v6} proto tcp dport 8775 ACCEPT;",
    }
}
