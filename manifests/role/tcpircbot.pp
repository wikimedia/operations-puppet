class role::tcpircbot {
    include ::tcpircbot

    system::role { 'tcpircbot':
        description => 'tcpircbot server',
    }

    nrpe::monitor_service { 'tcpircbot':
        description  => 'tcpircbot_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a tcpircbot',
    }

    tcpircbot::instance { 'logmsgbot':
        channels => '#wikimedia-operations',
        password => $passwords::logmsgbot::logmsgbot_password,
        cidr     => [
            '::ffff:10.64.21.123/128',    # vanadium
            '::ffff:10.64.0.196/128',     # tin
            '::ffff:208.80.152.165/128',  # fenari
            '::ffff:127.0.0.1/128',       # loopback
        ],
    }

    ferm::rule { 'tcpircbot_allowed':
        rule => 'saddr (::ffff:10.64.21.123/128 ::ffff:10.64.0.196/128 ::ffff:208.80.152.165/128 ::ffff:127.0.0.1/128) proto tcp dport 9200 ACCEPT';
    }
}
