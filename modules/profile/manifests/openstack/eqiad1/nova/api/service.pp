class profile::openstack::eqiad1::nova::api::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    $labs_hosts_range = lookup('profile::openstack::eqiad1::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::eqiad1::labs_hosts_range_v6'),
    String $dhcp_domain               = lookup('profile::openstack::eqiad1::nova::dhcp_domain',
                                                {default_value => 'example.com'}),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
        dhcp_domain         => $dhcp_domain,
    }

    class {'::openstack::nova::api::monitor':
        active         => true,
        critical       => false,
        contact_groups => 'wmcs-team-email',
    }
}
