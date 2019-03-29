class profile::openstack::codfw1dev::envscripts(
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $region = hiera('profile::openstack::codfw1dev::region'),
    $nova_db_pass = hiera('profile::openstack::codfw1dev::nova::db_pass'),
    $wmflabsdotorg_admin = hiera('profile::openstack::codfw1dev::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::codfw1dev::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = hiera('profile::openstack::codfw1dev::designate::wmflabsdotorg_project'),
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
