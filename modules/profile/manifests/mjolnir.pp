class profile::mjolnir(
    String $logstash_host = lookup('logstash_host'),
    Stdlib::Port $logstash_port = lookup('logstash_json_lines_port')
) {
    ensure_packages(['python3'])

    class { '::mjolnir':
        logstash_host => $logstash_host,
        logstash_port => $logstash_port,
    }

}
