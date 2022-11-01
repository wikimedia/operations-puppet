# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::config::yoga(
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String[1]           $db_user,
    String[1]           $db_pass,
    String[1]           $db_name,
    Stdlib::Fqdn        $db_host,
    String[1]           $ldap_user_pass,
    String[1]           $keystone_admin_uri,
    String[1]           $region,
    String[1]           $ceph_pool,
    String[1]           $ceph_rbd_client_name,
    String[1]           $rabbit_user,
    String[1]           $rabbit_pass,
    Stdlib::Port        $api_bind_port,
    String[1]           $libvirt_rbd_cinder_uuid,
    Stdlib::Unixpath    $backup_path,
) {
    require 'openstack::cinder::user'

    file { '/etc/cinder/':
        ensure => directory,
        owner  => 'cinder',
        group  => 'cinder',
    }

    file { '/etc/cinder/cinder.conf':
        content   => template('openstack/yoga/cinder/cinder.conf.erb'),
        owner     => 'cinder',
        group     => 'cinder',
        mode      => '0440',
        show_diff => false,
    }
}
