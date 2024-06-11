# SPDX-License-Identifier: Apache-2.0
# Access credentials for the keystone 'novaobserver' account
class profile::openstack::base::observerenv(
    String       $region            = lookup('profile::openstack::base::region'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String       $os_user           = lookup('profile::openstack::base::observer_user'),
    String       $os_password       = lookup('profile::openstack::base::observer_password'),
    String       $os_project        = lookup('profile::openstack::base::observer_project'),
  ) {

    $root_clouds_file = '/root/.config/openstack/clouds.yaml'
    wmflib::dir::mkdir_p($root_clouds_file.dirname.dirname, {'mode' => '0700'})
    wmflib::dir::mkdir_p($root_clouds_file.dirname, {'mode' => '0700'})

    concat { $root_clouds_file:
        mode      => '0400',
        show_diff => false,
    }

    concat::fragment { 'root_clouds_file_header':
        target  => $root_clouds_file,
        order   => '01',
        content => "clouds:\n",
    }

    $clouds_file = '/etc/openstack/clouds.yaml'
    ensure_resource('file', $clouds_file.dirname, { 'ensure' => 'directory',
                                                    'mode' => '0755' })
    concat { $clouds_file:
        mode      => '0444',
        show_diff => false,
    }
    concat::fragment { 'observer_clouds_file_header':
        target  => $clouds_file,
        order   => '01',
        content => inline_template('<%= "clouds:" + "\n" %>'),
    }

    openstack::util::envscript { 'novaobserver':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25000,
        keystone_api_interface => 'public',
        os_user                => $os_user,
        os_password            => $os_password,
        os_project             => $os_project,
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
        scriptpath             => '/usr/local/bin/observerenv.sh',
        yaml_mode              => '0444',
        clouds_files           => [$clouds_file, $root_clouds_file],
    }

    openstack::util::envscript { 'ossystemobserver':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 25000,
        keystone_api_interface => 'public',
        os_user                => $os_user,
        os_password            => $os_password,
        os_project_domain_id   => 'default',
        os_user_domain_id      => 'default',
        scriptpath             => '/usr/local/bin/osobserverenv.sh',
        yaml_mode              => '0444',
        clouds_files           => [$clouds_file, $root_clouds_file],
        os_system_scope        => 'all',
    }
}
