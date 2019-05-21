# == Class: role::parsoid
#
# filtertags: labs-project-deployment-prep
class role::parsoid {

    system::role { 'parsoid':
        description => "Parsoid ${::realm}"
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::parsoid

    include ::profile::rsyslog::udp_localhost_compat
}
