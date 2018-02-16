class profile::openstack::base::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $wmflabsdotorg_admin = hiera('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::base::nova::dhcp_domain'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::base::horizon::webserver_hostname'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    ) {

    class { '::openstack::horizon::source_deploy':
        version             => $version,
        nova_controller     => $nova_controller,
        wmflabsdotorg_admin => $wmflabsdotorg_admin,
        wmflabsdotorg_pass  => $wmflabsdotorg_pass,
        dhcp_domain         => $dhcp_domain,
        ldap_user_pass      => $ldap_user_pass,
        webserver_hostname  => $webserver_hostname,
    }
    contain '::openstack::horizon::source_deploy'

    ferm::service { 'horizon_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC'
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    class { '::memcached':
    }

    ferm::service { 'horizon_memcached':
        proto  => 'tcp',
        port   => '11000',
        srange => "${labweb_ips}"
    }
}
