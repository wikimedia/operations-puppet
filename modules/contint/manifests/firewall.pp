# vim: set ts=4 sw=4 et:
class contint::firewall {

    include base::firewall
    include network::constants

    # Restrict some services to be only reacheable from localhost over both
    # IPv4 and IPv6 (to be safe)

    # Jenkins on port 8080, reacheable via Apache proxying the requests
    ferm::rule { 'jenkins_localhost_only':
        rule => 'proto tcp dport 8080 { saddr (127.0.0.1 ::1) ACCEPT; }'
    }
    # Zuul status page on port 8001, reacheable via Apache proxying the requests
    ferm::rule { 'zuul_localhost_only':
        rule => 'proto tcp dport 8001 { saddr (127.0.0.1 ::1) ACCEPT; }'
    }

    # Gearman is used between Zuul and the Jenkin master, both on the same
    # server and communicating over localhost.
    # It is also used by Zuul merger daemons.
    ferm::service { 'gearman_from_zuul_mergers':
        proto => 'tcp',
        port  => '4730',
        srange => hiera('contint::zuul_merger_hosts'),
    }

    # The master runs a git-daemon process used by slave to fetch changes from
    # the Zuul git repository. It is only meant to be used from slaves, so
    # reject outside calls.
    ferm::rule { 'git-daemon_internal':
        rule => 'proto tcp dport 9418 { saddr $INTERNAL ACCEPT; }'
    }

    # Need to grant ytterbium ssh access for git
    ferm::rule { 'ytterbium_ssh':
        rule => 'proto tcp dport ssh { saddr (208.80.154.80 208.80.154.81 2620:0:861:3:92b1:1cff:fe2a:e60 2620:0:861:3:208:80:154:80 2620:0:861:3:208:80:154:81) ACCEPT; }'
    }

    # ALLOWS:

    # web access
    ferm::rule { 'allow_http':
        rule => 'proto tcp dport http ACCEPT;'
    }
    ferm::rule { 'allow_https':
        rule => 'proto tcp dport https ACCEPT;'
    }

}
