class profile::openstack::base::cinder(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
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
    String $libvirt_rbd_cinder_uuid = lookup('profile::ceph::client::rbd::libvirt_rbd_cinder_uuid'),
    Hash   $cinder_backup_volumes = lookup('profile::openstack::base::cinder_backup_volumes'),
    Boolean $active = lookup('profile::openstack::base::cinder_active'),
    Stdlib::Unixpath    $backup_path           = lookup('profile::openstack::base::cinder::backup::path'),
    String              $ceph_rbd_client_name  = lookup('profile::openstack::base::cinder::ceph_rbd_client_name'),
    ) {

    $keystone_admin_uri = "https://${keystone_fqdn}:${auth_port}"

    class { "::openstack::cinder::config::${version}":
        openstack_controllers   => $openstack_controllers,
        rabbitmq_nodes          => $rabbitmq_nodes,
        keystone_admin_uri      => $keystone_admin_uri,
        region                  => $region,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ceph_pool               => $ceph_pool,
        ceph_rbd_client_name    => $ceph_rbd_client_name,
        api_bind_port           => $api_bind_port,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        libvirt_rbd_cinder_uuid => $libvirt_rbd_cinder_uuid,
        backup_path             => $backup_path,
    }

    class { '::openstack::cinder::service':
        version               => $version,
        active                => $active,
        api_bind_port         => $api_bind_port,
        cinder_backup_volumes => $cinder_backup_volumes,
    }

    class { '::openstack::cinder::monitor':
        active                => $active,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'cinder_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (28776) ACCEPT;",
    }

    openstack::db::project_grants { 'cinder':
        access_hosts => $openstack_controllers,
        db_name      => 'cinder',
        db_user      => $db_user,
        db_pass      => $db_pass,
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
