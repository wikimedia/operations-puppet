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
    include ::standard
    include ::base::firewall

    $monitoring_groups = hiera('monitoring::groups')
    create_resources(monitoring::group, $monitoring_groups)

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    if $ircbot {
        include icinga::ircbot
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!icinga.wikimedia.org',
    }

    class { '::icinga':            }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }

    $partner = hiera('role::icinga::partner')
    $is_passive = hiera('role::icinga::passive')
    include rsync::server
    ferm::service { 'icinga-rsync':
        proto  => 'tcp',
        port   => 873,
        srange => "@resolve(${partner})",
    }
    rsync::server::module { 'icinga-tmpfs':
        read_only => 'yes',
        path      => '/var/icinga-tmpfs',
    }
    rsync::server::module { 'icinga-cache':
        read_only => 'yes',
        path      => '/var/cache/icinga',
    }
    rsync::server::module { 'icinga-lib':
        read_only => 'yes',
        path      => '/var/lib/icinga',
    }
    file { '/usr/local/sbin/sync_icinga_state':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('role/sync_icinga_state.sh.erb'),
    }
    if $is_passive {
        cron { 'sync-icinga-state':
            minute  => '*/10',
            command => '/usr/local/sbin/sync_icinga_state >/dev/null 2>&1',
        }
    }
}
