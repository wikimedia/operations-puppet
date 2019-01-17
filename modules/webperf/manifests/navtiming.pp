# == Class: webperf::navtiming
#
# Captures NavigationTiming events from Kafka and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# https://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*kafka_brokers*]
#   String of comma separated Kafka bootstrap brokers.
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::navtiming(
    String $kafka_brokers,
    Variant[Stdlib::Ipv4, Stdlib::Fqdn] $statsd_host = '127.0.0.1',
    Stdlib::Port $statsd_port = 8125,
) {
    include ::webperf

    require_package('python-kafka')
    require_package('python-yaml')

    scap::target { 'performance/navtiming':
        service_name => 'navtiming',
        deploy_user  => 'deploy-service',
    }

    file { '/srv/webperf/navtiming.py':
        ensure => absent
    }

    file { '/lib/systemd/system/navtiming.service':
        # uses $statsd_host, $statsd_port, $kafka_brokers
        content => template('webperf/navtiming.systemd.erb'),
        notify  => Service['navtiming'],
    }

    service { 'navtiming':
        ensure   => running,
        provider => systemd,
    }

    base::service_auto_restart { 'navtiming': }
}
