class profile::openstack::main::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $wmflabsdotorg_admin = hiera('profile::openstack::main::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::main::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::main::nova::dhcp_domain'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::main::horizon::webserver_hostname'),
    ) {

    require ::profile::openstack::main::clientlib
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        version             => $version,
        nova_controller     => $nova_controller,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
    }
}
