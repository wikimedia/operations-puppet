# Profile class for trendingedits
class profile::trendingedits {

    $kafka_config = kafka_config('main')
    $port = 6699

    service::packages { 'trendingedits':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
        dev_pkgs => ['librdkafka-dev'],
    }

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
