class profile::openstack::codfw1dev::envscripts(
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $nova_db_pass = lookup('profile::openstack::codfw1dev::nova::db_pass'),
    $wmflabsdotorg_admin = lookup('profile::openstack::codfw1dev::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::codfw1dev::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = lookup('profile::openstack::codfw1dev::designate::wmflabsdotorg_project'),
    $osstackcanary_pass = lookup('profile::openstack::codfw1dev::nova::fullstack_pass'),
    ) {
    class {'::profile::openstack::base::envscripts':
        ldap_user_pass        => $ldap_user_pass,
        keystone_api_fqdn     => $keystone_api_fqdn,
        region                => $region,
        nova_db_pass          => $nova_db_pass,
        wmflabsdotorg_admin   => $wmflabsdotorg_admin,
        wmflabsdotorg_pass    => $wmflabsdotorg_pass,
        wmflabsdotorg_project => $wmflabsdotorg_project,
        osstackcanary_pass    => $osstackcanary_pass,
    }
}
