class role::labs::openstack::keystone::server {

    system::role { $name: }

    $nova_controller   = hiera('labs_nova_controller')
    $keystoneconfig    = hiera_hash('keystoneconfig', {})

    class { 'openstack::keystone::service':
        keystoneconfig => $keystoneconfig,
    }

    $replication = {
        'labcontrol2001' => $nova_controller
    }

    class { '::redis::legacy':
        maxmemory                 => '250mb',
        persist                   => 'aof',
        redis_replication         => $replication,
        password                  => $keystoneconfig['db_pass'],
        dir                       => '/var/lib/redis/',
        auto_aof_rewrite_min_size => '64mb',
    }
}
