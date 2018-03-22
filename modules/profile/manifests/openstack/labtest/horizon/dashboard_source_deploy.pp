class profile::openstack::labtest::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $wmflabsdotorg_admin = hiera('profile::openstack::labtest::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::labtest::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::labtest::nova::dhcp_domain'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::labtest::horizon::webserver_hostname'),
    $maintenance_mode = hiera('profile::openstack::labtest::horizon::maintenance_mode'),
    ) {

    require ::profile::openstack::labtest::clientlib
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        version             => $version,
        nova_controller     => $nova_controller,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
        maintenance_mode    => $maintenance_mode,
    }
}
