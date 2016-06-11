class role::labs::ores::worker {
    include ::ores::worker
    include ::role::labs::ores::redisproxy

    ores::config { 'redis':
        config   => {
            'score_caches'     => {
                'ores_redis' => {
                    'host' => "ores-redis-01",
                    'port' => '6380',
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => "redis://ores-redis-01:6379",
                    'CELERY_RESULT_BACKEND' => "redis://ores-redis-01:6379",
                }
            }
        },
        priority => '99',
    }
}
