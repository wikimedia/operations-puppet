class role::prometheus::ops {
    include base::firewall

    prometheus::server { 'ops':
        listen_address => '127.0.0.1:9900',
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
