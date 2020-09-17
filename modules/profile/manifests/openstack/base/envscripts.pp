class profile::openstack::base::envscripts(
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $region = lookup('profile::openstack::base::region'),
    $nova_db_pass = lookup('profile::openstack::base::nova::db_pass'),
    $wmflabsdotorg_admin = lookup('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = lookup('profile::openstack::base::designate::wmflabsdotorg_project'),
    ) {

    class {'::openstack::util::envscripts':
        ldap_user_pass        => $ldap_user_pass,
        keystone_api_fqdn     => $keystone_api_fqdn,
        region                => $region,
        nova_db_pass          => $nova_db_pass,
        wmflabsdotorg_admin   => $wmflabsdotorg_admin,
        wmflabsdotorg_pass    => $wmflabsdotorg_pass,
        wmflabsdotorg_project => $wmflabsdotorg_project,
    }
    contain '::openstack::util::envscripts'
}
