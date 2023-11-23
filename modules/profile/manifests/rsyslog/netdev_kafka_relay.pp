# SPDX-License-Identifier: Apache-2.0
# Class profile::rsyslog::netdev_kafka_relay - UDP syslog compatiblity endpoint for network devices

# This provides an entry point into the kafka logging pipeline for network hardware devices which do
# not have native support for kafka or rsyslog.
#
# Syslogs that arrive on $port are relayed to the kafka logging pipeline for durability and
# consumption by logtash

class profile::rsyslog::netdev_kafka_relay (
    Array $logging_kafka_brokers = lookup('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Integer $port = lookup('profile::rsyslog::netdev_kafka_relay_port', {'default_value' => 10514}),
    Array[String] $queue_enabled_sites = lookup('profile::rsyslog::kafka_queue_enabled_sites',
                                                {'default_value' => []}),
) {
    ensure_packages('rsyslog-kafka')

    $queue_size = $::site in $queue_enabled_sites ? {
        true  => 10000,
        false => 0,
    }

    include profile::base::certificates
    $trusted_ca_path = $profile::base::certificates::trusted_ca_path
    rsyslog::conf { 'netdev_kafka_relay':
        content  => template('profile/rsyslog/netdev_kafka_relay.conf.erb'),
        priority => 50,
        instance => 'receiver',
    }

    # Templates required by netdev_kafka_relay output
    rsyslog::conf { 'template_syslog_json':
        source   => 'puppet:///modules/profile/rsyslog/template_syslog_json.conf',
        priority => 10,
        instance => 'receiver',
    }
}
