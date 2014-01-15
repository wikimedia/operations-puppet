# == Class: kibana
#
# Kibana is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with ElasticSearch and LogStash.
#
class kibana {
    deployment::target { 'kibana': }

    file { '/etc/kibana':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/etc/kibana/config.js':
        ensure  => present,
        source  => 'puppet:///modules/kibana/config.js',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
