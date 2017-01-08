class role::labs::ores::staging {
    include ::ores::base
    include ::ores::web
    include ::ores::worker

    include ::role::labs::ores::lb

    class { '::ores::redis':
        cache_maxmemory => '512M',
        queue_maxmemory => '256M',
    }

    git::clone { 'ores-wm-config':
        ensure    => present,
        origin    => 'https://github.com/wiki-ai/ores-wikimedia-config.git',
        directory => $ores::base::config_path,
        branch    => 'master',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/ores'],
        before    => Ores::Config['staging'],
    }

    ores::config { 'staging':
        config   => {
            'score_caches'     => {
                'ores_redis' => {
                    'host' => '127.0.0.1',
                    'port' => '6380',
                },
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => 'redis://127.0.0.1:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://127.0.0.1:6379',
                },
            },
            'scoring_systems'  => {
                'celery_queue' => {
                    'BROKER_URL'            => 'redis://127.0.0.1:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://127.0.0.1:6379',
                },
            },
        },
        priority => '99',
    }

    file { '/srv/ores':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0775',
    }

    file { $ores::base::config_path:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        require => File['/srv/ores'],
    }
}
