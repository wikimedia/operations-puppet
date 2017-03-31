class profile::ircserver {

    include ::standard
    include ::base::firewall
    include passwords::udpmxircecho
    # $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    #class { '::mw_rc_irc::irc_echo':
    #    ircpassword => $udpmxircecho_pass,
    #}

    include mw_rc_irc::ircserver

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

}
