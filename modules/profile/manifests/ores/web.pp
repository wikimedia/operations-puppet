class profile::ores::web(
    $redis_host = hiera('profile::ores::web::redis_host'),
    $redis_password = hiera('profile::ores::web::redis_password'),
    $web_workers = hiera('profile::ores::web::workers', 48),
    $celery_workers = hiera('profile::ores::celery::workers', 45),
    $celery_queue_maxsize = hiera('profile::ores::celery::queue_maxsize', 100),
){
    class { '::ores::web':
        redis_password       => $redis_password,
        redis_host           => $redis_host,
        web_workers          => $web_workers,
        celery_workers       => $celery_workers,
        celery_queue_maxsize => $celery_queue_maxsize
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
