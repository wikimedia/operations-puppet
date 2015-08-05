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

class cassandra::metrics(
    $graphite_prefix = "cassandra.${::hostname}",
    $graphite_host   = 'localhost',
    $graphite_port   = '2003',
) {
    validate_string($graphite_prefix)
    validate_string($graphite_host)
    validate_string($graphite_port)

    package { 'cassandra/metrics-collector':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/usr/local/lib/cassandra-metrics-collector':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        ensure => 'directory',
    }

    file { '/usr/local/lib/cassandra-metrics-collector/cassandra-metrics-collector.jar':
        ensure => 'link',
        target => '/srv/deployment/cassandra/metrics-collector/lib/cassandra-metrics-collector-1.0.0-20150805.144415-6-jar-with-dependencies.jar',
        require => Package['cassandra/metrics-collector'],
    }

    file { '/usr/local/bin/cassandra-metrics-collector':
        source => "puppet:///modules/${module_name}/cassandra-metrics-collector",
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    cron { 'cassandra-metrics-collector':
        ensure  => present,
        user    => 'cassandra',
        command => "flock --wait 2 /tmp/cassandra-metrics-collector.lock /usr/local/bin/cassandra-metrics-collector --graphite-host ${graphite_host} --graphite-port ${graphite_port} --prefix ${graphite_prefix} >/dev/null 2>&1",
        minute  => '*',
        require => Package['cassandra/metrics-collector'],
    }

    # built-in cassandra metrics reporter, T104208
    file { '/usr/share/cassandra/lib/metrics-graphite.jar':
        ensure => absent,
    }

    file { '/etc/cassandra/metrics.yaml':
        ensure => absent,
    }
}
