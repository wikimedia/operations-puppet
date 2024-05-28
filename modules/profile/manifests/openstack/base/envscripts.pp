# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::envscripts(
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $region = lookup('profile::openstack::base::region'),
    $nova_db_pass = lookup('profile::openstack::base::nova::db_pass'),
    $wmflabsdotorg_admin = lookup('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $wmflabsdotorg_project = lookup('profile::openstack::base::designate::wmflabsdotorg_project'),
    $osstackcanary_pass = lookup('profile::openstack::base::nova::fullstack_pass'),
) {
    $root_clouds_file = '/root/.config/openstack/clouds.yaml'

    # Specify the novaadmin user in the 'admin' project. This gets us
    #  a project-scoped token
    openstack::util::envscript { 'novaadmin':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25357,
        keystone_api_interface => 'admin',
        os_user                => 'novaadmin',
        os_password            => $ldap_user_pass,
        os_project             => 'admin',
        os_db_password         => $nova_db_pass,
        scriptpath             => '/root/novaenv.sh',
        yaml_mode              => '0440',
        clouds_files           => [$root_clouds_file],
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
    }

    #  system-scoped token:
    openstack::util::envscript { 'ossystemadmin':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25357,
        keystone_api_interface => 'admin',
        os_user                => 'novaadmin',
        os_password            => $ldap_user_pass,
        os_db_password         => $nova_db_pass,
        scriptpath             => '/root/ossystemenv.sh',
        yaml_mode              => '0440',
        clouds_files           => [$root_clouds_file],
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
        os_system_scope        => 'all',
    }

    openstack::util::envscript { 'wmflabsorg-domainadminenv':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25357,
        keystone_api_interface => 'admin',
        os_user                => $wmflabsdotorg_admin,
        os_password            => $wmflabsdotorg_project,
        os_project             => $wmflabsdotorg_project,
        scriptpath             => '/root/wmflabsorg-domainadminenv.sh',
        yaml_mode              => '0440',
        clouds_files           => [$root_clouds_file],
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
    }

    # Creds for a mortal user with membership only in select projects.
    # Will be used for policy tests.
    openstack::util::envscript { 'oss-canary':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25000,
        os_password            => $osstackcanary_pass,
        keystone_api_interface => 'public',
        os_user                => 'osstackcanary',
        os_project             => 'admin-monitoring',
        scriptpath             => '/usr/local/bin/osscanaryenv.sh',
        yaml_mode              => '0440',
        clouds_files           => [$root_clouds_file],
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
    }
}
