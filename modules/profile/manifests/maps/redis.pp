class profile::maps::redis {
    system::role { 'profile::maps::redis':
        ensure      => 'present',
        description => 'Maps redis server',
    }

    $maps_hosts = hiera('maps::hosts')
    $maps_hosts_ferm = join($maps_hosts, ' ')

    redis::instance { '6379':
        settings => { 'bind' => '0.0.0.0' },
    }

    ferm::service { 'tilerator_redis':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${maps_hosts_ferm}))",
    }

}