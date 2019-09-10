# filtertags: labs-project-ores
class role::labs::ores::worker {
    include ::profile::ores::worker
    include ::role::labs::ores::redisproxy # lint:ignore:wmf_styleguide

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
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'broker_url'     => 'redis://ores-redis-02:6379',
                    'result_backend' => 'redis://ores-redis-02:6379',
                }
            },
            'scoring_systems'  => {
                'celery_queue' => {
                    'broker_url'     => 'redis://ores-redis-02:6379',
                    'result_backend' => 'redis://ores-redis-02:6379',
                }
            }
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
