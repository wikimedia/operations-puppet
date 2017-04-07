class profile::maps::redis(
    $maps_hosts = hiera('profile::maps::hosts'),
) {
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
