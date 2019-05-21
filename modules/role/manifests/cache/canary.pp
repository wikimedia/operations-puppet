class role::cache::canary {
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include role::cache::text

    ferm::service { 'nginx-https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'varnish-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'gdnsd-udp':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'gdnsd-tcp':
        proto => 'tcp',
        port  => '53',
    }
}
