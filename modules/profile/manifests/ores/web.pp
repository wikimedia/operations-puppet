# SPDX-License-Identifier: Apache-2.0
class profile::ores::web(
    Stdlib::Host $redis_host = lookup('profile::ores::web::redis_host'),
    Stdlib::Port $redis_queue_port = lookup('profile::ores::web::redis_queue_port', {'default_value' => 6379}),
    Stdlib::Port $redis_cache_port = lookup('profile::ores::web::redis_cache_port', {'default_value' => 6380}),
    Optional[String] $redis_password = lookup('profile::ores::web::redis_password', {'default_value' => undef}),
    Integer $web_workers = lookup('profile::ores::web::workers'),
    Integer $celery_workers = lookup('profile::ores::celery::workers'),
    Integer $celery_queue_maxsize = lookup('profile::ores::celery::queue_maxsize'),
    Array[String] $poolcounter_nodes = lookup('profile::ores::web::poolcounter_nodes'),
    Stdlib::Host $logstash_host = lookup('profile::ores::logstash_host'),
    Stdlib::Port $logstash_port = lookup('logstash_json_lines_port', {'default_value' => 11514}),
    String $statsd = lookup('statsd'),
    String $ores_config_user = lookup('profile::ores::web::ores_config_user', {'default_value' => 'deploy-service'}),
    String $ores_config_group = lookup('profile::ores::web::ores_config_group', {'default_value' => 'deploy-service'}),
    Integer $celery_version = lookup('profile::ores::web::celery_version', {'default_value' => 5 }),
){
    require profile::ores::git

    $statsd_parts = split($statsd, ':')

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { '::profile::rsyslog::udp_json_logback_compat':
        port => $logstash_port,
    }

    class { '::ores::web':
        redis_password       => $redis_password,
        redis_host           => $redis_host,
        redis_queue_port     => $redis_queue_port,
        redis_cache_port     => $redis_cache_port,
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
        celery_version       => $celery_version,
    }

    ferm::service { 'ores':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }

    $min_crit = $celery_workers - 2
    $max_crit = $celery_workers + 2
    nrpe::monitor_service { 'ores_workers':
        description  => 'ores_workers_running',
        retries      => 10,
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -C celery -c ${min_crit}:${max_crit}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/ORES',
    }
}
