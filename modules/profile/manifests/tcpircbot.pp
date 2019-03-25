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
            '::ffff:10.64.0.196/128',           # deployment eqiad v4: tin
            '2620:0:861:101:10:64:0:196/128',   # deployment eqiad v6: tin
            '::ffff:10.64.32.16/128',           # deployment eqiad v4: deploy1001
            '2620:0:861:103:10:64:32:16/128',   # deployment eqiad v6: deploy1001
            '::ffff:10.192.32.24/128',          # deployment codfw v4: deploy2001
            '2620:0:860:103:10:192:32:24/128',  # deployment codfw v6: deploy2001
            '::ffff:10.64.16.77/128',           # maintenance eqiad v4: mwmaint1002
            '2620:0:861:102:10:64:16:77/64',    # maintenance eqiad v6: mwmaint1002
            '::ffff:10.192.48.45/128',          # maintenance codfw v4: mwmaint2001
            '2620:0:860:104:10:192:48:45/64',   # maintenance codfw v6: mwmaint2001
            '::ffff:10.64.16.73/128',           # puppetmaster1001.eqiad.wmnet
            '2620:0:861:102:10:64:16:73/128',   # puppetmaster1001.eqiad.wmnet
            '::ffff:10.192.0.27/128',           # puppetmaster2001.codfw.wmnet
            '2620:0:860:101:10:192:0:27/128',   # puppetmaster2001.codfw.wmnet
            '::ffff:10.64.32.25/128',           # cumin1001.eqiad.wmnet
            '2620:0:861:103:10:64:32:25/64',    # cumin1001.eqiad.wmnet
            '::ffff:10.192.48.16/128',          # cumin2001.codfw.wmnet
            '2620:0:860:101:10:192:48:16/64',   # cumin2001.codfw.wmnet
        ],
    }
    if $ensure == 'present' {
        nrpe::monitor_service { 'tcpircbot':
            description  => 'tcpircbot_service_running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C python -a tcpircbot.py',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Logmsgbot',
        }
    }

    $allowed_hosts = [
        'deploy1001.eqiad.wmnet',       # deployment eqiad
        'deploy2001.codfw.wmnet',       # deployment codfw
        'puppetmaster1001.eqiad.wmnet', # puppet eqiad
        'puppetmaster2001.codfw.wmnet', # puppet codfw
        'mwmaint1002.eqiad.wmnet',      # maintenance eqiad
        'mwmaint2001.codfw.wmnet',      # maintenance codfw
        'cumin1001.eqiad.wmnet',        # cluster mgmt eqiad
        'cumin2001.codfw.wmnet',        # cluster mgmt codfw
    ]

    $allowed_hosts_ferm = join($allowed_hosts, ' ')
    ferm::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => '9200',
        srange => "(@resolve((${allowed_hosts_ferm})) @resolve((${allowed_hosts_ferm}), AAAA))",
    }
}
