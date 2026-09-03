class profile::tcpircbot(
    Wmflib::Ensure                                    $ensure          = lookup('profile::tcpircbot::ensure'),
    Stdlib::Host                                      $irc_host        = lookup('profile::tcpircbot::irc::host'),
    Stdlib::Port                                      $irc_port        = lookup('profile::tcpircbot::irc::port'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers = lookup('authdns_servers'),
){

    include passwords::logmsgbot
    class {'tcpircbot': }

    # We need to allow access from dnsXXXX hosts (A:dnsbox) so that
    # authdns-update runs can be logged to SAL, automatically.
    $authdns_hosts = $authdns_servers.keys()
    $authdns_hosts_ips = $authdns_servers.values().map |$ip| { "::ffff:${ip}/128" }

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
            '::ffff:10.192.57.6/128',           # deployment codfw v4: deploy2003
            '2620:0:860:12c:10:192:57:6/128',   # deployment codfw v6: deploy2003
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
            '::ffff:10.192.43.9/128',           # puppetserver2004.codfw.wmnet (for conftool notifications)
            '2620:0:860:122:10:192:43:9/128',   # puppetserver2004.codfw.wmnet (for conftool notifications)
            '::ffff:10.64.16.154/128',          # cumin1003.eqiad.wmnet
            '2620:0:861:102:10:64:16:154/128',  # cumin1003.eqiad.wmnet
            '::ffff:10.64.32.18/128',           # cumin1004.eqiad.wmnet
            '2620:0:861:103:10:64:32:18/128',   # cumin1004.eqiad.wmnet
            '::ffff:10.192.15.6/128',           # cumin2003.codfw.wmnet
            '2620:0:860:110:10:192:15:6/128',   # cumin2003.codfw.wmnet
        ] + $authdns_hosts_ips,
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
        'deploy2003.codfw.wmnet',       # deployment codfw
        'puppetserver1001.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver1002.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver1003.eqiad.wmnet', # puppet 7 eqiad
        'puppetserver2001.codfw.wmnet', # puppet 7 codfw
        'puppetserver2002.codfw.wmnet', # puppet 7 codfw
        'puppetserver2004.codfw.wmnet', # puppet 7 codfw
        'cumin1003.eqiad.wmnet',        # cluster mgmt eqiad
        'cumin1004.eqiad.wmnet',        # cluster mgmt eqiad
        'cumin2003.codfw.wmnet',        # cluster mgmt codfw
    ] + $authdns_hosts

    $allowed_hosts_cloud = [
        'cloudcumin1001.eqiad.wmnet',   # cloud cluster mgmt eqiad
        'cloudcumin2001.codfw.wmnet',   # cloud cluster mgmt codfw
    ]

    firewall::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => 9200,
        srange => $allowed_hosts_prod,
    }

    firewall::service { 'tcpircbot_cloud_allowed':
        proto  => 'tcp',
        port   => 9201,
        srange => $allowed_hosts_cloud,
    }
}
