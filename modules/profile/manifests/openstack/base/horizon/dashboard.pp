class profile::openstack::base::horizon::dashboard(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $wmflabsdotorg_admin = hiera('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::base::nova::dhcp_domain'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::base::horizon::webserver_hostname'),
    ) {

    # TODO: Add openstack::util::envscripts during profile conversion
    class { '::openstack::horizon::service':
        version             => $version,
        nova_controller     => $nova_controller,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
    }
    contain '::openstack::horizon::service'

    #   require => Class['openstack::horizon::service'],
    class {'::openstack::horizon::puppetpanel':
        version => $version,
    }
    contain '::openstack::horizon::puppetpanel'

    ferm::service { 'horizon_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC'
    }
}
