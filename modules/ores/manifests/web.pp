# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $uwsgi_workers = 45,
    $redis_host = '127.0.0.1',
    $redis_password = undef,
    $port = 8081,
    $graphite_server = 'graphite-in.eqiad.wmnet',
    $deployment = 'scap3',
    $celery_workers = 45,
    $extra_config = undef,
    $ores_config_user = 'deploy-service',
    $ores_config_group = 'deploy-service',
    $celery_queue_maxsize = 100,
) {
    require ::ores::base

    # Need to be able to also restart the worker. The uwsgi service is
    # hopefully temporary
    # lsof is temporary, to diagnose T174402
    $sudo_rules = [
        'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores *',
        'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
    ]

    service::uwsgi { 'ores':
        port            => $port,
        sudo_rules      => $sudo_rules,
        healthcheck_url => '/',
        deployment      => $deployment,
        config          => {
            'wsgi-file'   => "${ores::base::config_path}/ores_wsgi.py",
            chdir         => $ores::base::config_path,
            need-plugins  => 'python3,stats_pusher_statsd',
            venv          => $ores::base::venv_path,
            logformat     => '[pid: %(pid)] %(addr) (%(user)) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes (%(switches) switches on core %(core)) user agent "%(uagent)"',
            processes     => $uwsgi_workers,
            add-header    => 'Access-Control-Allow-Origin: *',
            max-requests  => 200,
            stats-push    => "statsd:${graphite_server}:8125,ores.${::hostname}.uwsgi",
            memory-report => true,
        },
    }

    # lint:ignore:arrow_alignment
    $base_config = {
        'metrics_collectors' => {
            'wmflabs_statsd' => {
                'host' => $graphite_server,
            },
        },
        'ores' => {
            'data_paths' => {
                'nltk' => "${::ores::base::config_path}/submodules/wheels/nltk/",
            },
        },
        'score_caches' => {
            'ores_redis' => {
                'host' => $redis_host,
                'port' => '6380',
            },
        },
        'score_processors' => {
            'ores_celery' => {
                'BROKER_URL'            => "redis://${redis_host}:6379",
                'CELERY_RESULT_BACKEND' => "redis://${redis_host}:6379",
                'CELERYD_CONCURRENCY'   => $celery_workers,
                'queue_maxsize'         => $celery_queue_maxsize,
            },
        },
        'scoring_systems' => {
            'celery_queue' => {
                'BROKER_URL'            => "redis://${redis_host}:6379",
                'CELERY_RESULT_BACKEND' => "redis://${redis_host}:6379",
                'CELERYD_CONCURRENCY'   => $celery_workers,
                'queue_maxsize'         => $celery_queue_maxsize,
            },
        },
    }
    if $redis_password {
        $pass_config = {
            'score_caches' => {
                'ores_redis' => {
                    'password' => $redis_password,
                },
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => "redis://:${redis_password}@${redis_host}:6379",
                    'CELERY_RESULT_BACKEND' => "redis://:${redis_password}@${redis_host}:6379",
                },
            },
            'scoring_systems' => {
                'celery_queue' => {
                    'BROKER_URL'            => "redis://:${redis_password}@${redis_host}:6379",
                    'CELERY_RESULT_BACKEND' => "redis://:${redis_password}@${redis_host}:6379",
                },
            },
        }
        $config = deep_merge($base_config, $pass_config)
    } else {
        $config = $base_config
    }
    # lint:endignore

    if $extra_config {
        $final_config = deep_merge($config, $extra_config)
    } else {
        $final_config = $config
    }

    # For now puppet ships the config until we migrate it to scap3 as well
    ores::config { 'main':
        config   => $final_config,
        priority => '99',
        mode     => '0444',
        owner    => $ores_config_user,
        group    => $ores_config_group,
    }

}
