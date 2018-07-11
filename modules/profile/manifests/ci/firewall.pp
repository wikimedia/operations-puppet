# == class contint::firewall
#
# === Parameters
#
# Several bricks communicate with the Zuul Gearman server:
#
# [$nodepool_host] The Nodepool server
# [$zuul_merger_hosts] List of zuul-mergers
#
class profile::ci::firewall (
    $nodepool_host = hiera('profile::ci::firewall::nodepool_host'),
    $zuul_merger_hosts = hiera('profile::ci::firewall::zuul_merger_hosts'),
) {
    class { '::base::firewall': }
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
    $zuul_merger_hosts_ferm = join($zuul_merger_hosts, ' ')

    ferm::service { 'gearman_from_zuul_mergers':
        proto  => 'tcp',
        port   => '4730',
        srange => "(${zuul_merger_hosts_ferm})",
    }

    # Nodepool related
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
    ferm::service { 'ci_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
