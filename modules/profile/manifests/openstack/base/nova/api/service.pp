class profile::openstack::base::nova::api::service(
    $version = lookup('profile::openstack::base::version'),
    $labs_hosts_range = lookup('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::base::labs_hosts_range_v6'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::nova::osapi_compute_listen_port'),
    Stdlib::Port $metadata_bind_port = lookup('profile::openstack::base::nova::metadata_listen_port'),
    String       $dhcp_domain               = lookup('profile::openstack::base::nova::dhcp_domain',
                                                      {default_value => 'example.com'}),
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::nova::api::service':
        version            => $version,
        active             => true,
        api_bind_port      => $api_bind_port,
        metadata_bind_port => $metadata_bind_port,
        dhcp_domain        => $dhcp_domain,
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
