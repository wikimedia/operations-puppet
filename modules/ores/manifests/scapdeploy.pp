class ores::scapdeploy(
    $deploy_user = 'deploy-service',
    $deploy_group = 'deploy-service',
    $public_key_path = 'puppet:///private/ssh/tin/servicedeploy_rsa.pub',
    $redis_host = '127.0.0.1',
) {
    require ores::base

    # Deployment configurations
    include scap
    scap::target { 'ores/deploy':
        deploy_user       => $deploy_user,
        public_key_source => $public_key_path,
        sudo_rules        => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores-web *',
            'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
        ],
    }

    file { '/srv/ores':
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_group,
        mode   => '0775',
    }

    file { '/srv/ores/deploy-cache':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
    }

    file { '/srv/deployment/ores':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
    }

    file { '/srv/ores/deploy':
        ensure  => present,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
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
        mode     => '0775',
        owner    => 'deploy-service',
        group    => 'deploy-service',
        require  => Package['scap'],
    }
}
