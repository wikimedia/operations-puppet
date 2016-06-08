class role::labs::ores::worker {
    include ::ores::worker
    include ::role::labs::ores::redisproxy

    ores::config { 'redis':
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
