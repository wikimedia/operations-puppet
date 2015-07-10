# == Class: cassandra::logging
#
# Configure remote logging for Cassandra
#
# === Usage
# class { '::cassandra::logging':
#     logstash_host => 'logstash1001.eqiad.wmnet',
#     logstash_port => 11514,
# }
#
# === Parameters
# [*logstash_host*]
#   The logstash logging server to send to.
#
# [*logstash_port*]
#   The logstash logging server port number.

class cassandra::logging(
    $logstash_host  = 'logstash1003.eqiad.wmnet',
    $logstash_port  = 11514,
) {
    require ::cassandra

    validate_string($logstash_host)
    validate_re("${logstash_port}", '^[0-9]+$')

    file { '/etc/cassandra/logback.xml':
        content => template("${module_name}/logback.xml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    package { 'cassandra/logstash-logback-encoder':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/usr/share/cassandra/lib/logstash-logback-encoder.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/logstash-logback-encoder-4.2.jar',
        require => Package['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-annotations-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-annotations-2.4.0.jar',
        require => Package['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-core-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-core-2.4.0.jar',
        require => Package['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-databind-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-databind-2.4.0.jar',
        require => Package['cassandra/logstash-logback-encoder'],
    }
}
