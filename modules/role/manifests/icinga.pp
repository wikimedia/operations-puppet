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
    include lvs::monitor
    include icinga::monitor::checkpaging
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::monitor::ores
    include icinga::monitor::toollabs
    include icinga::monitor::ripeatlas
    include icinga::monitor::legal
    include icinga::monitor::certs
    include icinga::monitor::gsb
    include icinga::monitor::commons
    include icinga::monitor::elasticsearch
    include icinga::monitor::wdqs
    include icinga::event_handlers::raid

    include role::authdns::monitoring
    include netops::monitoring
    include scap::dsh
    include mysql
    include nrpe
    include standard
    include base::firewall

    # Dependencies for the check_keystone_roles script
    include ::openstack::clientlib

    $monitoring_groups = hiera('monitoring::groups')
    create_resources(monitoring::group, $monitoring_groups)

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    if $ircbot {
        include icinga::ircbot
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    letsencrypt::cert::integrated { 'icinga':
	subjects => 'icinga.wikimedia.org',
	puppet_svc => 'apache2',
	system_svc => 'apache2',
	require => Class['apache::mod::ssl']
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!icinga.wikimedia.org',
    }

    class { '::icinga':            }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }
}
