# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    String       $ircpassword,
    Stdlib::Port $metrics_port,
) {

    if debian::codename::eq('buster') {
        ensure_packages(['python-irc'])
        ensure_packages(['python-prometheus-client'])
        $echo_source = 'puppet:///modules/mw_rc_irc/udpmxircecho.py'
        $py_interpreter = 'python'
    } else {
        apt::package_from_component { 'irc-python-prometheus-client':
            component => 'component/pybal',
        }

        apt::package_from_component { 'irc-py-irc':
            component => 'main',
            packages  => ['python-irc'],
            priority  => 1002,
        }

        $echo_source = 'puppet:///modules/mw_rc_irc/udpmxircecho-bullseye.py'
        $py_interpreter = 'python2'
    }

    file { '/etc/udpmxircecho-config.json':
        content => to_json_pretty({
            irc_oper_pass => $ircpassword,
            irc_nickname  => 'rc-pmtpa',
            irc_server    => 'localhost',
            irc_port      => 6667,
            irc_realname  => 'IRC echo bot',
            udp_port      => 9390,
            metrics_port  => $metrics_port,
        }),
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc'
    }

    file { '/usr/local/bin/udpmxircecho.py':
        source => $echo_source,
        mode   => '0555',
        owner  => 'irc',
        group  => 'irc',
    }

    file { '/etc/systemd/system/ircecho.service':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mw_rc_irc/systemd/ircecho.service',
    }

    service { 'ircecho':
        ensure   => running,
        provider => 'systemd',
    }

    # icinga check if bot process is running
    nrpe::monitor_service { 'ircecho-process':
        description  => 'ircecho bot process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C ${py_interpreter} --ereg-argument-array '/usr/local/bin/udpmxircecho.py'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Ircecho',
    }

}
