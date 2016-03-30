class ores::scapdeploy(
    $deploy_user = 'deploy-service',
    $deploy_group = 'deploy-service',
    $redis_host = '127.0.0.1',
) {
    require ores::base
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
    }
}
