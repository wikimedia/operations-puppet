# SPDX-License-Identifier: Apache-2.0
# == Class: coal::processor
#
# Install and run the coal processor service, which collects median
# values from incoming RUM performance data (Extension:NavigationTiming).
# Consumes from Kafka EventLogging, produces to Graphite.
#
# Contact: Performance Team
# See also: <https://wikitech.wikimedia.org/wiki/Webperf>
#
# === Parameters
#
# [*kafka_brokers*]
#   List of Kafka brokers to use for bootstrapping
#
# [*kafka_security_protocol*]
#   one of "PLAINTEXT", "SSL", "SASL", "SASL_SSL"
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
    String                  $kafka_brokers,
    Optional[String]        $kafka_security_protocol = 'PLAINTEXT',
    Optional[String]        $kafka_consumer_group    = "coal_${::site}",
    Optional[Array[String]] $el_schemas              = ['NavigationTiming', 'SaveTiming', 'PaintTiming'],
    Optional[String]        $log_dir                 = '/var/log/coal',
    Optional[Stdlib::Host]  $graphite_host           = 'localhost',
    Optional[Stdlib::Port]  $graphite_port           = 2003,
    Optional[String]        $graphite_prefix         = 'coal',
    Optional[Stdlib::Unixpath] $kafka_ssl_cafile     = undef,
) {
    # Include common elements
    include ::coal::common

    ensure_packages(['python3-kafka', 'python3-dateutil', 'python3-etcd', 'python3-tz', 'python3-snappy'])

    file { $log_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'adm',
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

    profile::auto_restarts::service { 'coal': }
}
