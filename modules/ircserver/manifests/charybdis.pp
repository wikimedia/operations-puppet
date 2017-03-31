# Sets up the Wikimedia (read-only) IRCd
# This is a modified ircd server and is not
# suitable for a general ircd deployment
class ircserver::charybdis {

    require_package('charybdis', 'irssi')

    # public part of the ircd config
    file { '/usr/etc/ircd.conf':
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc',
        content => template('mw_rc_irc/ircd.conf.erb');
    }

    # private config block for auth/allowed users
    file { '/usr/etc/auth.conf':
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc',
        content => secret('mw_rc_irc/auth.conf');
    }

    # private config block for operators and their passwords
    file { '/usr/etc/operator.conf':
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc',
        content => secret('mw_rc_irc/operator.conf');
    }

    # message of the day / connect banner
    file { '/usr/etc/ircd.motd':
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc',
        content => template('mw_rc_irc/motd.erb');
    }

    file { '/etc/systemd/system/ircd.service':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mw_rc_irc/systemd/ircd.service',
    }

    service { 'ircd':
        ensure   => running,
        provider => 'systemd',
        require  => File['/etc/systemd/system/ircd.service'],
    }

    diamond::collector { 'IRCDStats':
        source   => 'puppet:///modules/mw_rc_irc/monitor/ircd_stats.py',
        settings => {
            method => 'Threaded',
        },
    }

    monitoring::service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
        critical      => true,
    }
}
