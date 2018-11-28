class profile::openstack::main::keystone::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $keystone_host = hiera('profile::openstack::main::keystone_host'),
    $nova_db_pass = hiera('profile::openstack::main::nova::db_pass'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $wmflabsdotorg_admin = hiera('profile::openstack::main::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::main::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::main::designate::wmflabsdotorg_project'),
    $region = hiera('profile::openstack::main::region'),
    ) {

    require ::profile::openstack::main::clientpackages

    class {'::openstack::util::envscripts':
        ldap_user_pass        => $ldap_user_pass,
        nova_controller       => $nova_controller,
        keystone_host         => $keystone_host,
        region                => $region,
        nova_db_pass          => $nova_db_pass,
        wmflabsdotorg_admin   => $wmflabsdotorg_admin,
        wmflabsdotorg_pass    => $wmflabsdotorg_pass,
        wmflabsdotorg_project => $wmflabsdotorg_project,
    }
    contain '::openstack::util::envscripts'

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'
}
