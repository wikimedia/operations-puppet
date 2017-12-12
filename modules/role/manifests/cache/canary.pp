class role::cache::canary {
    include ::base::firewall
    include role::cache::text

    # Temp. experiment to duplicate/mirror the webrequest data
    # to the new Kafka Jumbo brokers.
    include ::profile::cache::kafka::webrequest::duplicate

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
