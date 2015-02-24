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

    package { 'dropwizard/metrics':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/usr/share/cassandra/lib/metrics-graphite.jar':
        ensure => 'link',
        target => '/srv/deployment/dropwizard/metrics/lib/metrics-graphite-2.2.0.jar',
        require => Package['dropwizard/metrics'],
    }

    file { '/etc/cassandra/metrics.yaml':
        content => template("${module_name}/metrics.yaml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }
}
