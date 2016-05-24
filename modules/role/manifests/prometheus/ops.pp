class role::prometheus::ops {
    prometheus::server { 'ops':
        listen_address => '127.0.0.1:9900',
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }
}
