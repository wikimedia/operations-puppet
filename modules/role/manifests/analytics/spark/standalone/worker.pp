class role::analytics::spark::standalone::worker {
    require role::analytics::spark::standalone
    include cdh::spark::worker

    ferm::service{ 'spark-worker-web-ui':
        proto  => 'tcp',
        port   => '18081',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-worker-rpc':
        proto  => 'tcp',
        port   => '7078',
        srange => '$ANALYTICS_NETWORKS',
    }
}
