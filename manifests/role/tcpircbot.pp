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
            '::ffff:127.0.0.1/128',             # loopback
            '::ffff:10.64.32.167/128',          # logging: eventlog1001
            '::ffff:10.64.0.196/128',           # deployment eqiad v4: tin
            '2620:0:861:101:10:64:0:196/128',   # deployment eqiad v6: tin
            '::ffff:10.192.16.132/128',         # deployment codfw v4: mira
            '2620:0:860:102:10:192:16:132/128', # deployment codfw v6: mira
            '::ffff:10.64.32.13/128',                 # maintenance eqiad v4: terbium
            '2620:0:861:103:92b1:1cff:fe25:9d72/128', # maintenance eqiad v6: terbium
            '::ffff:10.192.48.45/128',                # maintenance codfw v4: wasat
            '2620:0:860:104:1602:ecff:fe3f:478c/128', # maintenance codfw v6: wasat
            '::ffff:10.64.16.160/128',          # puppet master v4: palladium
            '2620:0:861:102:10:64:16:160/128',  # puppet master v6: palladium
        ],
    }

    ferm::rule { 'tcpircbot_allowed':
        # eventlog1001, tin (v4), mira (v4), localhost, tin (v6), mira (v6), terbium (v4), wasat (v4)
        rule => 'proto tcp dport 9200 { saddr (10.64.32.167/32 10.64.0.196/32 10.192.16.132/32 10.64.16.160/32 127.0.0.1 2620:0:861:101:10:64:0:196/128 2620:0:860:102:10:192:16:132/128 2620:0:861:102:10:64:16:160/128 10.64.32.13/32 2620:0:861:103:92b1:1cff:fe25:9d72/128 10.192.48.45/32 2620:0:860:104:1602:ecff:fe3f:478c/128) ACCEPT; }',
    }
}
