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

    # removes unnecessary dependencies, deprecates T128787; the following code
    # can be removed once it's run on each node note! the source dependency
    # jar files needs to be removed from somewhere (maybe trebuchet?? I don't
    # know where)
    $useless = ['/usr/share/cassandra/lib/commons-compiler-2.7.8.jar', '/usr/share/cassandra/lib/janino-2.7.8.jar']
    file { $useless:
        ensure  => 'absent',
    }
}
