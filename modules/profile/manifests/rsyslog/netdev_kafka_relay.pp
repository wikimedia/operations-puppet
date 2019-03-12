# Class profile::rsyslog::netdev_kafka_relay - UDP syslog compatiblity endpoint for network devices

# This provides an entry point into the kafka logging pipeline for network hardware devices which do
# not have native support for kafka or rsyslog.
#
# Syslogs that arrive on $port are relayed to the kafka logging pipeline for durability and
# consumption by logtash

class profile::rsyslog::netdev_kafka_relay (
    Array   $logging_kafka_brokers = hiera('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Integer $port = hiera('profile::rsyslog::netdev_kafka_relay_port', 10514),
) {
    require_package('rsyslog-kafka')

    rsyslog::conf { 'netdev_kafka_relay':
        content  => template('profile/rsyslog/netdev_kafka_relay.conf.erb'),
        priority => 50,
    }

    rsyslog::conf { 'template_syslog_json':
        source   => 'puppet:///modules/profile/rsyslog/template_syslog_json.conf',
        priority => 10,
    }
}
