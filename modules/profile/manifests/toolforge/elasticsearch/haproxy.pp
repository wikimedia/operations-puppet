class profile::toolforge::elasticsearch::haproxy(
    Elasticsearch::InstanceParams $elastic_settings = lookup('profile::elasticsearch::common_settings'),
    Array[Hash] $elastic_users = lookup('profile::toolforge::elasticsearch::haproxy::elastic_users'),
) {
    class { 'haproxy':
        template => 'profile/toolforge/elasticsearch/haproxy.cfg.erb',
    }

    haproxy::site { 'elastic':
        content => template('profile/toolforge/elasticsearch/haproxy-elastic.cfg.erb'),
    }

    # Allow load balancer traffic to peers on back-end ports
    $peers = join(delete($elastic_settings['cluster_hosts'], $::fqdn), ' ')
    ferm::service { 'elastic_haproxy_backend':
        proto  => 'tcp',
        port   => $elastic_settings['http_port'],
        srange => "@resolve((${peers}))",
    }

    # Allow front-end traffend to haproxy
    ferm::service { 'haproxy-http':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
    }
}

