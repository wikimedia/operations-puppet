# == Class: role::parsoid
#
class role::parsoid {

    system::role { 'parsoid':
        description => "Parsoid ${::realm}"
    }

    include ::role::mediawiki::common
    include ::profile::base::firewall
    include ::profile::parsoid
    include ::profile::prometheus::apache_exporter

    include ::profile::rsyslog::udp_localhost_compat
}
