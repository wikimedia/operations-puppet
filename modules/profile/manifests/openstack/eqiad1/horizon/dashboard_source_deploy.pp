class profile::openstack::eqiad1::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::eqiad1::version'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $wmflabsdotorg_admin = hiera('profile::openstack::eqiad1::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::eqiad1::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::eqiad1::nova::dhcp_domain'),
    $instance_network_id = hiera('profile::openstack::eqiad1::horizon::instance_network_id'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::eqiad1::horizon::webserver_hostname'),
    $all_regions = hiera('profile::openstack::eqiad1::all_regions'),
    $maintenance_mode = hiera('profile::openstack::eqiad1::horizon::maintenance_mode'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        version             => $version,
        keystone_host       => $keystone_host,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        instance_network_id => $instance_network_id,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
        all_regions         => $all_regions,
        maintenance_mode    => $maintenance_mode,
    }
}
