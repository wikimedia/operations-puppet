# = Class: role::icinga
#
# Sets up a icinga instance which checks services
# and hosts for Wikimedia Production cluster
#
# = Parameters
#
# [*ircbot*]
#   Setup an ircbot using ircecho to support echoing notifications
#
class role::icinga(
    ircbot = true,
){
    include facilities::pdu_monitoring
    include icinga::monitor::checkpaging
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::groups::misc
    include icinga::ircbot
    include lvs::monitor
    include role::authdns::monitoring
    include network::checks
    include dsh::config
    include mysql
    include icinga::gsbmonitoring
    include nrpe
    include certificates::globalsign_ca

    class { '::icinga':            }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }
}
