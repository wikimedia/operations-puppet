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
    $ircbot = true,
){
    include facilities
    include icinga::monitor::checkpaging
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::monitor::ripeatlas
    include icinga::monitor::legal
    include icinga::groups::misc
    include lvs::monitor
    include role::authdns::monitoring
    include network::checks
    include dsh::config
    include mysql
    include icinga::gsbmonitoring
    include nrpe

    if $ircbot {
        tcpircbot::instance { 'icinga-wm':
            server_host => 'chat.freenode.net',
            infiles => {
                '/var/log/icinga/irc.log'           => '#wikimedia-operations',
                '/var/log/icinga/irc-wikidata.log'  => '#wikidata',
                '/var/log/icinga/irc-releng.log'    => '#wikimedia-releng',
                '/var/log/icinga/irc-labs.log'      => '#wikimedia-labs',
                '/var/log/icinga/irc-analytics.log' => '#wikimedia-analytics',
            }
        }
    }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    class { '::icinga':            }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }
}
