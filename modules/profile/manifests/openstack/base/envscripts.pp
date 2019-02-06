class profile::openstack::base::envscripts(
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $region = hiera('profile::openstack::base::region'),
    $nova_db_pass = hiera('profile::openstack::base::nova::db_pass'),
    $wmflabsdotorg_admin = hiera('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::base::designate::wmflabsdotorg_project'),
    ) {

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
}
