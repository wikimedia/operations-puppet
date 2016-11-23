# Role class for trendingedits
class role::trendingedits {

    $kafka_config = kafka_config('main')
    $port = 6699

    system::role { 'role::trendingedits':
        description => 'computes the list of currently-trending articles',
    }

    class { '::trendingedits':
        port        => $port,
        broker_list => $kafka_config['brokers']['string'],
    }

    ferm::service { "trendingedits_http_${port}":
        proto  => 'tcp',
        port   => $port,
        srange => '$DOMAIN_NETWORKS',
    }

}

