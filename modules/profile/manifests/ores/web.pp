class profile::ores::web(
    $redis_host = hiera('profile::ores::web::redis_host'),
    $redis_password = hiera('profile::ores::web::redis_password'),
){
    class { '::ores::web':
        redis_password => $redis_password,
        redis_host     => $redis_host,
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
