# vim: set ts=4 sw=4 et:
class contint::firewall {

    include ::base::firewall
    include ::network::constants

    # Restrict some services to be only reacheable from localhost over both
    # IPv4 and IPv6 (to be safe)

    # Jenkins on port 8080, reacheable via Apache proxying the requests
    ferm::rule { 'jenkins_localhost_only':
        rule => 'proto tcp dport 8080 { saddr (127.0.0.1 ::1) ACCEPT; }',
    }
    # Zuul status page on port 8001, reacheable via Apache proxying the requests
    ferm::rule { 'zuul_localhost_only':
        rule => 'proto tcp dport 8001 { saddr (127.0.0.1 ::1) ACCEPT; }',
    }

    # Gearman is used between Zuul and the Jenkin master, both on the same
    # server and communicating over localhost.
    # It is also used by Zuul merger daemons.
    $zuul_merger_hosts = hiera('contint::zuul_merger_hosts')
    $zuul_merger_hosts_ferm = join($zuul_merger_hosts, ' ')

    ferm::service { 'gearman_from_zuul_mergers':
        proto  => 'tcp',
        port   => '4730',
        srange => "(${zuul_merger_hosts_ferm})",
    }

    # Nodepool related
    $nodepool_host = hiera('contint::nodepool_host')
    ferm::service { 'gearman_from_nodepool':
        proto  => 'tcp',
        port   => '4730',
        srange => $nodepool_host,
    }
    ferm::service { 'jenkins_zeromq_from_nodepool':
        proto  => 'tcp',
        port   => '8888',
        srange => $nodepool_host,
    }

    ferm::service { 'jenkins_restapi_from_nodepool':
        proto  => 'tcp',
        port   => '443',
        srange => $nodepool_host,
    }

    ferm::service { 'gerrit_ssh':
        proto  => 'tcp',
        port   => '29418',
        srange => '@resolve((gerrit2001.wikimedia.org cobalt.wikimedia.org gerrit.wikimedia.org))',
    }

    # ALLOWS:

    # web access
    ferm::service { 'allow_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$PRODUCTION_NETWORKS',
    }
}
