# = Class: role::icinga
#
# Sets up a icinga instance which checks services
# and hosts for Wikimedia Production cluster
class role::icinga {
    include facilities::pdu_monitoring
    include icinga::ganglia::ganglios
    include icinga::monitor::checkpaging
    include icinga::monitor::files::misc
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::groups::misc
    include lvs::monitor
    include role::authdns::monitoring
    include network::checks
    include dsh::config
    include mysql
    include nagios::gsbmonitoring
    include nrpe
    include certificates::globalsign_ca

    class { '::icinga':            }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }
}
