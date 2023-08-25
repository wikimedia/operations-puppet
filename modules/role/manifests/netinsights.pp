#
class role::netinsights {

  system::role { 'netinsights':
      description => 'network telemetry collector',
  }
    include profile::base::production
    include profile::firewall
    include profile::pmacct
    include profile::fastnetmon
    include profile::samplicator
    include profile::gnmi_telemetry
}
