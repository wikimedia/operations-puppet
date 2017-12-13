class profile::openstack::labtest::horizon::dashboard(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $wmflabsdotorg_admin = hiera('profile::openstack::labtest::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::labtest::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::labtest::nova::dhcp_domain'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::labtest::horizon::webserver_hostname'),
    ) {

    require ::profile::openstack::labtest::clientlib
    class {'::profile::openstack::base::horizon::dashboard':
        version             => $version,
        nova_controller     => $nova_controller,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
    }
    contain '::profile::openstack::base::horizon::dashboard'
}
