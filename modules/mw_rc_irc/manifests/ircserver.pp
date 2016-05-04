# Sets up the Wikimedia (read-only) IRCd

# This is a modified ircd server and is not
# suitable for a general ircd deployment

class mw_rc_irc::ircserver {

    require_package('ircd-ratbox', 'irssi')

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

    if os_version('debian >= jessie') {

        $ircd_provider = 'systemd'
        $ircd_require  = '/etc/systemd/system/ircd.service'

        file { '/etc/systemd/system/ircd.service':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/mw_rc_irc/systemd/ircd.service',
        }

    } else {

        $ircd_provider = 'upstart'
        $ircd_require  = '/etc/init/ircd.conf'

        file { '/etc/init/ircd.conf':
            source => 'puppet:///modules/mw_rc_irc/upstart/ircd.conf',
        }
    }

    service { 'ircd':
        ensure   => running,
        provider => $ircd_provider,
        require  => File[$ircd_require],
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
    }
}
