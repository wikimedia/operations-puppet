# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::cinder(
    String $version = lookup('profile::openstack::base::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $region = lookup('profile::openstack::base::region'),
    String $db_user = lookup('profile::openstack::base::cinder::db_user'),
    String $db_name = lookup('profile::openstack::base::cinder::db_name'),
    String $db_pass = lookup('profile::openstack::base::cinder::db_pass'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::cinder::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::cinder::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::base::cinder::ceph_pool'),
    String $rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    String $rabbit_pass = lookup('profile::openstack::base::nova::rabbit_pass'),
    String $libvirt_rbd_cinder_uuid = lookup('profile::cloudceph::client::rbd::libvirt_rbd_cinder_uuid'),
    Hash   $cinder_backup_volumes = lookup('profile::openstack::base::cinder_backup_volumes'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    Boolean $active = lookup('profile::openstack::base::cinder_active'),
    String              $ceph_rbd_client_name  = lookup('profile::openstack::base::cinder::ceph_rbd_client_name'),
    Array[Stdlib::Fqdn] $haproxy_nodes         = lookup('profile::openstack::base::haproxy_nodes'),
    Array[String]       $all_backend_names     = lookup('profile::openstack::base::cinder::all_backend_names'),
    String[1]           $backend_type          = lookup('profile::openstack::base::cinder::backend_type'),
    String[1]           $backend_name          = lookup('profile::openstack::base::cinder::backend_name'),
    Array[Stdlib::Fqdn] $cinder_volume_nodes   = lookup('profile::openstack::base::cinder_volume_nodes'),
    ) {

    class { "::openstack::cinder::config::${version}":
        memcached_nodes             => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes              => $rabbitmq_nodes,
        keystone_fqdn               => $keystone_fqdn,
        region                      => $region,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        ceph_pool                   => $ceph_pool,
        ceph_rbd_client_name        => $ceph_rbd_client_name,
        api_bind_port               => $api_bind_port,
        ldap_user_pass              => $ldap_user_pass,
        rabbit_user                 => $rabbit_user,
        rabbit_pass                 => $rabbit_pass,
        libvirt_rbd_cinder_uuid     => $libvirt_rbd_cinder_uuid,
        all_backend_names           => $all_backend_names,
        backend_type                => $backend_type,
        backend_name                => $backend_name,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    class { '::openstack::cinder::service':
        version               => $version,
        active                => $active,
        api_bind_port         => $api_bind_port,
        cinder_backup_volumes => $cinder_backup_volumes,
    }

    class { '::openstack::cinder::monitor':
    }

    ferm::service { 'cinder-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }

    openstack::db::project_grants { 'cinder':
        access_hosts => $haproxy_nodes + $cinder_volume_nodes,
        db_name      => 'cinder',
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['cinder-api'],
    }

    if debian::codename::eq('bullseye') {
        grub::bootparam { 'disable_unified_cgroup_hierarchy':
            key   => 'systemd.unified_cgroup_hierarchy',
            value => '0',
        }
        grub::bootparam { 'disable_legacy_systemd_cgroup_controller':
            key   => 'systemd.legacy_systemd_cgroup_controller',
            value => '0',
        }
    }
}
