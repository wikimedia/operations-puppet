# == Class: coal::processor
#
# Install and run the coal processor service, which collects median
# values from incoming RUM performance data (Extension:NavigationTiming).
# Consumes from Kafka EventLogging, produces to Graphite.
#
# Contact: performance-team@wikimedia.org
# See also: <https://wikitech.wikimedia.org/wiki/Webperf>
#
# === Parameters
#
# [*kafka_brokers*]
#   List of Kafka brokers to use for bootstrapping
#
# [*kafka_consumer_group*]
#   Name of the consumer group to use for Kafka
#
# [*el_schemas*]
#   EventLogging schemas that should be read from Kafka.  Topic names are
#   derived from these values (eventlogging_$schema)
#
# [*log_dir*]
#   Directory where coal's logs should be written by rsyslog
#
# [*graphite_host*]
#   Hostname to which graphite metrics are sent.
#   Default: "localhost".
#
# [*graphite_port*]
#   Port for graphite metrics. Default: 2003.
#
# [*graphite_prefix*]
#   Beginning of the graphite metric path.  Defaults to "coal", which results
#   in metrics like "coal.responseStart"
#
class coal::processor(
    $kafka_brokers,
    $kafka_consumer_group = "coal_${::site}",
    $el_schemas = ['NavigationTiming', 'SaveTiming', 'PaintTiming'],
    $log_dir = '/var/log/coal',
    $graphite_host = 'localhost',
    $graphite_port = 2003,
    $graphite_prefix = 'coal'
) {
    # Include common elements
    include ::coal::common

    require_package('python-kafka')
    require_package('python-dateutil')
    require_package('python-etcd')
    require_package('python-tz')

    file { $log_dir:
        ensure => directory,
        owner  => 'nobody',
        group  => 'nogroup',
        mode   => '0755',
    }

    logrotate::rule { 'coal':
        ensure       => present,
        file_glob    => "${log_dir}/*.log",
        not_if_empty => true,
        max_age      => 30,
        rotate       => 7,
        date_ext     => true,
        compress     => true,
        missing_ok   => true,
    }

    rsyslog::conf { 'coal':
        content  => template('coal/rsyslog.conf.erb'),
        priority => 80,
    }

    systemd::service { 'coal':
        ensure  => present,
        content => systemd_template('coal'),
        restart => true,
        require => [
            File[$log_dir]
        ],
    }

    base::service_auto_restart { 'coal': }
}
