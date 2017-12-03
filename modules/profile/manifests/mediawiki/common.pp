class profile::mediawiki::common(
    $logstash_host = hiera('logstash_host'),
    $logstash_syslog_port = hiera('logstash_syslog_port'),
    $log_aggregator = hiera('udp2log_aggregator'),
    $php7 = hiera('mediawiki_php7'),
    ){

    # GeoIP is needed for MW
    class { '::geoip':
    }

    class { '::mediawiki':
        forward_syslog => "${logstash_host}:${logstash_syslog_port}",
        log_aggregator => $log_aggregator,
        php7           => $php7,
    }

    class { '::tmpreaper':
    }

    # TODO: move to role::mediawiki::webserver ?
    ferm::service{ 'ssh_pybal':
        proto  => 'tcp',
        port   => '22',
        srange => '$PRODUCTION_NETWORKS',
        desc   => 'Allow incoming SSH for pybal health checks',
    }

    # Allow sockets in TIME_WAIT state to be re-used.
    # This helps prevent exhaustion of ephemeral port or conntrack sessions.
    # See <http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html>
    sysctl::parameters { 'tcp_tw_reuse':
        values => { 'net.ipv4.tcp_tw_reuse' => 1 },
    }

    include scap::ferm

    monitoring::service { 'mediawiki-installation DSH group':
        description    => 'mediawiki-installation DSH group',
        check_command  => 'check_dsh_groups!mediawiki-installation',
        check_interval => 60,
    }

}
