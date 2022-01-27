class mediawiki::logging::yaml_defs(
    Stdlib::Unixpath $path,
    Array[String] $kafka_brokers,
    String $udp2log,
    String $ca_cert_path = '/etc/ssl/certs/wmf-ca-certificates.crt',
) {
    $kb = $kafka_brokers.map |$broker| { {'host' => $broker, 'port' => 9093}}
    $logging_data = {
        'kafka_brokers' => $kb,
        'rsyslog' => true,
        'udp2log_hostport' => $udp2log,
        'ca_cert_path' => $ca_cert_path,
    }
    file { $path:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => to_yaml({'mw' => {'logging' => $logging_data}})
    }
}
