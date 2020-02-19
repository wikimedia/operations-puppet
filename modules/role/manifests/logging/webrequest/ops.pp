# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::webrequest::ops {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::kafkatee::webrequest::ops

    system::role { 'logging:webrequest::ops':
        description => 'Host with various filters for debugging web requests',
    }
}
