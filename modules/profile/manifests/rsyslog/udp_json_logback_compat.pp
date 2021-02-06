# Class profile::rsyslog::udp_json_logback_compat - UDP json log compatibility endpoint
#
# This provides a compatibility endpoint to enable applications that do not yet support
# kafka natively to produce logs into the kafka logging pipeline
#

class profile::rsyslog::udp_json_logback_compat(
    Array $logging_kafka_brokers = lookup('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Integer $port = lookup('profile::rsyslog::udp_json_logback_compat_port', {'default_value' => 11514}),
    Array[String] $queue_enabled_sites = lookup('profile::rsyslog::kafka_queue_enabled_sites',
                                                {'default_value' => []}),
) {
    require_package('rsyslog-kafka')

    $queue_size = $::site in $queue_enabled_sites ? {
        true  => 10000,
        false => 0,
    }

    rsyslog::conf { 'udp_json_logback_compat':
        content  => template('profile/rsyslog/udp_json_logback_compat.conf.erb'),
        priority => 50,
    }
}
