# == Class: cassandra::logging
#
# Configure remote logging requirements for Cassandra
#
# === Usage
# class { '::cassandra::logging': }
#

class cassandra::logging(
) {
    require ::cassandra

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
