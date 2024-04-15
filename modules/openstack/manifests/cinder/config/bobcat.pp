# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::config::bobcat(
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String[1]           $db_user,
    String[1]           $db_pass,
    String[1]           $db_name,
    Stdlib::Fqdn        $db_host,
    String[1]           $ldap_user_pass,
    Stdlib::Fqdn        $keystone_fqdn,
    String[1]           $region,
    String[1]           $ceph_pool,
    String[1]           $ceph_rbd_client_name,
    String[1]           $rabbit_user,
    String[1]           $rabbit_pass,
    Stdlib::Port        $api_bind_port,
    String[1]           $libvirt_rbd_cinder_uuid,
    Stdlib::Unixpath    $backup_path,
    Array[String]       $all_backend_names,
    String[1]           $backend_type,
    String[1]           $backend_name,
    Boolean             $enforce_policy_scope,
    Boolean             $enforce_new_policy_defaults,
) {
    require 'openstack::cinder::user'

    file { '/etc/cinder/':
        ensure => directory,
        owner  => 'cinder',
        group  => 'cinder',
    }

    # Subtemplates of cinder.conf are going to want to know what
    #  version this is
    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    file { '/etc/cinder/cinder.conf':
        content   => template('openstack/bobcat/cinder/cinder.conf.erb'),
        owner     => 'cinder',
        group     => 'cinder',
        mode      => '0440',
        show_diff => false,
    }
}
