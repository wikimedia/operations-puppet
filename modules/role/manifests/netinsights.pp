#
class role::netinsights {
    include profile::base::production
    include profile::firewall
    include profile::pmacct
    include profile::fastnetmon
    include profile::samplicator
    include profile::gnmi_telemetry
}
