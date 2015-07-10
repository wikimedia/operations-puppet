# == Class: cassandra::logging
#
# Configure remote logging for Cassandra
#
# === Usage
# class { '::cassandra::logging':
#     logstash_host => 'logstash1001.eqiad.wmnet',
# }
#
# === Parameters
# [*logstash_host*]
#   The logstash logging server to send to.
#
# [*logstash_port*]
#   The logstash logging server port number.

class cassandra::logging(
    $logstash_host  = 'logstash1001.eqiad.wmnet',
    $logstash_port  = 514,
) {
    validate_string($logstash_host)
    validate_re("${logstash_port}", '^[0-9]+$')

    package { 'cassandra/logstash-logback-encoder':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/usr/share/cassandra/lib/logstash-logback-encoder.jar':
        ensure => 'link',
        target => '/srv/deployment/cassandra/logstash-logback-encoder/lib/logstash-logback-encoder-4.2.jar',
        require => Package['cassandra/logstash-logback-encoder'],
    }
}
