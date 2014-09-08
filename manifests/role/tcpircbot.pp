class role::tcpircbot {
    include ::tcpircbot
    include passwords::logmsgbot

    system::role { 'tcpircbot':
        description => 'tcpircbot server',
    }

    nrpe::monitor_service { 'tcpircbot':
        description  => 'tcpircbot_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C python -a tcpircbot.py',
    }

    tcpircbot::instance { 'logmsgbot':
        channels => '#wikimedia-operations',
        password => $passwords::logmsgbot::logmsgbot_password,
        cidr     => [
            '::ffff:10.64.21.123/128',    # vanadium
            '::ffff:10.64.0.196/128',     # tin
            '::ffff:208.80.152.165/128',  # fenari
            '::ffff:127.0.0.1/128',       # loopback
            '2620:0:861:101:10:64:0:196/128', # tin
        ],
    }

    ferm::rule { 'tcpircbot_allowed':
        # Vanadium, tin(v4), fenari, localhost, tin (v6)
        rule => 'proto tcp dport 9200 { saddr (10.64.21.123/32 10.64.0.196/32 208.80.152.165/32 127.0.0.1 2620:0:861:101:10:64:0:196/128) ACCEPT; }',
    }
}
