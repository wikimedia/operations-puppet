class profile::ores::web(
    $redis_host = hiera('profile::ores::web::redis_host'),
    $redis_password = hiera('profile::ores::web::redis_password', undef),
    $web_workers = hiera('profile::ores::web::workers'),
    $celery_workers = hiera('profile::ores::celery::workers'),
    $celery_queue_maxsize = hiera('profile::ores::celery::queue_maxsize'),
    $poolcounter_nodes = hiera('profile::ores::web::poolcounter_nodes'),
    $logstash_host = hiera('logstash_host'),
    $logstash_port = hiera('logstash_json_lines_port', 11514),
    $statsd = hiera('statsd'),
    $ores_config_user = hiera('profile::ores::web::ores_config_user', 'deploy-service'),
    $ores_config_group = hiera('profile::ores::web::ores_config_group', 'deploy-service'),
){
    $statsd_parts = split($statsd, ':')

    class { '::ores::web':
        redis_password       => $redis_password,
        redis_host           => $redis_host,
        web_workers          => $web_workers,
        celery_workers       => $celery_workers,
        celery_queue_maxsize => $celery_queue_maxsize,
        poolcounter_nodes    => $poolcounter_nodes,
        logstash_host        => $logstash_host,
        logstash_port        => $logstash_port,
        statsd_host          => $statsd_parts[0],
        statsd_port          => $statsd_parts[1],
        ores_config_user     => $ores_config_user,
        ores_config_group    => $ores_config_group,
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
