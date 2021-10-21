# @summary generalized rsyslog configuration to ship logs into logging pipeline
# @param logging_kafka_brokers array of kafka broker used in rsyslog omkafka config
# @param enable if true enable config
# @param queue_enabled_sites list of sites to enable queues

class profile::rsyslog::kafka_shipper (
    Array         $logging_kafka_brokers = lookup('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Boolean       $enable                = lookup('profile::rsyslog::kafka_shipper::enable'),
    Array[String] $queue_enabled_sites   = lookup('profile::rsyslog::kafka_queue_enabled_sites')
) {

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

    rsyslog::conf { 'max_message_size':
        ensure   => $ensure,
        content  => template('profile/rsyslog/max_message_size.conf.erb'),
        priority => 00,
    }

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
