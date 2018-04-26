# == Class: coal::consumer
#
# Configure and run the consumer side of the coal service
#
# === Parameters
#
# [*kafka_brokers*]
#   List of kafka brokers to use for bootstrapping
#
# [*kafka_consumer_group*]
#   Name of the consumer group to use for Kafka
#
# [*el_schemas*]
#   Event Logging schemas that should be read from Kafka.  Topic names are
#   derived from these values (eventlogging_$schema)
#
# [*log_dir*]
#   Directory where coal's logs should be written by rsyslog
#
# [*graphite_host*]
#   Hostname to which graphite metrics are sent.  
#   Defaults to graphite-in.eqiad.wmnet
#
# [*graphite_port*]
#   Port for graphite metrics. Defaults to 2003 (standard plain-text port)
#
# [*graphite_prefix*]
#   Beginning of the graphite metric path.  Defaults to "coal", which results
#   in metrics like "coal.domInteractive"
#
class coal::consumer(
    $kafka_brokers,
    $kafka_consumer_group = "coal_${::site}",
    $el_schemas = ['NavigationTiming', 'SaveTiming'],
    $log_dir = '/var/log/coal',
    $graphite_host = 'graphite-in.eqiad.wmnet',
    $graphite_port = 2003,
    $graphite_prefix = 'coal'
) {
    require_package('python-kafka')
    require_package('python-dateutil')
    require_package('python-etcd')

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

}