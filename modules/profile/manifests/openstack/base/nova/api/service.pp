class profile::openstack::base::nova::api::service(
    $version = lookup('profile::openstack::base::version'),
    String $region = lookup('profile::openstack::base::region'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::nova::osapi_compute_listen_port'),
    Stdlib::Port $metadata_bind_port = lookup('profile::openstack::base::nova::metadata_listen_port'),
    String       $dhcp_domain               = lookup('profile::openstack::base::nova::dhcp_domain',
                                                      {default_value => 'example.com'}),
    Integer      $compute_workers = lookup('profile::openstack::base::nova::compute_workers'),
    ) {

    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')

    class {'::openstack::nova::api::service':
        version            => $version,
        active             => true,
        api_bind_port      => $api_bind_port,
        metadata_bind_port => $metadata_bind_port,
        dhcp_domain        => $dhcp_domain,
        compute_workers    => $compute_workers,
    }
    contain '::openstack::nova::api::service'

    ferm::rule{'nova_api_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8774 28774) ACCEPT;",
    }

    $nova_hosts_ranges = $::network::constants::cloud_nova_hosts_ranges[$region]

    # Allow neutron hosts to access the metadata service
    # TODO: check if this is used by neutron only (as the comment above claims), and if so,
    # update this firewall rule to only permit traffic from the neutron hosts
    ferm::service { 'nova-metadata-nova-hosts':
        proto  => 'tcp',
        port   => '8775',
        srange => "(${nova_hosts_ranges.join(' ')})",
    }
}
