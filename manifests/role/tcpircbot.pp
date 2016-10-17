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
            '::ffff:10.64.32.13/128',           # maintenance eqiad v4: terbium
            '2620:0:861:103:10:64:32:13/64',    # maintenance eqiad v6: terbium
            '::ffff:10.192.48.45/128',          # maintenance codfw v4: wasat
            '2620:0:860:104:10:192:48:45/64',   # maintenance codfw v6: wasat
            '::ffff:10.64.16.73/128',           # puppetmaster1001.eqiad.wmnet
            '2620:0:861:102:10:64:16:73/128',   # puppetmaster1001.eqiad.wmnet
            '::ffff:10.192.0.27/128',           # puppetmaster2001.codfw.wmnet
            '2620:0:860:101:10:192:0:27/128',   # puppetmaster2001.codfw.wmnet

        ],
    }

    $allowed_hosts = [
        'eventlog1001.eqiad.wmnet',     # logging eqiad
        'eventlog2001.codfw.wmnet',     # logging codfw
        'tin.eqiad.wmnet',              # deployment eqiad
        'mira.codfw.wmnet',             # deployment codfw
        'puppetmaster1001.eqiad.wmnet', # puppet eqiad
        'puppetmaster2001.codfw.wmnet', # puppet codfw
        'terbium.eqiad.wmnet',          # maintenance eqiad
        'wasat.codfw.wmnet',            # maintenance codfw
    ]

    ferm::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => '9200',
        srange => "(@resolve((${allowed_hosts})) @resolve((${allowed_hosts}), AAAA))",
    }

}
