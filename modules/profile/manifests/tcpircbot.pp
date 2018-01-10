class profile::tcpircbot(
    $ensure='present',
){

    include passwords::logmsgbot
    include ::tcpircbot

    tcpircbot::instance { 'logmsgbot':
        ensure   => $ensure,
        channels => '#wikimedia-operations',
        password => $passwords::logmsgbot::logmsgbot_password,
        cidr     => [
            '::ffff:127.0.0.1/128',             # loopback
            '::ffff:10.64.32.167/128',          # logging: eventlog1001
            '::ffff:10.64.0.196/128',           # deployment eqiad v4: tin
            '2620:0:861:101:10:64:0:196/128',   # deployment eqiad v6: tin
            '::ffff:10.192.32.22/128',          # deployment codfw v4: naos
            '2620:0:860:103:10:192:32:22/128',  # deployment codfw v6: naos
            '::ffff:10.64.32.13/128',           # maintenance eqiad v4: terbium
            '2620:0:861:103:10:64:32:13/64',    # maintenance eqiad v6: terbium
            '::ffff:10.192.48.45/128',          # maintenance codfw v4: wasat
            '2620:0:860:104:10:192:48:45/64',   # maintenance codfw v6: wasat
            '::ffff:10.64.16.73/128',           # puppetmaster1001.eqiad.wmnet
            '2620:0:861:102:10:64:16:73/128',   # puppetmaster1001.eqiad.wmnet
            '::ffff:10.192.0.27/128',           # puppetmaster2001.codfw.wmnet
            '2620:0:860:101:10:192:0:27/128',   # puppetmaster2001.codfw.wmnet
            '::ffff:10.64.32.20/128',           # neodymium.eqiad.wmnet
            '2620:0:861:103:10:64:32:20/64',    # neodymium.eqiad.wmnet
            '::ffff:10.192.0.140/128',          # sarin.codfw.wmnet
            '2620:0:860:101:10:192:0:140/64',   # sarin.codfw.wmnet
        ],
    }
    if $ensure == 'present' {
        nrpe::monitor_service { 'tcpircbot':
            description  => 'tcpircbot_service_running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C python -a tcpircbot.py',
        }
    }

    $allowed_hosts = [
        'eventlog1001.eqiad.wmnet',     # logging eqiad
        'tin.eqiad.wmnet',              # deployment eqiad
        'naos.codfw.wmnet',             # deployment codfw
        'puppetmaster1001.eqiad.wmnet', # puppet eqiad
        'puppetmaster2001.codfw.wmnet', # puppet codfw
        'terbium.eqiad.wmnet',          # maintenance eqiad
        'wasat.codfw.wmnet',            # maintenance codfw
        'neodymium.eqiad.wmnet',        # cluster mgmt eqiad
        'sarin.codfw.wmnet',            # cluster mgmt codfw
    ]

    $allowed_hosts_ferm = join($allowed_hosts, ' ')
    ferm::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => '9200',
        srange => "(@resolve((${allowed_hosts_ferm})) @resolve((${allowed_hosts_ferm}), AAAA))",
    }
}
