#
class role::netinsights {

  system::role { 'netinsights':
      description => 'Netflow collector and analysis',
  }

    include ::profile::base::firewall
    include ::profile::pmacct
    include ::profile::rpkicounter
    include ::profile::fastnetmon
}
