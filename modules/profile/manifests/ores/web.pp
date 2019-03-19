class profile::ores::web(
    $redis_host = hiera('profile::ores::web::redis_host'),
    $redis_password = hiera('profile::ores::web::redis_password'),
    $web_workers = hiera('profile::ores::web::workers'),
    $celery_workers = hiera('profile::ores::celery::workers'),
    $celery_queue_maxsize = hiera('profile::ores::celery::queue_maxsize'),
    $poolcounter_nodes = hiera('profile::ores::web::poolcounter_nodes'),
    $logstash_host = hiera('profile::ores::logstash_host'),
    $logstash_port = hiera('logstash_json_lines_port', 11514),
){

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { '::profile::rsyslog::udp_json_logback_compat':
        port => $logstash_port,
    }

    class { '::ores::web':
        redis_password       => $redis_password,
        redis_host           => $redis_host,
        web_workers          => $web_workers,
        celery_workers       => $celery_workers,
        celery_queue_maxsize => $celery_queue_maxsize,
        poolcounter_nodes    => $poolcounter_nodes,
        logstash_host        => $logstash_host,
        logstash_port        => $logstash_port,
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
