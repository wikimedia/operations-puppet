# manifests/role/gitblit.pp

class role::gitblit {
    system::role { 'role::gitblit': description => 'Gitblit, a git viewer' }

    include role::gerrit::production::replicationdest

    class { 'gitblit':
        host         => 'git.wikimedia.org',
        ssl_cert     => 'git.wikimedia.org',
        ssl_cert_key => 'git.wikimedia.org'
    }

    # Firewall GitBlit, it should be accessed from localhost or Varnish
    include base::firewall
    ferm::rule { 'gitblit_8080':
        rule => 'proto tcp dport 8080 { saddr $INTERNAL ACCEPT; }'
    }

    # Add ytterbium to ssh exceptions for git replication
    ferm::rule { 'ytterbium_ssh_git':
        rule => 'proto tcp dport ssh { saddr (208.80.154.80 2620:0:861:3:92b1:1cff:fe2a:e60 2620:0:861:3:208:80:154:81) ACCEPT; }'
    }
    # NRPE for monitoring
    include nrpe
}
