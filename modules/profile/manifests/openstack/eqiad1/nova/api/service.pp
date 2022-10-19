class profile::openstack::eqiad1::nova::api::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    String $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain', {default_value => 'example.com'}),
    Boolean $public_apis = lookup('profile::openstack::eqiad1::public_apis')
) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version     => $version,
        dhcp_domain => $dhcp_domain,
        public_apis => $public_apis,
    }

    class {'::openstack::nova::api::monitor':
        active         => true,
        critical       => false,
        contact_groups => 'wmcs-team-email',
    }
}
