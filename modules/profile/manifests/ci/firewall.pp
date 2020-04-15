# == class contint::firewall
#
# === Parameters
#
# Several bricks communicate with the Zuul Gearman server:
#
# [$zuul_merger_hosts] List of zuul-mergers
#
class profile::ci::firewall (
    $jenkins_master_hosts = lookup('profile::ci::firewall::jenkins_master_hosts'),
    $zuul_merger_hosts = lookup('profile::ci::firewall::zuul_merger_hosts'),
) {
    class { '::profile::base::firewall': }
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

    # Each master is an agent of the other
    $jenkins_master_hosts_ferm = join($jenkins_master_hosts, ' ')
    ferm::service { 'jenkins_masters_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${jenkins_master_hosts_ferm}))",
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

    # ALLOWS:

    # web access
    ferm::service { 'ci_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
