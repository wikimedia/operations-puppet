# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $workers_per_core = 3,
    $redis_host = '127.0.0.1',
    $redis_password = undef,
    $port = 8081,
    $graphite_server = 'graphite-in.eqiad.wmnet',
) {
    require ores::base

    # Need to be able to also restart the worker. The uwsgi service is
    # hopefully temporary
    $sudo_rules = [
        'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores *',
        'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
    ]

    $processes = $::processorcount * $workers_per_core
    service::uwsgi { 'ores':
        port            => $port,
        sudo_rules      => $sudo_rules,
        healthcheck_url => '/',
        config          => {
            'wsgi-file' => "${ores::base::config_path}/ores_wsgi.py",
            chdir       => $ores::base::config_path,
            plugins     => 'python3',
            venv        => $ores::base::venv_path,
            logformat   => '[pid: %(pid)] %(addr) (%(user)) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes (%(switches) switches on core %(core)) user agent "%(uagent)"',
            processes   => $processes,
            add-header  => 'Access-Control-Allow-Origin: *',
        }
    }

    # lint:ignore:arrow_alignment
    $base_config = {
        'metrics_collectors' => {
            'wmflabs_statsd' => {
                'host' => $graphite_server,
            }
        },
        'ores' => {
            'data_paths' => {
                'nltk' => "${::ores::base::config_path}/submodules/wheels/nltk/",
            }
        },
        'score_caches' => {
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
    }
    if $redis_password {
        $pass_config = {
            'score_caches' => {
                'ores_redis' => {
                    'password' => $redis_password,
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => "redis://:${redis_password}@${redis_host}:6379",
                    'CELERY_RESULT_BACKEND' => "redis://:${redis_password}@${redis_host}:6379",
                }
            },
        }
        $config = deep_merge($base_config, $pass_config)
    } else {
        $config = $base_config
    }
    # lint:endignore
    # For now puppet ships the config until we migrate it to scap3 as well
    ores::config { 'main':
        config   => $config,
        priority => '99',
        mode     => '0444',
        owner    => 'deploy-service',
        group    => 'deploy-service',
    }

}
