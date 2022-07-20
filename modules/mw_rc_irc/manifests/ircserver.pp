# Sets up the Wikimedia (read-only) IRCd
# This is a modified ircd server and is not
# suitable for a general ircd deployment
class mw_rc_irc::ircserver {

    ensure_packages(['ircd-ratbox', 'irssi'])

    # public part of the ircd config
    file {
        default:
            mode  => '0444',
            owner => 'irc',
            group => 'irc';
        '/usr/etc/ircd.conf':
            notify  => Service['ircd'],
            content => template('mw_rc_irc/ircd.conf.erb');
        '/usr/etc/auth.conf':
            notify    => Service['ircd'],
            show_diff => false,
            content   => secret('mw_rc_irc/auth.conf');
        '/usr/etc/operator.conf':
            notify    => Service['ircd'],
            show_diff => false,
            content   => secret('mw_rc_irc/operator.conf');
        '/usr/etc/ircd.motd':
            notify  => Exec['reload ircd-motd'],
            content => template('mw_rc_irc/motd.erb');
    }

    exec {'reload ircd-motd':
        command     => '/usr/bin/systemctl kill --signalt=SIGUSR1 ircd',
        refreshonly => true,
    }

    systemd::service { 'ircd':
        content        => file('mw_rc_irc/systemd/ircd.service'),
        service_params => {'restart' => '/usr/bin/systemctl reload ircd'},
    }

    monitoring::service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
        critical      => true,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Irc.wikimedia.org',
    }

    prometheus::blackbox::check::tcp { 'mw_rc_irc':
        port           => 6667,
        query_response => [
            { 'send'   => 'NICK prober' },
            { 'send'   => 'USER prober prober prober :prober' },
            { 'expect' => '^:[^ ]+ 376 .*' }, # end of MOTD
        ],
    }
}
