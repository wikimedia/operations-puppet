class profile::openstack::base::cinder::backup (
    String[1]               $version                 = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn]     $openstack_controllers   = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn]     $rabbitmq_nodes          = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn            $keystone_fqdn           = lookup('profile::openstack::base::keystone_api_fqdn'),
    String[1]               $region                  = lookup('profile::openstack::base::region'),
    String[1]               $db_user                 = lookup('profile::openstack::base::cinder::db_user'),
    String[1]               $db_name                 = lookup('profile::openstack::base::cinder::db_name'),
    String[1]               $db_pass                 = lookup('profile::openstack::base::cinder::db_pass'),
    String[1]               $ldap_user_pass          = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn            $db_host                 = lookup('profile::openstack::base::cinder::db_host'),
    Stdlib::Port            $api_bind_port           = lookup('profile::openstack::base::cinder::api_bind_port'),
    String[1]               $ceph_pool               = lookup('profile::openstack::base::cinder::ceph_pool'),
    String[1]               $ceph_rbd_client_name    = lookup('profile::openstack::base::cinder::ceph_rbd_client_name'),
    String[1]               $rabbit_user             = lookup('profile::openstack::base::nova::rabbit_user'),
    String[1]               $rabbit_pass             = lookup('profile::openstack::base::nova::rabbit_pass'),
    Boolean                 $enforce_policy_scope    = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean                 $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    String[1]               $libvirt_rbd_cinder_uuid = lookup('profile::cloudceph::client::rbd::libvirt_rbd_cinder_uuid'),
    Boolean                 $active                  = lookup('profile::openstack::base::cinder::backup::active'),
    Stdlib::Unixpath        $backup_path             = lookup('profile::openstack::base::cinder::backup::path'),
    Array[Stdlib::Unixpath] $lvm_pv_units            = lookup('profile::openstack::base::cinder::backup::lvm::pv_units'),
    String[1]               $lvm_vg_name             = lookup('profile::openstack::base::cinder::backup::lvm::vg_name'),
    String[1]               $lvm_lv_name             = lookup('profile::openstack::base::cinder::backup::lvm::lv_name'),
    String[1]               $lvm_lv_size             = lookup('profile::openstack::base::cinder::backup::lvm::lv_size'),
    String[1]               $lvm_lv_format           = lookup('profile::openstack::base::cinder::backup::lvm::lv_format'),
    String[1]               $user                    = lookup('profile::openstack::base::cinder::backup::user'),
    Boolean                 $vg_createonly           = lookup('profile::openstack::base::cinder::backup::vg_createonly'),
    Array[String]           $all_backend_names       = lookup('profile::openstack::base::cinder::all_backend_names'),
    String[1]               $backend_type            = lookup('profile::openstack::base::cinder::backend_type'),
    String[1]               $backend_name            = lookup('profile::openstack::base::cinder::backend_name'),
) {
    class { "::openstack::cinder::config::${version}":
        memcached_nodes             => $openstack_controllers,
        keystone_fqdn               => $keystone_fqdn,
        rabbitmq_nodes              => $rabbitmq_nodes,
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
        backup_path                 => $backup_path,
        all_backend_names           => $all_backend_names,
        backend_type                => $backend_type,
        backend_name                => $backend_name,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    class { 'openstack::cinder::backup':
        version => $version,
        active  => $active,
    }

    ensure_packages(['lvm2'])

    lvm::volume { $lvm_lv_name :
        ensure     => present,
        vg         => $lvm_vg_name,
        pv         => $lvm_pv_units,
        fstype     => $lvm_lv_format,
        size       => $lvm_lv_size,
        createonly => $vg_createonly
    }

    file { $backup_path :
        ensure => directory,
        owner  => $user,
        mode   => '0750'
    }

    mount { $backup_path :
        ensure  => mounted,
        device  => "/dev/${lvm_vg_name}/${lvm_lv_name}",
        fstype  => $lvm_lv_format,
        options => 'defaults',
        atboot  => true,
        require => [Lvm::Volume[$lvm_lv_name], File[$backup_path]],
    }
}
