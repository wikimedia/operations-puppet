#
class role::netinsights {
    include ::profile::base::firewall
    include ::profile::pmacct

    # TODO: this needs to become a profile, obviously
    include ::role::logging::kafkatee::webrequest::base
}
