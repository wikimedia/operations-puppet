class profile::tcpircbot(
    Wmflib::Ensure $ensure = lookup('profile::tcpircbot::ensure'),
    Stdlib::Host $irc_host = lookup('profile::tcpircbot::irc::host'),
    Stdlib::Port $irc_port = lookup('profile::tcpircbot::irc::port'),
){

    include passwords::logmsgbot
    class {'tcpircbot': }

    tcpircbot::instance { 'logmsgbot':
        ensure      => $ensure,
        listen_port => 9200,
        channels    => '#wikimedia-operations',
        password    => $passwords::logmsgbot::logmsgbot_password,
        server_host => $irc_host,
        server_port => $irc_port,
        cidr        => [
            '::ffff:127.0.0.1/128',             # loopback
            '::ffff:10.64.16.93/128',           # deployment eqiad v4: deploy1003
            '2620:0:861:102:10:64:16:93/128',   # deployment eqiad v6: deploy1003
            '::ffff:10.192.32.7/128',           # deployment codfw v4: deploy2002
            '2620:0:860:103:10:192:32:7/128',   # deployment codfw v6: deploy2002
            '::ffff:10.64.16.77/128',           # maintenance eqiad v4: mwmaint1002
            '2620:0:861:102:10:64:16:77/128',   # maintenance eqiad v6: mwmaint1002
            '::ffff:10.192.32.34/128',          # maintenance codfw v4: mwmaint2002
            '2620:0:860:103:10:192:32:34/128',  # maintenance codfw v6: mwmaint2002
            '::ffff:10.64.32.39/128',           # puppetserver1001.eqiad.wmnet (for conftool notifications)
            '2620:0:861:103:10:64:32:39/128',   # puppetserver1001.eqiad.wmnet (for conftool notifications)
            '::ffff:10.64.16.19/128',           # puppetserver1002.eqiad.wmnet (for conftool notifications)
            '2620:0:861:102:10:64:16:19/128',   # puppetserver1002.eqiad.wmnet (for conftool notifications)
            '::ffff:10.64.0.23/128',            # puppetserver1003.eqiad.wmnet (for conftool notifications)
            '2620:0:861:101:10:64:0:23/128',    # puppetserver1003.eqiad.wmnet (for conftool notifications)
            '::ffff:10.192.32.10/128',          # puppetserver2001.codfw.wmnet (for conftool notifications)
            '2620:0:860:103:10:192:32:10/128',  # puppetserver2001.codfw.wmnet (for conftool notifications)
            '::ffff:10.192.0.19/128',           # puppetserver2002.codfw.wmnet (for conftool notifications)
            '2620:0:860:101:10:192:0:19/128',   # puppetserver2002.codfw.wmnet (for conftool notifications)
            '::ffff:10.192.14.6/128',           # puppetserver2003.codfw.wmnet (for conftool notifications)
            '2620:0:860:10f:10:192:14:6/128',   # puppetserver2003.codfw.wmnet (for conftool notifications)
            '::ffff:10.64.48.98/128',           # cumin1002.eqiad.wmnet
            '2620:0:861:107:10:64:48:98/128',   # cumin1002.eqiad.wmnet
            '::ffff:10.192.32.49/128',          # cumin2002.codfw.wmnet
            '2620:0:860:103:10:192:32:49/128',  # cumin2002.codfw.wmnet
        ],
    }
    tcpircbot::instance { 'logmsgbot_cloud':
        ensure      => $ensure,
        listen_port => 9201,
        channels    => '#wikimedia-cloud-feed',
        password    => $passwords::logmsgbot::logmsgbot_password,
        server_host => $irc_host,
        server_port => $irc_port,
        cidr        => [
            '::ffff:127.0.0.1/128',             # loopback
            '::ffff:10.64.48.148/128',          # cloudcumin1001.eqiad.wmnet
            '2620:0:861:107:10:64:48:148/128',  # cloudcumin1001.eqiad.wmnet
            '::ffff:10.192.32.140/128',         # cloudcumin2001.codfw.wmnet
            '2620:0:860:103:10:192:32:140/128', # cloudcumin2001.codfw.wmnet
        ],
    }

    $allowed_hosts_prod = [
        'deploy1003.eqiad.wmnet',       # deployment eqiad
        'deploy2002.codfw.wmnet',       # deployment codfw
        'puppetserver1001.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver1002.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver1003.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver2001.codfw.wmnet', # puppet 7 codfw
        'puppetserver2002.codfw.wmnet', # puppet 7 codfw
        'puppetserver2003.codfw.wmnet', # puppet 7 codfw
        'mwmaint1002.eqiad.wmnet',      # maintenance eqiad
        'mwmaint2002.codfw.wmnet',      # maintenance codfw
        'cumin1002.eqiad.wmnet',        # cluster mgmt eqiad
        'cumin2002.codfw.wmnet',        # cluster mgmt codfw
    ]
    $allowed_hosts_cloud = [
        'cloudcumin1001.eqiad.wmnet',   # cloud cluster mgmt eqiad
        'cloudcumin2001.codfw.wmnet',   # cloud cluster mgmt codfw
    ]

    $allowed_hosts_prod_ferm = join($allowed_hosts_prod, ' ')
    ferm::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => '9200',
        srange => "(@resolve((${allowed_hosts_prod_ferm})) @resolve((${allowed_hosts_prod_ferm}), AAAA))",
    }

    $allowed_hosts_cloud_ferm = join($allowed_hosts_cloud, ' ')
    ferm::service { 'tcpircbot_cloud_allowed':
        proto  => 'tcp',
        port   => '9201',
        srange => "(@resolve((${allowed_hosts_cloud_ferm})) @resolve((${allowed_hosts_cloud_ferm}), AAAA))",
    }
}
