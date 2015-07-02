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

    package { 'XXX':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/usr/local/bin/cassandra-jmx-metrics-graphite':
        source => "puppet:///modules/${module_name}/cassandra-jmx-metrics-graphite",
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    cron { 'cassandra-jmx-metrics-graphite':
        ensure  => present,
        user    => 'cassandra',
        command => "flock --wait 2 /usr/local/bin/cassandra-jmx-metrics-graphite --graphite-host ${graphite_host} --graphite-port ${graphite_port} --prefix ${graphite_prefix}",
        minute  => '*',
        require => Package['XXX'],
    }
}
