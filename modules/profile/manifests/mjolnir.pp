class profile::mjolnir(
    String $logstash_host = lookup('logstash_host'),
    Stdlib::Port $logstash_port = lookup('logstash_json_lines_port')
) {
    # Mjolnir is deployed to stretch and buster. We have 3.7 packages for
    # stretch, but no 3.5 packages for buster. Install 3.7 to have the same
    # version everywhere. The search/mjolnir/deploy repo expects to find a
    # python3.7 executable.
    require profile::python37

    class { '::mjolnir':
        logstash_host => $logstash_host,
        logstash_port => $logstash_port,
    }

}
