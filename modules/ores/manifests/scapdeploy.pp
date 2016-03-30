class ores::scapdeploy(
    $deploy_user = 'deploy-service',
    $deploy_group = 'deploy-service',
    $redis_host = '127.0.0.1',
) {
    require ores::base

    # Deployment configurations
    include scap
    scap::target { 'ores/deploy':
        deploy_user => $deploy_user,
        sudo_rules  => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores-web *',
            'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
        ],
        require     => File['/srv/ores/deploy-cache'],
        manage_user => false,
    }

    group { $deploy_group:
        ensure => present,
        system => true,
        before => User[$deploy_user],
    }

    user { $deploy_user:
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/scap',
        system     => true,
        managehome => true,
    }

    file { '/srv/ores':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
        require => User[$deploy_user],
    }

    file { '/srv/ores/deploy-cache':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        require => File['/srv/ores'],
    }

    ores::config { 'main':
        config   => {
            'ores'             => {
                'data_paths' => {
                    'nltk' => "${::ores::base::config_path}/submodules/wheels/nltk/",
                }
            },
            'score_caches'     => {
                'ores_redis' => {
                    'host' => $redis_host,
                    'port' => '6380',
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => "redis://${redis_host}:6379",
                    'CELERY_RESULT_BACKEND' => "redis://${redis_host}:6379",
                }
            },
        },
        priority => '99',
        mode     => '0644',
        owner    => 'deploy-service',
        group    => 'deploy-service',
        require  => Package['ores/deploy'],
    }
}
