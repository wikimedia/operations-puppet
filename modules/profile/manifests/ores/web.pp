class profile::ores::web(
    $redis_host = hiera('profile::ores::web::redis_host'),
    $redis_password = hiera('profile::ores::web::redis_password'),
    $celery_workers = hiera('profile::ores::celery::workers', 45),
){
    class { '::ores::web':
        redis_password => $redis_password,
        redis_host     => $redis_host,
        celery_workers => $celery_workers,
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
