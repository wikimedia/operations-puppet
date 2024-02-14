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

    # The scap deploy below requires git-fat
    ensure_packages(['git-fat'])

    scap::target { 'cassandra/logstash-logback-encoder':
        deploy_user => 'deploy-service',
        manage_user => true,
    }

    file { '/usr/share/cassandra/lib/logstash-logback-encoder.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/logstash-logback-encoder-4.2.jar',
        require => Scap::Target['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-annotations-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-annotations-2.4.0.jar',
        require => Scap::Target['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-core-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-core-2.4.0.jar',
        require => Scap::Target['cassandra/logstash-logback-encoder'],
    }

    file { '/usr/share/cassandra/lib/jackson-databind-2.4.0.jar':
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/logstash-logback-encoder/lib/jackson-databind-2.4.0.jar',
        require => Scap::Target['cassandra/logstash-logback-encoder'],
    }
}
