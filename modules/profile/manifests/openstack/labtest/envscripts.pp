class profile::openstack::labtest::envscripts(
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $keystone_host = hiera('profile::openstack::labtest::keystone_host'),
    $region = hiera('profile::openstack::labtest::region'),
    $nova_db_pass = hiera('profile::openstack::labtest::nova::db_pass'),
    $wmflabsdotorg_admin = hiera('profile::openstack::labtest::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::labtest::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::labtest::designate::wmflabsdotorg_project'),
    ) {
    class {'::profile::openstack::base::envscripts':
        ldap_user_pass        => $ldap_user_pass,
        nova_controller       => $nova_controller,
        keystone_host         => $keystone_host,
        region                => $region,
        nova_db_pass          => $nova_db_pass,
        wmflabsdotorg_admin   => $wmflabsdotorg_admin,
        wmflabsdotorg_pass    => $wmflabsdotorg_pass,
        wmflabsdotorg_project => $wmflabsdotorg_project,
    }
}
