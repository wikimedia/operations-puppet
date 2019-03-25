# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    $ircpassword,
) {

        require_package('python-irc')

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

    file { '/etc/systemd/system/ircecho.service':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/mw_rc_irc/systemd/ircecho.service',
        require => File['/usr/local/bin/udpmxircecho.py'],
    }

    service { 'ircecho':
        ensure   => running,
        provider => 'systemd',
        require  => File['/etc/systemd/system/ircecho.service'],
    }

    # icinga check if bot process is running
    nrpe::monitor_service { 'ircecho-process':
        description  => 'ircecho bot process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C python --ereg-argument-array '/usr/local/bin/udpmxircecho.py'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Ircecho',
    }

}
