# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $workers_per_core = 4,
    $redis_host = '127.0.0.1',
) {
    require ores::base

    $processes = $::processorcount * $workers_per_core
    service::uwsgi { 'ores':
        port   => 8080,
        config => {
            'wsgi-file' => "${ores::base::config_path}/ores_wsgi.py",
            chdir       => $ores::base::config_path,
            plugins     => 'python3',
            venv        => $ores::base::venv_path,
            logformat   => '[pid: %(pid)] %(addr) (%(user)) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes (%(switches) switches on core %(core)) user agent "%(uagent)"',
            processes   => $processes,
        }
    }

    # For now puppet ships the config until we migrate it to scap3 as well
    ores::config { 'main':
        # lint:ignore:arrow_alignment
        config => {
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
        },
        priority => '99',
        mode     => '0444',
        owner    => 'deploy-service',
        group    => 'deploy-service',
        # lint:endignore
    }
}
