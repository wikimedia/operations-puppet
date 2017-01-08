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
            'score_caches'     => {
                'ores_redis' => {
                    'host' => 'ores-redis-02',
                    'port' => '6380',
                },
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => 'redis://ores-redis-02:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://ores-redis-02:6379',
                },
            },
            'scoring_systems'  => {
                'celery_queue' => {
                    'BROKER_URL'            => 'redis://ores-redis-02:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://ores-redis-02:6379',
                },
            },
        },
        priority => '99',
    }

    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    if !defined(File['/srv/log/ores']) {
        file { '/srv/log/ores':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'www-data',
            group  => 'www-data',
        }
    }

}
