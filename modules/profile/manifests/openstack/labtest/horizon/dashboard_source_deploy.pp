class profile::openstack::labtest::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::labtest::version'),
    $keystone_host = hiera('profile::openstack::labtest::keystone_host'),
    $wmflabsdotorg_admin = hiera('profile::openstack::labtest::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::labtest::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::labtest::nova::dhcp_domain'),
    $instance_network_id = hiera('profile::openstack::labtest::horizon::instance_network_id'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::labtest::horizon::webserver_hostname'),
    $all_regions = hiera('profile::openstack::labtest::all_regions'),
    $maintenance_mode = hiera('profile::openstack::labtest::horizon::maintenance_mode'),
    ) {

    require ::profile::openstack::labtest::clientpackages
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
