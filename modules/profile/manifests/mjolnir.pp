class profile::mjolnir(
    String $logstash_host = hiera('logstash_host'),
    Stdlib::Port $logstash_port = hiera('logstash_json_lines_port')
) {

    class { '::mjolnir':
        logstash_host => $logstash_host,
        logstash_port => $logstash_port,
    }
}
