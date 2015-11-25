class role::labs::openstack::glance::server {

    system::role { $name: }

    class { 'openstack::glance::service':
        active_server  => hiera('labs_nova_controller'),
        standby_server => hiera('labs_nova_controller_spare'),
        keystone_host  => hiera('labs_keystone_host'),
        glanceconfig   => hiera_hash('glanceconfig', {}),
        keystoneconfig => hiera_hash('keystoneconfig', {}),
    }
}
