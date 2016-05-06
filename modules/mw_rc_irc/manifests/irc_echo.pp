# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    $ircpassword,
) {

    if os_version('debian >= jessie') {
        require_package('python-irc')
    } else {
        require_package('python-irclib')
    }

    file { '/etc/udpmxircecho-config.json':
        content => ordered_json({
            irc_oper_pass => $ircpassword,
            irc_nickname  => 'rc-pmtpa',
            irc_server    => 'localhost',
            irc_port      => 6667,
            irc_realname  => 'IRC echo bot',
            udp_port      => 9390
        }),
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc'
    }

    file { '/usr/local/bin/udpmxircecho.py':
        source  => 'puppet:///modules/mw_rc_irc/udpmxircecho.py',
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc',
        require => File['/etc/udpmxircecho-config.json']
    }

    if $::initsystem == 'systemd' {
        $ircecho_provider = 'systemd'
        $ircecho_require = '/etc/systemd/system/ircecho.service'

        file { '/etc/systemd/system/ircecho.service':
            source  => 'puppet:///modules/mw_rc_irc/systemd/ircecho.service',
            require => File['/usr/local/bin/udpmxircecho.py'],

        }
    } else {
        $ircecho_provider = 'upstart'
        $ircecho_require = '/etc/init/ircecho.conf'

        file { '/etc/init/ircecho.conf':
            source  => 'puppet:///modules/mw_rc_irc/upstart/ircecho.conf',
            require => File['/usr/local/bin/udpmxircecho.py'],
        }
    }

    # Ensure that the service is running.
    service { 'ircecho':
        ensure   => running,
        provider => $ircecho_provider,
        require  => File[$ircecho_require],
    }
}
