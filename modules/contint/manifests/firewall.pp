# vim: set ts=4 sw=4 et:
class contint::firewall {

    include base::firewall

    # Restrict some services to be only reacheable from localhost..

    # Jenkins on port 8080, reacheable via Apache proxying the requests
    ferm::rule { 'jenkins_localhost_only':
        rule => 'proto tcp dport 8080 { saddr localhost ACCEPT; DROP; }'
    }
    # Zuul status page on port 8001, reacheable via Apache proxying the requests
    ferm::rule { 'zuul_localhost_only':
        rule => 'proto tcp dport 8001 { saddr localhost ACCEPT; DROP; }'
    }
    # Gearman is used between Zuul and the Jenkin master, both on the same
    # server and communicating over localhost
    ferm::rule { 'gearman_localhost_only':
        rule => 'proto tcp dport 4730 { saddr localhost ACCEPT; DROP; }'
    }

    # The master runs a git-daemon process used by slave to fetch changes from
    # the Zuul git repository. It is only meant to be used from slaves, so
    # reject outside calls.
    ferm::rule { 'git-daemon_internal':
        rule => 'proto tcp dport 9418 { saddr $INTERNAL ACCEPT; DROP; }'
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
