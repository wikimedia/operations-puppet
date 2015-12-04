# == Class: cassandra::metrics
#
# Configure metrics reporting for cassandra
#
# === Usage
# class { '::cassandra::metrics':
#     graphite_host => 'graphite.duh',
# }
#
# === Parameters
# [*graphite_prefix*]
#   The metrics prefix to use
#
# [*graphite_host*]
#   What host to send metrics to
#
# [*graphite_port*]
#   What port to send metrics to
#
# [*blacklist*]
#   Array of strings, each is a regular expression of metric names to blacklist
#   (i.e. don't send to graphite)

class cassandra::metrics(
    $graphite_prefix = "cassandra.${::hostname}",
    $graphite_host   = 'localhost',
    $graphite_port   = '2003',
    $blacklist       = undef,
) {
    validate_string($graphite_prefix)
    validate_string($graphite_host)
    validate_string($graphite_port)
    if $blacklist {
        validate_array($blacklist)
    }

    $filter_file   = '/etc/cassandra-metrics-collector/filter.yaml'
    $collector_jar = '/usr/local/lib/cassandra-metrics-collector/cassandra-metrics-collector.jar'

    package { 'cassandra/metrics-collector':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/etc/cassandra-metrics-collector':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $filter_file:
        ensure  => 'present',
        content => template("${module_name}/metrics-filter.yaml.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/lib/cassandra-metrics-collector':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $collector_jar:
        ensure  => 'link',
        target  => '/srv/deployment/cassandra/metrics-collector/lib/cassandra-metrics-collector-2.0.0-20151001.182133-1-jar-with-dependencies.jar',
        require => Package['cassandra/metrics-collector'],
    }

    cron { 'cassandra-metrics-collector':
        ensure => absent,
        user   => 'cassandra',
    }

    base::service_unit { 'cassandra-metrics-collector':
        ensure        => present,
        template_name => 'cassandra-metrics-collector',
        systemd       => true,
        refresh       => false,
        require       => [
            File[$collector_jar],
            File[$filter_file],
        ],
    }

    # built-in cassandra metrics reporter, T104208
    file { '/usr/share/cassandra/lib/metrics-graphite.jar':
        ensure => absent,
    }

    file { '/etc/cassandra/metrics.yaml':
        ensure => absent,
    }
}
