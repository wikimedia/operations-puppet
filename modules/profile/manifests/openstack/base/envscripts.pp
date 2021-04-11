class profile::openstack::base::envscripts(
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $region = lookup('profile::openstack::base::region'),
    $nova_db_pass = lookup('profile::openstack::base::nova::db_pass'),
    $wmflabsdotorg_admin = lookup('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = lookup('profile::openstack::base::designate::wmflabsdotorg_project'),
    ) {

    openstack::util::envscript { 'novaadmin':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 35357,
        keystone_api_interface => 'admin',
        os_user                => 'novaadmin',
        os_password            => $ldap_user_pass,
        os_project             => 'admin',
        os_db_password         => $nova_db_pass,
        scriptpath             => '/usr/local/bin/novaenv.sh',
        yaml_mode              => '0440',
    }

    openstack::util::envscript { 'wmflabsorg-domainadminenv':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 35357,
        keystone_api_interface => 'admin',
        os_user                => $wmflabsdotorg_admin,
        os_password            => $wmflabsdotorg_project,
        os_project             => $wmflabsdotorg_project,
        scriptpath             => '/root/wmflabsorg-domainadminenv.sh',
        yaml_mode              => '0440',
    }
}
