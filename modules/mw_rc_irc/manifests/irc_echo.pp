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
        ensure_packages(['python3-irc', 'python3-prometheus-client'])
        $echo_source = 'puppet:///modules/mw_rc_irc/udpmxircecho-py3.py'
        $py_interpreter = 'python3'
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

    monitoring::check_prometheus { "udpmxircecho_throughput_${::site}":
        description     => "ircecho is not relaying messages - ${::site}",
        dashboard_links => ['https://grafana.wikimedia.org/d/XyXn_CPMz/ircecho'],
        query           => 'sum(irate(udpmxircecho_messages_relayed_total[5m]))',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        method          => 'lt',
        critical        => 1,
        warning         => 2,
        contact_group   => 'admins',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Irc.wikimedia.org',
    }

}
