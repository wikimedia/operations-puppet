class role::labs::ores::staging {
    class { 'ores::base':
        branch => 'master',
    }

    include ::ores::web
    include ::ores::worker
    include ::ores::flower

    include ::role::labs::ores::lb

    class { '::ores::redis':
        cache_maxmemory => '512M',
        queue_maxmemory => '256M',
    }

    ores::config { 'staging':
        config   => {
            'score_caches'     => {
                'ores_redis' => {
                    'host' => '127.0.0.1',
                    'port' => '6380',
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => 'redis://127.0.0.1:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://127.0.0.1:6379',
                }
            }
        },
        priority => '99',
    }
}
