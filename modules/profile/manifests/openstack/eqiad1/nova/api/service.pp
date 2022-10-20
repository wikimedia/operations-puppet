class profile::openstack::eqiad1::nova::api::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    String $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain', {default_value => 'example.com'}),
) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version     => $version,
        dhcp_domain => $dhcp_domain,
    }

    class {'::openstack::nova::api::monitor':
        active         => true,
        critical       => false,
        contact_groups => 'wmcs-team-email',
    }
}
