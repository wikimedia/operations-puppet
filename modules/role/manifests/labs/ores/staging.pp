# filtertags: labs-project-ores-staging
class role::labs::ores::staging {
    class { '::git::lfs': }
    include ::ores::base
    class { '::ores::web':
        ores_config_user  => 'nobody',
        ores_config_group => 'nogroup',
    }
    include ::ores::worker

    include ::role::labs::ores::lb

    class { '::ores::redis':
        cache_maxmemory => '512M',
        queue_maxmemory => '256M',
    }

    git::clone { 'ores-wm-config':
        ensure    => present,
        origin    => 'https://github.com/wikimedia/ores-wikimedia-config.git',
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
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'broker_url'     => 'redis://127.0.0.1:6379',
                    'result_backend' => 'redis://127.0.0.1:6379',
                }
            },
            'scoring_systems'  => {
                'celery_queue' => {
                    'broker_url'     => 'redis://127.0.0.1:6379',
                    'result_backend' => 'redis://127.0.0.1:6379',
                }
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
