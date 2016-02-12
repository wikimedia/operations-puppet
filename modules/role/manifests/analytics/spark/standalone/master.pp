class role::analytics::spark::standalone::master {
    require role::analytics::spark::standalone
    include cdh::spark::master

    ferm::service{ 'spark-master-web-ui':
        proto  => 'tcp',
        port   => '18080',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-master-rpc':
        proto  => 'tcp',
        port   => '7077',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-rest-server':
        proto  => 'tcp',
        port   => '6066',
        srange => '$ANALYTICS_NETWORKS',
    }
}
