class role::labs::ores::worker {
    include ::ores::worker
    include ::role::labs::ores::redisproxy

    file { '/etc/ores/':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0644',
    }

    ores::config { 'redis':
        config   => {
            'score_caches'    => {
                'ores_redis' => {
                    'host' => 'ores-redis-01',
                    'port' => '6380',
                }
            },
            'scoring_systems' => {
                'celery_queue' => {
                    'BROKER_URL'            => 'redis://ores-redis-01:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://ores-redis-01:6379',
                }
            }
        },
        priority => '99',
    }
}
