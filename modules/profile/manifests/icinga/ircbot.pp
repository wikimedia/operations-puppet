# = Class: profile::icinga::ircbot
#
# Sets up an ircecho instance that sends icinga alerts to IRC
class profile::icinga::ircbot(
    # Overridden by profile::icinga considering active/passive and 'profile::icinga::ircbot::ensure'
    Wmflib::Ensure $ensure = 'present', # lint:ignore:wmf_styleguide
    String $ircecho_nick   = lookup('profile::icinga::ircbot::ircecho_nick'),
    String $ircecho_server = lookup('profile::icinga::ircbot::ircecho_server'),
) {
    $ircecho_logs   = {
        '/var/log/icinga/irc.log'                    => '#wikimedia-operations',
        '/var/log/icinga/irc-releng.log'             => '#wikimedia-releng',
        '/var/log/icinga/irc-cloud-feed.log'         => '#wikimedia-cloud-feed',
        '/var/log/icinga/irc-analytics.log'          => '#wikimedia-analytics',
        '/var/log/icinga/irc-interactive.log'        => '#wikimedia-interactive',
        '/var/log/icinga/irc-performance.log'        => '#wikimedia-perf-bots',
        '/var/log/icinga/irc-fundraising.log'        => '#wikimedia-fundraising',
        '/var/log/icinga/irc-reading-web.log'        => '#wikimedia-reading-web-bots',
        '/var/log/icinga/irc-dcops.log'              => '#wikimedia-dcops',
        '/var/log/icinga/irc-databases.log'          => '#wikimedia-data-persistence',
        '/var/log/icinga/irc-team-data-platform.log' => '#wikimedia-data-platform-alerts',
    }

    $password_file = '/etc/icinga/.irc_secret'
    file { $password_file:
        ensure    => $ensure,
        owner     => 'nobody',
        group     => 'nogroup',
        mode      => '0400',
        content   => secret('icinga/icinga-wm_irc.secret'),
        show_diff => false,
    }

    class { '::ircecho':
        ensure            => $ensure,
        ircecho_logs      => $ircecho_logs,
        ircecho_nick      => $ircecho_nick,
        ircecho_server    => $ircecho_server,
        ident_passwd_file => $password_file,
    }

    # T28784 - IRC bots process need nagios monitoring
    nrpe::monitor_service { 'ircecho':
        ensure       => $ensure,
        description  => 'ircecho_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a ircecho',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Ircecho',
    }
}
