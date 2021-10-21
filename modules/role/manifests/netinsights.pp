#
class role::netinsights {

  system::role { 'netinsights':
      description => 'Netflow collector and analysis',
  }
    include profile::base::production
    include profile::base::firewall
    include profile::pmacct
    include profile::fastnetmon
    include profile::samplicator
}
