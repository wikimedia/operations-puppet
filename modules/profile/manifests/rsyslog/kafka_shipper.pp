# SPDX-License-Identifier: Apache-2.0
# @summary generalized rsyslog configuration to ship logs into logging pipeline
# @param enable if true enable config
# @param queue_enabled_sites list of sites to enable queues
# @param kafka_destination_clusters hash of site -> kafka cluster name, used to look up broker details via kafka_config()

class profile::rsyslog::kafka_shipper (
    Boolean       $enable                     = lookup('profile::rsyslog::kafka_shipper::enable'),
    Array[String] $queue_enabled_sites        = lookup('profile::rsyslog::kafka_queue_enabled_sites'),
    Hash          $kafka_destination_clusters = lookup('profile::rsyslog::kafka_destination_clusters'),
) {

    # use kafka_config to build the ssl broker string to be used in the rsyslog omkafka configs for our site
    # clusters are defined under kafka_clusters in hieradata/common.yaml
    if $enable {
        $config                = kafka_config($kafka_destination_clusters[$::site])
        $logging_kafka_brokers = split($config['brokers']['ssl_string'], ',')
    }

    ensure_packages('rsyslog-kafka')

    $ensure = $enable.bool2str('present', 'absent')

    $queue_size = $::site in $queue_enabled_sites ? {
        true  => 10000,
        false => 0,
    }

    file { '/etc/rsyslog.lookup.d':
        ensure => directory,
    }

    file { '/etc/rsyslog.lookup.d/lookup_table_output.json':
        ensure  => stdlib::ensure($ensure, 'file'),
        source  => 'puppet:///modules/profile/rsyslog/lookup_table_output.json',
        require => File['/etc/rsyslog.lookup.d'],
        notify  => Service['rsyslog'],
    }

    # Rsyslog defaults to a MaxMessageSize of 8k which is too short for certain
    # types of logs (for instance multi-line events containing stack traces),
    # increase to 64k to avoid dropping large logs to the floor.
    rsyslog::global_entry('maxMessageSize', '64k')

    rsyslog::conf { 'lookup_output':
        ensure   => $ensure,
        content  => template('profile/rsyslog/lookup_output.conf.erb'),
        priority => 10,
        require  => File['/etc/rsyslog.lookup.d/lookup_table_output.json'],
    }

    rsyslog::conf { 'template_syslog_json':
        ensure   => $ensure,
        source   => 'puppet:///modules/profile/rsyslog/template_syslog_json.conf',
        priority => 10,
    }

    include profile::base::certificates
    $trusted_ca_path = $profile::base::certificates::trusted_ca_path
    rsyslog::conf { 'output_kafka':
        ensure   => $ensure,
        content  => template('profile/rsyslog/output_kafka.conf.erb'),
        priority => 30,
    }

    rsyslog::conf { 'output_local':
        ensure   => $ensure,
        content  => template('profile/rsyslog/output_local.conf.erb'),
        priority => 95,
    }

}
