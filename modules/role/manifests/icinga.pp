# = Class: role::icinga
#
# Sets up a icinga instance which checks services
# and hosts for Wikimedia Production cluster
#
# = Parameters
#
class role::icinga {

    include ::standard
    include ::profile::base::firewall
    include ::profile::scap::dsh

    include role::authdns::monitoring
    include netops::monitoring
    include facilities
    include lvs::monitor
    include mysql
    include rsync::server

    include icinga::monitor::checkpaging
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::monitor::ores
    include icinga::monitor::toollabs
    include icinga::monitor::legal
    include icinga::monitor::certs
    include icinga::monitor::gsb
    include icinga::monitor::commons
    include icinga::monitor::elasticsearch
    include icinga::monitor::wdqs
    include icinga::monitor::performance
    include icinga::monitor::services
    include icinga::monitor::reading_web
    include icinga::event_handlers::raid
    include ::profile::bird::anycast_monitoring
    include ::profile::prometheus::alerts

    $monitoring_groups = hiera('monitoring::groups')
    create_resources(monitoring::group, $monitoring_groups)

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!icinga.wikimedia.org',
    }

    $partner = hiera('role::icinga::partner')
    $is_passive = hiera('role::icinga::passive')

    $ircbot_present = $is_passive ? {
        false => 'present', #aka active
        true  => 'absent',
    }
    $enable_notifications = $is_passive ? {
        false => 1, #aka active
        true  => 0,
    }
    $enable_event_handlers = $is_passive ? {
        false => 1, #aka active
        true  => 0,
    }
    class { '::icinga':
        enable_notifications  => $enable_notifications,
        enable_event_handlers => $enable_event_handlers,
    }
    class { '::icinga::web':       }
    class { '::icinga::naggen':    }
    class { '::icinga::ircbot':
        ensure => $ircbot_present,
    }

    ferm::service { 'icinga-rsync':
        proto  => 'tcp',
        port   => 873,
        srange => "(@resolve(${partner}) @resolve(${partner}, AAAA))",
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
        content => template('role/icinga/sync_icinga_state.sh.erb'),
    }

    # We absent the cron on active hosts, should only exist on passive ones
    $cron_presence = $is_passive ? {
        true  => 'present',
        false => 'absent',
    }
    cron { 'sync-icinga-state':
        ensure  => $cron_presence,
        minute  => '33',
        command => '/usr/local/sbin/run-no-puppet /usr/local/sbin/sync_icinga_state >/dev/null 2>&1',
    }
}
