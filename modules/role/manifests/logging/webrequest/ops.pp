# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::webrequest::ops {
    include ::standard
    include ::profile::base::firewall
    include ::profile::kafkatee::webrequest::ops
    include ::profile::rsyslog::kafka_shipper
}
