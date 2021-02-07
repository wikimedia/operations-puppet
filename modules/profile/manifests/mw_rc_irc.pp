class profile::mw_rc_irc (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Port        $metrics_port     = lookup('profile::mw_rc_irc::metrics_port', { default_value => 9221 }),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    class { '::mw_rc_irc::irc_echo':
        ircpassword  => $udpmxircecho_pass,
        metrics_port => $metrics_port,
    }

    class { 'mw_rc_irc::ircserver': }

    # IRCd - public access
    ferm::service { 'ircd_public':
        proto => 'tcp',
        port  => '(6664 6665 6666 6667 6668 6669 8001)',
    }

    # IRC RecentChanges bot - gets updates from appservers
    ferm::service { 'udpmxircecho':
        proto  => 'udp',
        port   => '9390',
        srange => '$MW_APPSERVER_NETWORKS',
    }

    ferm::service { 'prometheus_metrics_endpoint':
      proto  => 'tcp',
      port   => $metrics_port,
      srange => "@resolve((${prometheus_nodes_ferm}))",
    }
}
