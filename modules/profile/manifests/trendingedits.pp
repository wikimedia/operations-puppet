# Profile class for trendingedits
class profile::trendingedits {

    require ::profile::kafka::librdkafka

    $kafka_config = kafka_config('main')
    $port = 6699

    service::node { 'trendingedits':
        port              => $port,
        repo              => 'trending-edits/deploy',
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            broker_list => $kafka_config['brokers']['string'],
            site        => $::site,
        },
        environment       => {
            'UV_THREADPOOL_SIZE' => 16
        },
    }
}
