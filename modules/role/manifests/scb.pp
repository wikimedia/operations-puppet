# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {

    $msg_services = 'None whatsoever!!!'

    system::role { 'scb':
        description => "Service cluster B; includes:\n\t${msg_services}"
    }

    include ::profile::standard
    include ::profile::base::firewall
    include profile::lvs::realserver

    include ::profile::rsyslog::udp_localhost_compat

    include ::profile::nutcracker
}
