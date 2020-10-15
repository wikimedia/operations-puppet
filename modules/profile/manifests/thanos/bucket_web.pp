class profile::thanos::bucket_web (
    Array $prometheus_nodes = lookup('prometheus_nodes'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
) {
    $http_port = 15902

    class { 'thanos::bucket_web':
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
    }

    # Allow access only to bucket-web to scrape metrics
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'thanos_bucket_web_prometheus':
        proto  => 'tcp',
        port   => $http_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}

