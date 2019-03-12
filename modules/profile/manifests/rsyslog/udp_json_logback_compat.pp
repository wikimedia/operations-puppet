# Class profile::rsyslog::udp_json_logback_compat - UDP json log compatibility endpoint
#
# This provides a compatibility endpoint to enable applications that do not yet support
# kafka natively to produce logs into the kafka logging pipeline
#

class profile::rsyslog::udp_json_logback_compat(
    Array   $logging_kafka_brokers = hiera('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Integer $port = hiera('profile::rsyslog::udp_json_logback_compat_port', 11514),
) {
    require_package('rsyslog-kafka')

    rsyslog::conf { 'udp_json_logback_compat':
        content  => template('profile/rsyslog/udp_json_logback_compat.conf.erb'),
        priority => 50,
    }
}
